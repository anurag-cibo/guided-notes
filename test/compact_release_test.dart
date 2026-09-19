import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  test('removing daily and weekly todos preserves credits through restart and next period', () async {
    final dir = await Directory.systemTemp.createTemp('guide_removal_');
    final file = File('${dir.path}/test.sqlite');
    var now = DateTime(2026, 9, 19);
    var db = AppDatabase(NativeDatabase(file));
    var r = GoalsRepository(db, now: () => now);
    try {
      await r.saveGoal(motivation: 'Meine persönliche Richtung', title: 'Ziel');
      await r.saveMilestone(
        motivation: 'Mein nächster Schritt zum Ziel',
        goalId: (await r.load()).goals.single.id,
        title: 'Schritt',
      );
      final milestoneId = (await r.load()).milestones.single.id;
      for (final frequency in TodoFrequency.values) {
        for (final count in [0, 1, if (frequency == TodoFrequency.weekly) 3]) {
          await r.todos.save(
            title: '${frequency.name} $count',
            frequency: frequency,
            target: frequency == TodoFrequency.daily ? 1 : 3,
            milestoneId: milestoneId,
            progressIncrement: 2.5,
          );
          final snapshot = await r.load();
          final entry = snapshot.todoEntries.last;
          for (var i = 0; i < count; i++) {
            await r.todos.changeCount(entry, 1);
          }
          await r.todos.stop(entry.templateId);
          await expectLater(
            r.todos.changeCount(entry, 1),
            throwsA(isA<RuleViolation>()),
          );
        }
      }
      final before = await r.load();
      expect(before.todoTemplates.every((t) => !t.active), isTrue);
      expect(before.todoEntries.map((e) => e.completed), [0, 1, 0, 1, 3]);
      expect(before.milestones.single.progress, 12.5);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db, now: () => now);
      var after = await r.load();
      expect(after.todoTemplates.every((t) => !t.active), isTrue);
      expect(after.todoCredits.length, before.todoCredits.length);
      expect(after.milestones.single.progress, 12.5);
      now = DateTime(2026, 9, 21);
      after = await r.load();
      expect(after.todoEntries.where((e) => e.isCurrent(now)), isEmpty);
      expect(after.todoEntries.length, 5);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  testWidgets(
    'detail opens exact milestone, saves and returns; removal updates both views',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final r = GoalsRepository(db);
      final c = GoalsController(r);
      for (final title in ['Erstes Ziel', 'Zweites Ziel']) {
        await r.saveGoal(
          motivation: 'Meine persönliche Richtung',
          title: title,
        );
        final goal = (await r.load()).goals.last;
        for (final name in ['Eins', 'Zwei']) {
          await r.saveMilestone(
            motivation: 'Mein nächster Schritt zum Ziel',
            goalId: goal.id,
            title: '$title $name',
            progress: name == 'Zwei' ? 30 : 10,
          );
        }
      }
      final selected = (await r.load()).milestones.last;
      await r.todos.save(
        title: 'Entfernbarer Schritt',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: selected.id,
        progressIncrement: 2.5,
      );
      await r.todos.save(
        title: 'Bleibender Schritt',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: selected.id,
      );
      await c.load();
      await tester.pumpWidget(GuideApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zweites Ziel'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Zweites Ziel Zwei'), 150);
      await tester.tap(find.text('Zweites Ziel Zwei'));
      await tester.pumpAndSettle();
      expect(find.text('Zwischenziel bearbeiten'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Zweites Ziel Zwei'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).first, 'Geändert');
      await tester.scrollUntilVisible(
        find.text('Speichern'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Zieldetails'), findsOneWidget);
      expect(c.snapshot.milestone(selected.id)!.title, 'Geändert');
      expect(c.snapshot.milestones.first.title, 'Erstes Ziel Eins');
      await tester.tap(find.text('Geändert'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Nicht speichern',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Zieldetails'), findsOneWidget);
      expect(c.snapshot.milestone(selected.id)!.title, 'Geändert');
      await tester.tap(find.text('Geändert'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Entfernbarer Schritt bearbeiten'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byTooltip('Entfernbarer Schritt bearbeiten'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Entfernbarer Schritt bearbeiten'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Aufgabe entfernen'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Aufgabe entfernen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entfernen'));
      await tester.pumpAndSettle();
      expect(find.text('Entfernbarer Schritt'), findsNothing);
      expect(find.text('Bleibender Schritt'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Entfernbarer Schritt'), findsNothing);
      expect(find.text('Bleibender Schritt'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
    },
  );
}
