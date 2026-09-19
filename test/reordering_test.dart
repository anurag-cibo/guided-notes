import 'dart:io';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/goals/presentation/goal_detail.dart';
import 'package:guided_notes/features/goals/presentation/goal_emoji_selector.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  test('schema 10 migration, ordering restart/backup and move with credited todo undo', () async {
    final directory = await Directory.systemTemp.createTemp('guide_order_');
    final file = File('${directory.path}/test.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var r = GoalsRepository(db);
    try {
      for (final title in ['Gesundheit', 'Lernen', 'Finanzen']) {
        await r.saveGoal(title: title);
      }
      await r.saveMilestone(goalId: 1, title: 'Erster', progress: 20);
      await r.saveMilestone(goalId: 1, title: 'Zweiter', progress: 50);
      await r.saveMilestone(goalId: 2, title: 'Dritter', progress: 80);
      await r.todos.save(
        title: 'Üben',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: 1,
        progressIncrement: 2.5,
      );
      await r.todos.changeCount((await r.load()).todoEntries.single, 1);
      final original = await r.exportBackup();
      await db.close();
      final old = sqlite.sqlite3.open(file.path);
      for (final table in ['goals', 'milestones']) {
        old.execute('ALTER TABLE $table DROP COLUMN sort_order');
      }
      old.execute('PRAGMA user_version=10');
      old.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db);
      expect(await r.exportBackup(), original);
      await r.moveGoal(3, 1, after: false);
      await r.moveMilestone(2, 1, targetId: 1);
      expect((await r.load()).forGoal(1).map((m) => m.id), [2, 1]);
      await r.moveMilestone(1, 2, targetId: 3, after: true);
      var snapshot = await r.load();
      expect(snapshot.activeGoals.map((g) => g.id), [3, 1, 2]);
      expect(snapshot.forGoal(2).map((m) => m.id), [3, 1]);
      expect(snapshot.progressFor(1), 50);
      expect(snapshot.progressFor(2), 51.25);
      final moved = jsonDecode(await r.exportBackup()) as Map;
      final before = jsonDecode(original) as Map;
      for (final key in ['todoCredits', 'todoEntries', 'todoTemplates']) {
        expect(moved[key], before[key]);
      }
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db);
      final backup = await r.exportBackup();
      await r.deleteAllContents();
      await r.importBackup(backup);
      expect(await r.exportBackup(), backup);
      await r.todos.changeCount((await r.load()).todoEntries.single, -1);
      snapshot = await r.load();
      expect(snapshot.milestone(1)!.progress, 20);
      expect(snapshot.milestone(1)!.goalId, 2);
      expect(snapshot.progressFor(2), 50);
      await r.saveGoal(title: 'Neues Ziel');
      expect((await r.load()).activeGoals.last.title, 'Neues Ziel');
      await r.setArchived(3, true);
      final unchanged = await r.exportBackup();
      await expectLater(r.moveMilestone(1, 3), throwsA(isA<RuleViolation>()));
      await expectLater(
        r.moveMilestone(1, 1, targetId: 999),
        throwsA(isA<RuleViolation>()),
      );
      expect(await r.exportBackup(), unchanged);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });

  testWidgets(
    'long press drag sorts goals, details and cross-goal milestones',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = GoalsRepository(db);
      final c = GoalsController(r);
      tester.view.physicalSize = const Size(420, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await r.saveGoal(title: 'Gesundheit', emoji: '🌿');
        await r.saveGoal(title: 'Lernen', emoji: '📚');
        await r.saveGoal(title: 'Finanzen', emoji: '💰');
        await r.saveMilestone(goalId: 1, title: 'Bewegen');
        await r.saveMilestone(goalId: 1, title: 'Schlafen');
        await r.saveMilestone(goalId: 2, title: 'Lesen');
        await c.load();
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        Future<void> move(
          String source,
          String target, {
          bool after = false,
        }) async {
          final from = find.byKey(ValueKey(source));
          final to = find.byKey(ValueKey(target));
          final point = after
              ? tester.getBottomLeft(to) + const Offset(30, -12)
              : tester.getTopLeft(to) + const Offset(30, 12);
          final gesture = await tester.startGesture(tester.getCenter(from));
          await tester.pump(const Duration(milliseconds: 650));
          await gesture.moveTo(point);
          await tester.pump(const Duration(milliseconds: 900));
          await gesture.up();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await move('drag-goal-2', 'drag-goal-1');
        expect(c.snapshot.activeGoals.map((g) => g.id), [2, 1, 3]);
        final cancelled = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('drag-goal-2'))),
        );
        await tester.pump(const Duration(milliseconds: 650));
        await cancelled.moveTo(
          tester.getCenter(find.byKey(const ValueKey('drag-goal-1'))),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await cancelled.cancel();
        await tester.pumpAndSettle();
        expect(c.snapshot.activeGoals.map((g) => g.id), [2, 1, 3]);
        await move('drag-goal-2', 'drag-goal-3', after: true);
        expect(c.snapshot.activeGoals.map((g) => g.id), [1, 3, 2]);
        await move('drag-goal-2', 'drag-goal-1');
        await move('drag-goal-3', 'drag-goal-1', after: true);
        expect(c.snapshot.activeGoals.map((g) => g.id), [2, 1, 3]);
        await tester.tap(find.text('Gesundheit'));
        await tester.pumpAndSettle();
        expect(find.byType(GoalDetail), findsOneWidget);
        await move('drag-milestone-2', 'drag-milestone-1');
        expect(c.snapshot.forGoal(1).map((m) => m.id), [2, 1]);
        Navigator.of(tester.element(find.byType(GoalDetail))).pop();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zwischenziele').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('goal-jump-2')));
        await tester.pump(const Duration(milliseconds: 70));
        await move('drag-milestone-1', 'drag-milestone-3');
        expect(c.snapshot.forGoal(2).map((m) => m.id), [1, 3]);
        await move('drag-milestone-1', 'drop-goal-3');
        expect(c.snapshot.forGoal(3).single.id, 1);
        await tester.tap(find.byKey(const ValueKey('goal-jump-2')));
        await tester.pump(const Duration(milliseconds: 70));
        expect(
          tester
              .widget<GoalEmojiSelector>(find.byType(GoalEmojiSelector))
              .selectedId,
          2,
        );
        await tester.pump(const Duration(milliseconds: 900));
        await tester.tap(find.byKey(const ValueKey('goal-jump-1')));
        await tester.pump(const Duration(milliseconds: 70));
        expect(
          tester
              .widget<GoalEmojiSelector>(find.byType(GoalEmojiSelector))
              .selectedId,
          1,
        );
        await tester.pump(const Duration(milliseconds: 120));
        expect(
          tester
              .widget<GoalEmojiSelector>(find.byType(GoalEmojiSelector))
              .selectedId,
          isNull,
        );
        await tester.pumpAndSettle();
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await db.close();
      }
    },
  );
  testWidgets(
    'drag auto-scrolls beyond source viewport and keeps source alive',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = GoalsRepository(db);
      final c = GoalsController(r);
      try {
        await r.saveGoal(title: 'Gesundheit');
        for (var i = 0; i < 20; i++) {
          await r.saveMilestone(goalId: 1, title: 'Schritt $i');
        }
        await c.load();
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zwischenziele').last);
        await tester.pumpAndSettle();
        final scroll = find.byType(CustomScrollView);
        final source = find.byKey(const ValueKey('drag-milestone-1'));
        final gesture = await tester.startGesture(tester.getCenter(source));
        await tester.pump(const Duration(milliseconds: 650));
        final bottom = tester.getBottomLeft(scroll) + const Offset(150, -12);
        await gesture.moveTo(bottom);
        // Real frame steps also verify scrolling continues with a stationary finger.
        for (var i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        expect(position.pixels, greaterThan(300));
        await gesture.moveTo(bottom - const Offset(0, 90));
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(c.snapshot.forGoal(1).first.id, isNot(1));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await db.close();
      }
    },
  );
  testWidgets(
    'headings navigate to details and back to the actual focused tab',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = GoalsRepository(db);
      final c = GoalsController(r);
      try {
        await r.saveGoal(title: 'Gesundheit', emoji: '🌿');
        for (var i = 0; i < 30; i++) {
          await r.saveMilestone(goalId: 1, title: 'Schritt $i');
        }
        await r.saveGoal(title: 'Lernen', emoji: '📚');
        await r.saveMilestone(goalId: 2, title: 'Buch lesen');
        await c.load();
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lernen'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Zwischenziele'));
        await tester.tap(find.text('Zwischenziele'));
        await tester.pumpAndSettle();
        expect(find.byType(GoalDetail), findsNothing);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        expect(find.text('📚 Lernen').hitTestable(), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('📚 Lernen'));
          await tester.pumpAndSettle();
          expect(tester.widget<GoalDetail>(find.byType(GoalDetail)).goalId, 2);
          await tester.ensureVisible(find.text('Zwischenziele'));
          await tester.tap(find.text('Zwischenziele'));
          await tester.pumpAndSettle();
          expect(find.byType(GoalDetail), findsNothing);
          expect(find.text('📚 Lernen').hitTestable(), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            1,
          );
        }
        await tester.tap(
          find.byTooltip('Zwischenziel hinzufügen').hitTestable().first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Neues Zwischenziel'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await db.close();
      }
    },
  );
}
