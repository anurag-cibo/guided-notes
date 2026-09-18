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
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/goal_cover.dart';
import 'package:guided_notes/features/goals/presentation/goal_header.dart';
import 'package:guided_notes/features/goals/presentation/goal_detail.dart';
import 'package:guided_notes/theme/guide_theme.dart';

import 'fixtures/legacy_todos.dart';

void main() {
  testWidgets(
    'compact details fit a narrow screen with large text in both appearances',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(NativeDatabase.memory());
      final controller = GoalsController(GoalsRepository(db));
      try {
        await controller.repository.saveGoal(
          title: 'Ein ausführlicher Zielname mit vielen Wörtern',
          color: GoalColor.rose,
        );
        final id = (await controller.repository.load()).goals.single.id;
        await controller.repository.saveMilestone(
          goalId: id,
          title: 'Schritt',
          progress: 100,
        );
        await controller.load();
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: guideTheme(brightness),
              home: GoalDetail(controller: controller, goalId: id),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('goal-achieved')),
            250,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      } finally {
        controller.dispose();
        await db.close();
      }
    },
  );
  test(
    'schema 4 migration, reopen and backup retain goal colors and contents',
    () async {
      final dir = await Directory.systemTemp.createTemp('guide_color_');
      final file = File('${dir.path}/store.sqlite');
      final fixedNow = DateTime(2026, 9, 18, 12);
      var db = AppDatabase(NativeDatabase(file));
      try {
        var repo = GoalsRepository(db, now: () => fixedNow);
        await repo.saveGoal(title: 'Vorhandenes Ziel', motivation: 'Bleibt');
        final id = (await repo.load()).goals.single.id;
        await repo.saveMilestone(goalId: id, title: 'Ein Schritt');
        final before = await repo.exportBackup();
        await db.close();
        final old = sqlite.sqlite3.open(file.path);
        old.execute('ALTER TABLE goals DROP COLUMN color');
        old.execute('ALTER TABLE goals DROP COLUMN custom_theme_id');
        old.execute('DROP TABLE goal_themes');
        removeTodoLinks(old);
        old.execute('ALTER TABLE goals DROP COLUMN started_on');
        old.execute('PRAGMA user_version = 4');
        old.close();
        db = AppDatabase(NativeDatabase(file));
        repo = GoalsRepository(db, now: () => fixedNow);
        expect(await repo.exportBackup(), before);
        await repo.saveGoal(id: id, title: 'Ozean', color: GoalColor.ocean);
        await repo.setArchived(id, true);
        await db.close();
        db = AppDatabase(NativeDatabase(file));
        repo = GoalsRepository(db, now: () => fixedNow);
        expect((await repo.load()).goals.single.color, GoalColor.ocean);
        await repo.saveGoal(id: id, title: 'Farbe bleibt');
        final backup = await repo.exportBackup();
        await repo.deleteAllContents();
        await repo.importBackup(backup);
        expect((await repo.load()).goals.single.color, GoalColor.ocean);
        expect((await repo.load()).goals.single.archived, isTrue);
        expect((await repo.load()).milestones.single.title, 'Ein Schritt');
        final invalid = jsonDecode(backup) as Map<String, dynamic>;
        invalid['goals'][0]['color'] = 'unknown';
        await expectLater(
          repo.importBackup(jsonEncode(invalid)),
          throwsA(isA<RuleViolation>()),
        );
        expect(await repo.exportBackup(), backup);
        for (final version in [1, 2, 3]) {
          final legacy = jsonDecode(backup) as Map<String, dynamic>;
          legacy['version'] = version;
          legacy['goals'][0].remove('color');
          expect(
            BackupCodec.decode(jsonEncode(legacy)).goals.single.color,
            GoalColor.forest,
          );
        }
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'select color, save, reopen editor; detail overlaps cover and actions share row',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      final controller = GoalsController(GoalsRepository(db));
      try {
        await controller.repository.saveGoal(title: 'Gesundheit');
        final id = (await controller.repository.load()).goals.single.id;
        await controller.repository.saveMilestone(
          goalId: id,
          title: 'Bewegen',
          progress: 30,
          status: MilestoneStatus.onTrack,
        );
        await controller.load();
        await tester.pumpWidget(GuideApp(controller: controller));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gesundheit'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Ziel bearbeiten'));
        await tester.pumpAndSettle();
        final color = find.byKey(const ValueKey('goal-color-lavender'));
        await tester.ensureVisible(color);
        await tester.tap(color);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Speichern'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        expect(controller.snapshot.goal(id)!.color, GoalColor.lavender);
        final header = find.byType(GoalHeader);
        final title = find.descendant(
          of: header,
          matching: find.text('Gesundheit'),
        );
        final cover = tester.getRect(find.byType(GoalCover));
        final titleRect = tester.getRect(title);
        expect(titleRect.top, lessThan(cover.bottom));
        expect(titleRect.bottom, greaterThan(cover.bottom));
        await tester.ensureVisible(find.byKey(const ValueKey('goal-achieved')));
        await tester.pumpAndSettle();
        final switchRect = tester.getRect(
          find.byKey(const ValueKey('goal-achieved')),
        );
        final archiveRect = tester.getRect(
          find.widgetWithText(OutlinedButton, 'Ziel archivieren'),
        );
        expect(switchRect.center.dy, closeTo(archiveRect.center.dy, 1));
        expect(find.text('Bleibt aktiv, bis du es archivierst.'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Ziel bearbeiten'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(color);
        expect(tester.widget<ChoiceChip>(color).selected, isTrue);
        await tester.pumpWidget(const SizedBox());
      } finally {
        controller.dispose();
        await db.close();
      }
    },
  );
}
