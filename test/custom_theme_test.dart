import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/goal_theme.dart';
import 'package:guided_notes/features/settings/presentation/custom_themes_screen.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

import 'fixtures/legacy_todos.dart';

void main() {
  testWidgets(
    'detail actions stay fixed while todo history scrolls after contents',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      final controller = GoalsController(GoalsRepository(db));
      try {
        await controller.repository.saveGoal(
          title: 'Ein Ziel',
          color: GoalColor.rose,
        );
        final id = (await controller.repository.load()).goals.single.id;
        for (var i = 0; i < 15; i++) {
          await controller.repository.saveMilestone(
            goalId: id,
            title: 'Schritt $i',
          );
          await controller.repository.todos.save(
            title: 'Aufgabe $i',
            frequency: TodoFrequency.daily,
            target: 1,
          );
        }
        await controller.load();
        await tester.pumpWidget(GuideApp(controller: controller));
        await tester.pumpAndSettle();
        final headingRect = tester.getRect(find.text('Deine Ziele · 1 von 5'));
        final addRect = tester.getRect(find.byTooltip('Ziel hinzufügen'));
        expect(addRect.center.dy, closeTo(headingRect.center.dy, 1));
        expect(addRect.left, greaterThan(headingRect.right));
        await tester.tap(find.text('Ein Ziel'));
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('goal-achieved'));
        final before = tester.getRect(action);
        expect(action.hitTestable(), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.getRect(action), before);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Todos').last);
        await tester.pumpAndSettle();
        final history = find.text('Vergangene Zeiträume');
        expect(history.hitTestable(), findsNothing);
        await tester.scrollUntilVisible(history, 500);
        await tester.pumpAndSettle();
        expect(history.hitTestable(), findsOneWidget);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
        await tester.pumpAndSettle();
        expect(history.hitTestable(), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        controller.dispose();
        await db.close();
      }
    },
  );
  test('migration 5, custom palette edits, reopen and backup preserve references atomically', () async {
    final directory = await Directory.systemTemp.createTemp(
      'guide_custom_theme_',
    );
    final file = File('${directory.path}/store.sqlite');
    final fixedNow = DateTime(2026, 9, 18, 12);
    var db = AppDatabase(NativeDatabase(file));
    try {
      var repo = GoalsRepository(db, now: () => fixedNow);
      await repo.saveGoal(title: 'Bestehend', color: GoalColor.ocean);
      final before = await repo.exportBackup();
      await db.close();
      final old = sqlite.sqlite3.open(file.path);
      old.execute('ALTER TABLE goals DROP COLUMN custom_theme_id');
      old.execute('DROP TABLE goal_themes');
      removeTodoLinks(old);
      old.execute('ALTER TABLE goals DROP COLUMN started_on');
      old.execute('PRAGMA user_version = 5');
      old.close();
      db = AppDatabase(NativeDatabase(file));
      repo = GoalsRepository(db, now: () => fixedNow);
      expect(await repo.exportBackup(), before);
      final goalId = (await repo.load()).goals.single.id;
      final themeId = await repo.saveTheme(
        name: 'Abend',
        colors: GoalColor.rose.colors,
      );
      await repo.saveGoal(
        id: goalId,
        title: 'Bestehend',
        customThemeId: themeId,
      );
      await repo.saveGoal(title: 'Zweites Ziel', customThemeId: themeId);
      await repo.saveTheme(
        id: themeId,
        name: 'Abendrot',
        colors: GoalColor.lavender.colors,
      );
      await repo.saveGoal(id: goalId, title: 'Referenz bleibt');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      repo = GoalsRepository(db, now: () => fixedNow);
      final snapshot = await repo.load();
      expect(snapshot.customThemes.single.name, 'Abendrot');
      expect(
        snapshot.customThemes.single.colors.accent,
        GoalColor.lavender.colors.accent,
      );
      expect(snapshot.goals.every((g) => g.customThemeId == themeId), isTrue);
      final backup = await repo.exportBackup();
      await repo.deleteAllContents();
      expect((await repo.load()).isEmpty, isTrue);
      for (final change in <void Function(Map<String, dynamic>)>[
        (d) => d['customThemes'][0]['primary'] = -1,
        (d) => d['customThemes'].add(d['customThemes'][0]),
        (d) => d['goals'][0]['customThemeId'] = 999,
      ]) {
        final broken = jsonDecode(backup) as Map<String, dynamic>;
        change(broken);
        await expectLater(
          repo.importBackup(jsonEncode(broken)),
          throwsA(isA<RuleViolation>()),
        );
        expect((await repo.load()).isEmpty, isTrue);
      }
      await repo.importBackup(backup);
      expect(await repo.exportBackup(), backup);
      await repo.deleteAllContents();
      await db.customStatement(
        "CREATE TRIGGER fail_goal_import BEFORE INSERT ON goals BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(repo.importBackup(backup), throwsA(anything));
      expect((await repo.load()).isEmpty, isTrue);
      await db.customStatement('DROP TRIGGER fail_goal_import');
      await repo.importBackup(backup);
      await repo.saveGoal(
        id: goalId,
        title: 'Standard',
        color: GoalColor.amber,
        clearCustomTheme: true,
      );
      expect((await repo.load()).goal(goalId)!.customThemeId, isNull);
      await expectLater(
        repo.saveGoal(id: goalId, title: 'Ungültig', customThemeId: 999),
        throwsA(isA<RuleViolation>()),
      );
      expect((await repo.load()).goal(goalId)!.title, 'Standard');
      await repo.deleteAllContents();
      await repo.saveTheme(name: 'Nur Theme', colors: GoalColor.forest.colors);
      await expectLater(
        repo.importBackup(backup),
        throwsA(isA<RuleViolation>()),
      );
      expect((await repo.load()).customThemes.single.name, 'Nur Theme');
      await repo.deleteAllContents();
      final legacy = jsonDecode(backup) as Map<String, dynamic>;
      legacy['version'] = 4;
      legacy.remove('customThemes');
      for (final g in legacy['goals']) {
        g.remove('customThemeId');
      }
      await repo.importBackup(jsonEncode(legacy));
      expect((await repo.load()).customThemes, isEmpty);
      expect((await repo.load()).goals.first.color, GoalColor.ocean);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });

  testWidgets(
    'create custom theme from unfinished goal, pick colors, save and edit via settings',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final controller = GoalsController(GoalsRepository(db));
      try {
        await controller.load();
        await tester.pumpWidget(GuideApp(controller: controller));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Ziel hinzufügen'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('goal-title')),
          'Mein Ziel',
        );
        await tester.ensureVisible(find.byTooltip('Eigenes Theme erstellen'));
        await tester.tap(find.byTooltip('Eigenes Theme erstellen'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('theme-name')),
          'Mein Abend',
        );
        await tester.tap(find.text('Primärfarbe'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('theme-hex')),
          '7542A1',
        );
        await tester.tap(find.text('Übernehmen'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Theme speichern'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Theme speichern'));
        await tester.pumpAndSettle();
        final theme = controller.snapshot.customThemes.single;
        expect(theme.colors.primary, 0xff7542a1);
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(ValueKey('custom-theme-${theme.id}')),
              )
              .selected,
          isTrue,
        );
        await tester.scrollUntilVisible(
          find.text('Speichern'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        expect(controller.snapshot.goals.single.title, 'Mein Ziel');
        expect(controller.snapshot.goals.single.customThemeId, theme.id);
        await tester.tap(find.byTooltip('Einstellungen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Themes'));
        await tester.pumpAndSettle();
        expect(find.byType(CustomThemesScreen), findsOneWidget);
        await tester.tap(find.text('Mein Abend'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('theme-name')),
          'Neuer Name',
        );
        await tester.scrollUntilVisible(
          find.text('Theme speichern'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Theme speichern'));
        await tester.pumpAndSettle();
        expect(controller.snapshot.customThemes.single.name, 'Neuer Name');
        expect(controller.snapshot.goals.single.customThemeId, theme.id);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        controller.dispose();
        await db.close();
      }
    },
  );
}
