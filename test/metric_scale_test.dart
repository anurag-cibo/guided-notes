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
import 'package:guided_notes/features/todos/domain/todo_models.dart';

import 'fixtures/legacy_todos.dart';

import 'package:guided_notes/features/todos/presentation/todo_group.dart';

void main() {
  late AppDatabase db;
  late GoalsRepository r;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    r = GoalsRepository(db);
    await r.saveGoal(motivation: 'Meine persönliche Richtung', title: 'Lernen');
  });
  tearDown(() => db.close());

  test(
    'arbitrary start, units, ascending/descending and precise normalization',
    () {
      const up = MetricScale(start: 80, target: 100, unit: 'Bücher');
      const down = MetricScale(start: 100, target: 80, unit: 'kg');
      expect(up.percent(90), 50);
      expect(down.percent(90), 50);
      expect(down.contribution(.5), '−0,5 kg');
      expect(const MetricScale(unit: '').format(2.5), '2,5');
      expect(const MetricScale(target: 1000000).percent(.01), .01);
      expect(const MetricScale(target: 1000000).percent(999999.99), 99.99);
      expect(
        () => const MetricScale(start: 1, target: 1).validate(),
        throwsArgumentError,
      );
      expect(() => metricUnits(.001), throwsArgumentError);
    },
  );

  test(
    'page contributions above 100, weekly target and capped exact undo',
    () async {
      await r.saveMilestone(
        goalId: 1,
        title: 'Buch lesen',
        motivation: 'Wissen vertiefen',
        scale: const MetricScale(target: 300, unit: 'Seiten'),
        currentValue: 0,
      );
      await r.todos.save(
        title: 'Lesen',
        frequency: TodoFrequency.weekly,
        target: 3,
        milestoneId: 1,
        progressIncrement: 150,
      );
      var entry = (await r.load()).todoEntries.single;
      await r.todos.changeCount(entry, 1);
      expect((await r.load()).milestones.single.currentValue, 150);
      expect((await r.load()).progressFor(1), 50);
      await r.todos.changeCount(entry, 1);
      await r.todos.changeCount(entry, 1);
      expect((await r.load()).todoCredits.map((c) => c.valueAmount), [
        150,
        150,
        0,
      ]);
      await r.todos.changeCount(entry, -1);
      expect((await r.load()).milestones.single.currentValue, 300);
      await r.todos.changeCount(entry, -1);
      expect((await r.load()).milestones.single.currentValue, 150);
      await r.todos.save(
        id: entry.templateId,
        title: 'Lesen',
        frequency: TodoFrequency.weekly,
        target: 3,
        milestoneId: 1,
        progressIncrement: 20,
        progressMode: TodoProgressMode.onTarget,
      );
      entry = (await r.load()).todoEntries.single;
      await r.todos.changeCount(entry, 1);
      expect((await r.load()).milestones.single.currentValue, 150);
      await r.todos.changeCount(entry, 1);
      expect((await r.load()).milestones.single.currentValue, 170);
      await r.todos.changeCount(entry, -1);
      expect((await r.load()).milestones.single.currentValue, 150);
    },
  );

  test(
    'descending amounts survive scale edits, goal moves and backup',
    () async {
      await r.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Gesundheit',
      );
      await r.saveMilestone(
        goalId: 1,
        title: 'Gewicht',
        motivation: 'Mehr Wohlbefinden',
        scale: const MetricScale(start: 100, target: 80, unit: 'kg'),
        currentValue: 81,
      );
      await r.todos.save(
        title: 'Ein Schritt',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: 1,
        progressIncrement: 2.5,
      );
      await r.todos.changeCount((await r.load()).todoEntries.single, 1);
      var snapshot = await r.load();
      expect(snapshot.milestones.single.currentValue, 80);
      expect(snapshot.todoCredits.single.valueAmount, -1);
      expect(snapshot.milestones.single.status, MilestoneStatus.achieved);
      await r.saveMilestone(
        id: 1,
        goalId: 1,
        title: 'Gewicht',
        scale: const MetricScale(start: 100, target: 70, unit: 'kg'),
        currentValue: 80,
        status: MilestoneStatus.onTrack,
      );
      await r.moveMilestone(1, 2);
      final backup = await r.exportBackup();
      await r.deleteAllContents();
      await r.importBackup(backup);
      expect(await r.exportBackup(), backup);
      await r.todos.changeCount((await r.load()).todoEntries.single, -1);
      snapshot = await r.load();
      expect(snapshot.milestones.single.currentValue, 81);
      expect(snapshot.milestones.single.goalId, 2);
      expect(snapshot.progressFor(2), 63.33);
      expect(snapshot.milestones.single.motivation, 'Mehr Wohlbefinden');
      expect(snapshot.todoCredits, isEmpty);
    },
  );

  test(
    'scale validation is atomic; unitless and custom units persist',
    () async {
      await r.saveMilestone(
        goalId: 1,
        title: 'Bücher',
        motivation: 'Neugierig bleiben',
        scale: const MetricScale(target: 12, unit: ''),
        currentValue: 3,
      );
      final backup = await r.exportBackup();
      for (final scale in [
        const MetricScale(start: 2, target: 2),
        const MetricScale(target: .001),
      ]) {
        await expectLater(
          r.saveMilestone(
            id: 1,
            goalId: 1,
            title: 'Ungültig',
            scale: scale,
            currentValue: 0,
          ),
          throwsA(isA<RuleViolation>()),
        );
      }
      await expectLater(
        r.saveMilestone(id: 1, goalId: 1, title: 'Ungültig', currentValue: 13),
        throwsA(isA<RuleViolation>()),
      );
      expect(await r.exportBackup(), backup);
      await r.deleteAllContents();
      await r.importBackup(backup);
      expect((await r.load()).milestones.single.scale.unit, '');
      final invalid = jsonDecode(backup) as Map<String, dynamic>;
      invalid['milestones'][0]['currentValue'] = 99;
      expect(
        () => BackupCodec.decode(jsonEncode(invalid)),
        throwsA(isA<RuleViolation>()),
      );
    },
  );

  test('schema 11 preserves ledger and percent values through restart and legacy backup', () async {
    final directory = await Directory.systemTemp.createTemp(
      'guide_metric_migration_',
    );
    final file = File('${directory.path}/test.sqlite');
    var store = AppDatabase(NativeDatabase(file));
    var repo = GoalsRepository(store);
    try {
      await repo.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Bestehend',
      );
      await repo.saveMilestone(
        goalId: 1,
        title: 'Schritt',
        motivation: 'Fixture',
        progress: 20,
      );
      await repo.todos.save(
        title: 'Todo',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: 1,
        progressIncrement: 2.5,
      );
      await repo.todos.changeCount((await repo.load()).todoEntries.single, 1);
      await store.close();
      final old = sqlite.sqlite3.open(file.path);
      removeMetricScale(old);
      old.execute('PRAGMA user_version=11');
      old.close();
      store = AppDatabase(NativeDatabase(file));
      repo = GoalsRepository(store);
      var snapshot = await repo.load();
      expect(snapshot.milestones.single.currentValue, 22.5);
      expect(snapshot.milestones.single.scale.isStandardPercent, isTrue);
      expect(snapshot.milestones.single.motivation, '');
      expect(snapshot.todoCredits.single.valueAmount, 2.5);
      final legacy =
          jsonDecode(await repo.exportBackup()) as Map<String, dynamic>;
      legacy['version'] = 10;
      for (final milestone in legacy['milestones'] as List) {
        for (final key in [
          'motivation',
          'startValue',
          'targetValue',
          'currentValue',
          'unit',
        ]) {
          (milestone as Map).remove(key);
        }
      }
      for (final credit in legacy['todoCredits'] as List) {
        (credit as Map).remove('valueAmount');
      }
      await store.close();
      store = AppDatabase(NativeDatabase(file));
      repo = GoalsRepository(store);
      await repo.deleteAllContents();
      await repo.importBackup(jsonEncode(legacy));
      await repo.todos.changeCount((await repo.load()).todoEntries.single, -1);
      snapshot = await repo.load();
      expect(snapshot.milestones.single.currentValue, 20);
      expect(snapshot.milestones.single.progress, 20);
      expect(
        await store.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    } finally {
      await store.close();
      await directory.delete(recursive: true);
    }
  });

  testWidgets(
    'bounds clamp immediately and Todo units preview without saving',
    (tester) async {
      await r.saveMilestone(goalId: 1, title: 'Messung', currentValue: 100);
      await r.todos.save(
        title: 'Ein Schritt',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: 1,
        progressIncrement: 2,
      );
      final c = GoalsController(r);
      await c.load();
      try {
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lernen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Messung'));
        await tester.pumpAndSettle();
        final current = find.byKey(const ValueKey('metric-current'));
        final target = find.byKey(const ValueKey('metric-target'));
        final start = find.byKey(const ValueKey('metric-start'));
        String value() =>
            tester.widget<TextFormField>(current).controller!.text;
        await tester.enterText(target, '80');
        await tester.pumpAndSettle();
        expect(value(), '80');
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('metric-slider-value')))
              .data,
          '80',
        );
        await tester.enterText(start, '100');
        await tester.enterText(current, '85');
        await tester.enterText(target, '90');
        await tester.pumpAndSettle();
        expect(value(), '90');
        await tester.tap(find.byKey(const ValueKey('metric-unit-false')));
        await tester.pumpAndSettle();
        expect(find.text('Kilogramm (kg)'), findsNothing);
        await tester.tap(find.text('Eigene Einheit').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('metric-custom-unit')),
          'Gläser',
        );
        await tester.pumpAndSettle();
        expect(find.text('−2 Gläser'), findsOneWidget);
        expect(c.snapshot.milestone(1)!.scale.unit, '%');
        expect(c.snapshot.milestone(1)!.currentValue, 100);
        final slider = find.byKey(const ValueKey('metric-slider'));
        final label = find.byKey(const ValueKey('metric-slider-value'));
        final right = tester.getCenter(label).dx;
        final todoGroups = tester
            .widgetList<TodoGroup>(find.byType(TodoGroup))
            .toList();
        tester.widget<Slider>(slider).onChanged!(33.33);
        await tester.pumpAndSettle();
        expect(value(), '96,7');
        expect(
          tester.widgetList<TodoGroup>(find.byType(TodoGroup)).toList(),
          orderedEquals(todoGroups),
        );
        expect(tester.widget<Text>(label).data, '96,7');
        tester.widget<Slider>(slider).onChanged!(0);
        await tester.pumpAndSettle();
        expect(value(), '100');
        expect(tester.getCenter(label).dx, lessThan(right));
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(c.snapshot.milestone(1)!.scale.unit, '%');
        expect(c.snapshot.milestone(1)!.scale.target, 100);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      }
    },
  );

  testWidgets(
    'create measurement without why, set unit and contribute using the linked unit',
    (tester) async {
      final c = GoalsController(r);
      await c.load();
      try {
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lernen'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Zwischenziel hinzufügen'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Bücher lesen',
        );
        expect(find.byKey(const ValueKey('milestone-why')), findsNothing);
        final units = find.byKey(const ValueKey('metric-unit-false'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(units);
        await tester.pumpAndSettle();
        await tester.tap(units);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Eigene Einheit').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('metric-custom-unit')),
          'Bücher',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('metric-target')),
          '12',
        );
        await tester.enterText(
          find.byKey(const ValueKey('metric-current')),
          '3',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        expect(c.snapshot.milestones.single.currentValue, 3);
        expect(c.snapshot.milestones.single.progress, 25);
        expect(c.snapshot.milestones.single.scale.unit, 'Bücher');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Bücher lesen'));
        await tester.tap(find.text('Bücher lesen'));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Tagesaufgabe hinzufügen'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tagesaufgabe hinzufügen'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Ein Buch');
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('todo-value-increment')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('todo-value-increment')),
          '1',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(Checkbox));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(c.snapshot.milestones.single.currentValue, 4);
        expect(c.snapshot.milestones.single.progress, 33.33);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      }
    },
  );
  testWidgets(
    'custom unit and unitless values fit narrow screens with large text',
    (tester) async {
      await r.saveMilestone(
        goalId: 1,
        title: 'Meine Messung',
        motivation: 'Meine eigene Richtung verfolgen',
        scale: const MetricScale(start: 70, target: 90, unit: 'Liegestütze'),
        currentValue: 80,
      );
      final c = GoalsController(r);
      await c.load();
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      try {
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lernen'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Meine Messung'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Meine Messung'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('metric-custom-unit')),
          findsOneWidget,
        );
        final unit = find.byKey(const ValueKey('metric-unit-true'));
        await tester.ensureVisible(unit);
        await tester.pumpAndSettle();
        await tester.tap(unit);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Ohne Einheit').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ohne Einheit').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        expect(c.snapshot.milestones.single.scale.unit, '');
        expect(c.snapshot.milestones.single.currentValue, 80);
        expect(c.snapshot.milestones.single.progress, 50);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      }
    },
  );
  testWidgets(
    'large contribution stays editable after switching to standard percent',
    (tester) async {
      await r.saveMilestone(
        goalId: 1,
        title: 'Lesen',
        motivation: 'Wissen',
        scale: const MetricScale(target: 300, unit: 'Seiten'),
        currentValue: 150,
      );
      await r.todos.save(
        title: 'Lesestunde',
        frequency: TodoFrequency.daily,
        target: 1,
        milestoneId: 1,
        progressIncrement: 150,
      );
      await r.saveMilestone(
        id: 1,
        goalId: 1,
        title: 'Lesen',
        scale: const MetricScale(),
        currentValue: 50,
      );
      final c = GoalsController(r);
      await c.load();
      try {
        await tester.pumpWidget(GuideApp(controller: c));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Todos'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Lesestunde bearbeiten'));
        await tester.pumpAndSettle();
        final amount = find.byKey(const ValueKey('todo-value-increment'));
        await tester.ensureVisible(amount);
        await tester.pumpAndSettle();
        expect(tester.widget<TextFormField>(amount).controller!.text, '150');
        await tester.enterText(amount, '25');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(c.snapshot.milestones.single.currentValue, 75);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      }
    },
  );
}
