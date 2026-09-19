import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/backup_codec.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/goal_time.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/goal_header.dart';
import 'package:guided_notes/features/goals/presentation/goal_theme.dart';
import 'package:guided_notes/features/settings/presentation/custom_themes_screen.dart';

import 'fixtures/legacy_todos.dart';

void main() {
  test('time circle uses calendar days and handles absent, overdue and moved deadlines', () {
    final goal = Goal(
      id: 1,
      title: 'Test',
      startedOn: DateTime(2026, 3, 28),
      dueDate: DateTime(2026, 3, 30),
    );
    final half = GoalTime(goal, DateTime(2026, 3, 29, 23));
    expect(half.elapsed, .5);
    expect(half.label, '1 Tag\nübrig');
    expect(GoalTime(goal, DateTime(2026, 3, 27)).elapsed, 0);
    expect(GoalTime(goal, DateTime(2026, 3, 30)).label, 'Heute\nfällig');
    final overdue = GoalTime(goal, DateTime(2026, 4, 1));
    expect(overdue.elapsed, 1);
    expect(overdue.label, '2 Tage\nüberfällig');
    expect(
      GoalTime(const Goal(id: 1, title: 'Test'), DateTime.now()).label,
      'Ohne\nFrist',
    );
    final early = Goal(
      id: 1,
      title: 'Test',
      startedOn: DateTime(2026, 4, 1),
      dueDate: DateTime(2026, 3, 30),
    );
    expect(GoalTime(early, DateTime(2026, 4, 1)).elapsed, 1);
  });

  test(
    'schema 6 start migration persists across restart, edit and backup',
    () async {
      final directory = await Directory.systemTemp.createTemp('guide_start_');
      final file = File('${directory.path}/test.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      var today = DateTime(2026, 9, 18);
      try {
        var repo = GoalsRepository(db, now: () => today);
        await repo.saveGoal(title: 'Bestehend', motivation: 'Bleibt');
        await db.close();
        final old = sqlite.sqlite3.open(file.path);
        removeTodoLinks(old);
        old.execute('ALTER TABLE goals DROP COLUMN started_on');
        old.execute('PRAGMA user_version = 6');
        old.close();
        db = AppDatabase(NativeDatabase(file));
        repo = GoalsRepository(db, now: () => today);
        expect((await repo.load()).goals.single.startedOn, today);
        await db.close();
        today = DateTime(2026, 9, 20);
        db = AppDatabase(NativeDatabase(file));
        repo = GoalsRepository(db, now: () => today);
        final existing = (await repo.load()).goals.single;
        expect(existing.startedOn, DateTime(2026, 9, 18));
        expect(existing.motivation, 'Bleibt');
        await repo.saveGoal(
          motivation: 'Meine persönliche Richtung',
          id: existing.id,
          title: 'Bearbeitet',
          dueDate: DateTime(2026, 10),
        );
        final backup = await repo.exportBackup();
        await repo.deleteAllContents();
        await repo.importBackup(backup);
        expect(await repo.exportBackup(), backup);
        final invalid = jsonDecode(backup) as Map<String, dynamic>;
        invalid['goals'][0]['startedOn'] = '2026-02-30';
        expect(
          () => BackupCodec.decode(jsonEncode(invalid)),
          throwsA(isA<RuleViolation>()),
        );
        final legacy = jsonDecode(backup) as Map<String, dynamic>;
        legacy['version'] = 5;
        legacy['goals'][0].remove('startedOn');
        await repo.deleteAllContents();
        await repo.importBackup(jsonEncode(legacy));
        expect((await repo.load()).goals.single.startedOn, today);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('deleting a theme preserves active and archived goals; failure rolls back references', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = GoalsRepository(db);
    try {
      final id = await repo.saveTheme(
        name: 'Abend',
        colors: GoalColor.rose.colors,
      );
      await repo.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Aktiv',
        customThemeId: id,
        color: GoalColor.ocean,
      );
      await repo.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Archiv',
        customThemeId: id,
        color: GoalColor.amber,
      );
      final goals = (await repo.load()).goals;
      await repo.setArchived(goals.last.id, true);
      await repo.saveMilestone(
        motivation: 'Mein nächster Schritt zum Ziel',
        goalId: goals.first.id,
        title: 'Bleibt',
        progress: 30,
      );
      final before = await repo.exportBackup();
      await db.customStatement(
        "CREATE TRIGGER fail_theme_delete BEFORE DELETE ON goal_themes BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(repo.deleteTheme(id), throwsA(anything));
      expect(await repo.exportBackup(), before);
      await db.customStatement('DROP TRIGGER fail_theme_delete');
      await repo.deleteTheme(id);
      final after = await repo.load();
      expect(after.customThemes, isEmpty);
      expect(after.goals.map((g) => g.customThemeId), everyElement(isNull));
      expect(after.goals.map((g) => g.color), [
        GoalColor.ocean,
        GoalColor.amber,
      ]);
      expect(after.goals.last.archived, isTrue);
      expect(after.milestones.single.progress, 30);
    } finally {
      await db.close();
    }
  });

  testWidgets(
    'archive sits below short contents and scrolls after long contents',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      final c = GoalsController(GoalsRepository(db));
      try {
        await c.repository.saveGoal(
          motivation: 'Meine persönliche Richtung',
          title: 'Erstes Ziel',
        );
        await c.load();
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        expect(find.text('The Guide'), findsNothing);
        expect(find.text('Schön, dass du da bist.'), findsOneWidget);
        final archive = find.text('Archiv');
        expect(archive.hitTestable(), findsOneWidget);
        expect(tester.getRect(archive).top, greaterThan(650));
        for (var i = 0; i < 4; i++) {
          await c.repository.saveGoal(
            motivation: 'Meine persönliche Richtung',
            title: 'Weiteres Ziel $i mit einem langen mehrzeiligen Titel',
          );
        }
        await c.load();
        await tester.pumpAndSettle();
        expect(archive.hitTestable(), findsNothing);
        await tester.scrollUntilVisible(archive, 300);
        await tester.pumpAndSettle();
        expect(archive.hitTestable(), findsOneWidget);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
        await tester.pumpAndSettle();
        expect(archive.hitTestable(), findsNothing);
        await tester.pumpWidget(const SizedBox());
      } finally {
        c.dispose();
        await db.close();
      }
    },
  );

  testWidgets(
    'theme preview stays bounded, reveals all choices and keeps selected theme visible',
    (tester) async {
      var selected = 20;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => GoalColorSelector(
                value: GoalColor.forest,
                customThemeId: selected,
                customThemes: [
                  for (var i = 1; i <= 20; i++)
                    CustomGoalTheme(
                      id: i,
                      name: 'Theme $i',
                      colors: GoalColor.rose.colors,
                    ),
                ],
                onChanged: (_) {},
                onCustomChanged: (id) => setState(() => selected = id),
                onCreate: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.text('Theme 20'), findsOneWidget);
      await tester.tap(find.text('Mehr anzeigen'));
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNWidgets(25));
      await tester.tap(find.text('Theme 18'));
      await tester.tap(find.text('Weniger anzeigen'));
      await tester.pumpAndSettle();
      expect(find.text('Theme 18'), findsOneWidget);
      expect(find.text('Theme 20'), findsNothing);
    },
  );

  testWidgets(
    'theme deletion confirms and system themes have no delete action',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final c = GoalsController(GoalsRepository(db));
      try {
        final id = await c.repository.saveTheme(
          name: 'Eigenes',
          colors: GoalColor.rose.colors,
        );
        await c.repository.saveGoal(
          motivation: 'Meine persönliche Richtung',
          title: 'Bleibt',
          customThemeId: id,
        );
        await c.load();
        await tester.pumpWidget(
          MaterialApp(home: CustomThemesScreen(controller: c)),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Wald löschen'), findsNothing);
        await tester.tap(find.byTooltip('Eigenes löschen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();
        expect(c.snapshot.customThemes, hasLength(1));
        await tester.tap(find.byTooltip('Eigenes löschen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Endgültig löschen'));
        await tester.pumpAndSettle();
        expect(c.snapshot.customThemes, isEmpty);
        expect(c.snapshot.goals.single.title, 'Bleibt');
        await tester.pumpWidget(const SizedBox());
      } finally {
        c.dispose();
        await db.close();
      }
    },
  );

  testWidgets('header separates time circle and milestone progress bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalHeader(
            goal: Goal(
              id: 1,
              title: 'Ziel',
              startedOn: DateTime(2026, 9, 1),
              dueDate: DateTime(2026, 10, 1),
            ),
            progress: 70,
            now: DateTime(2026, 9, 16),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      .5,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .7,
    );
    expect(find.text('15 Tage\nübrig'), findsOneWidget);
    expect(find.text('70 %'), findsOneWidget);
    expect(
      tester.getRect(find.byType(LinearProgressIndicator)).top,
      greaterThan(
        tester.getRect(find.byType(CircularProgressIndicator)).bottom,
      ),
    );
  });
}
