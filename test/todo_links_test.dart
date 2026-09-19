import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/app.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/backup_codec.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';
import 'package:guided_notes/features/todos/presentation/progress_increment_picker.dart';

import 'fixtures/legacy_todos.dart';

void main() {
  final fixedNow = DateTime(2026, 9, 18, 12);
  late AppDatabase db;
  late GoalsRepository r;
  late int goalId;
  late int milestoneId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    r = GoalsRepository(db, now: () => fixedNow);
    await r.saveGoal(
      motivation: 'Meine persönliche Richtung',
      title: 'Gesundheit',
    );
    goalId = (await r.load()).goals.single.id;
    await r.saveMilestone(
      motivation: 'Mein nächster Schritt zum Ziel',
      goalId: goalId,
      title: 'Bewegen',
      progress: 90,
      status: MilestoneStatus.offTrack,
    );
    milestoneId = (await r.load()).milestones.single.id;
  });
  tearDown(() => db.close());
  Future<TodoEntry> create({
    int increment = 7,
    TodoFrequency frequency = TodoFrequency.weekly,
  }) async {
    await r.todos.save(
      title: 'Laufen',
      frequency: frequency,
      target: frequency == TodoFrequency.daily ? 1 : 5,
      milestoneId: milestoneId,
      progressIncrement: increment,
    );
    return (await r.load()).todoEntries.last;
  }

  test(
    'each weekly repetition credits actual capped amount and undoes in reverse',
    () async {
      final entry = await create();
      await r.todos.changeCount(entry, 1);
      expect((await r.load()).milestones.single.progress, 97);
      await r.todos.changeCount(entry, 1);
      await r.todos.changeCount(entry, 1);
      var s = await r.load();
      expect(s.milestones.single.status, MilestoneStatus.achieved);
      expect(s.todoCredits.map((c) => c.amount), [7, 3, 0]);
      await r.todos.changeCount(entry, -1);
      expect((await r.load()).milestones.single.progress, 100);
      await r.todos.changeCount(entry, -1);
      s = await r.load();
      expect(s.milestones.single.progress, 97);
      expect(s.milestones.single.status, MilestoneStatus.offTrack);
      await r.todos.changeCount(entry, -1);
      expect((await r.load()).milestones.single.progress, 90);
      expect((await r.load()).todoCredits, isEmpty);
      await expectLater(
        r.todos.changeCount(entry, -1),
        throwsA(isA<RuleViolation>()),
      );
    },
  );

  test('link-only, switching links and disabling tracking leave old contributions reversible', () async {
    final entry = await create(increment: 0);
    await r.todos.changeCount(entry, 1);
    expect((await r.load()).milestones.single.progress, 90);
    await r.todos.save(
      id: entry.templateId,
      title: 'Laufen',
      frequency: entry.frequency,
      target: 5,
      milestoneId: milestoneId,
      progressIncrement: 5,
    );
    await r.todos.changeCount(
      entry,
      1,
    ); // Reads the updated configuration, not the stale widget.
    await r.saveMilestone(
      motivation: 'Mein nächster Schritt zum Ziel',
      goalId: goalId,
      title: 'Schlafen',
      progress: 10,
    );
    final otherId = (await r.load()).milestones.last.id;
    await r.todos.save(
      id: entry.templateId,
      title: 'Laufen',
      frequency: entry.frequency,
      target: 5,
      milestoneId: otherId,
      progressIncrement: 20,
    );
    await r.todos.changeCount(entry, 1);
    await r.todos.save(
      id: entry.templateId,
      title: 'Laufen',
      frequency: entry.frequency,
      target: 5,
    );
    await r.todos.changeCount(entry, -1);
    await r.todos.changeCount(entry, -1);
    await r.todos.changeCount(entry, -1);
    expect((await r.load()).milestones.map((m) => m.progress), [90, 10]);
  });

  test('rollover starts fresh without duplicate credits; stale periods cannot mutate', () async {
    var now = fixedNow;
    r = GoalsRepository(db, now: () => now);
    final entry = await create(frequency: TodoFrequency.daily, increment: 2);
    await r.todos.changeCount(entry, 1);
    now = DateTime(2026, 9, 19);
    var s = await r.load();
    await r.load();
    expect(s.todoEntries, hasLength(2));
    expect(s.milestones.single.progress, 92);
    await expectLater(
      r.todos.changeCount(entry, -1),
      throwsA(isA<RuleViolation>()),
    );
    await r.todos.changeCount(s.todoEntries.first, 1);
    s = await r.load();
    expect(s.milestones.single.progress, 94);
    now =
        fixedNow; // Returning to a stored day does not create a second credit.
    await r.load();
    await expectLater(
      r.todos.changeCount(entry, 1),
      throwsA(isA<RuleViolation>()),
    );
    expect((await r.load()).milestones.single.progress, 94);
  });

  test('archiving pauses new credits, deletion preserves todos, and manual edits remain bounded', () async {
    final entry = await create(increment: 5);
    await r.todos.changeCount(entry, 1);
    await r.saveMilestone(
      motivation: 'Mein nächster Schritt zum Ziel',
      id: milestoneId,
      goalId: goalId,
      title: 'Bewegen',
      progress: 98,
      status: MilestoneStatus.onHold,
    );
    await r.todos.changeCount(entry, -1);
    expect((await r.load()).milestones.single.progress, 93);
    expect((await r.load()).milestones.single.status, MilestoneStatus.onHold);
    await r.todos.changeCount(entry, 1);
    await r.setArchived(goalId, true);
    await r.todos.changeCount(entry, 1);
    expect((await r.load()).milestones.single.progress, 98);
    await r.todos.changeCount(entry, -1);
    await r.todos.changeCount(entry, -1);
    expect((await r.load()).milestones.single.progress, 93);
    await r.setArchived(goalId, false);
    await r.todos.changeCount(entry, 1);
    await r.deleteMilestone(milestoneId, goalId);
    var s = await r.load();
    expect(s.todoTemplates.single.milestoneId, isNull);
    expect(s.todoEntries.single.milestoneId, isNull);
    expect(s.todoCredits.single.milestoneId, isNull);
    await r.todos.changeCount(entry, -1);
    s = await r.load();
    expect(s.todoEntries.single.completed, 0);
  });

  test(
    'count, credit and milestone update roll back together on write failure',
    () async {
      final entry = await create();
      final before = await r.exportBackup();
      await db.customStatement(
        "CREATE TRIGGER fail_credit BEFORE INSERT ON todo_progress_credits BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(r.todos.changeCount(entry, 1), throwsA(anything));
      expect(await r.exportBackup(), before);
      await db.customStatement('DROP TRIGGER fail_credit');
      await r.todos.changeCount(entry, 1);
      final completed = await r.exportBackup();
      await db.customStatement(
        "CREATE TRIGGER fail_undo BEFORE DELETE ON todo_progress_credits BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(r.todos.changeCount(entry, -1), throwsA(anything));
      expect(await r.exportBackup(), completed);
    },
  );

  test(
    'schema 7 migration, reopen and backup preserve credit history for undo',
    () async {
      final dir = await Directory.systemTemp.createTemp('todo_links_');
      final file = File('${dir.path}/store.sqlite');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db, now: () => fixedNow);
      await r.saveGoal(motivation: 'Meine persönliche Richtung', title: 'Alt');
      final g = (await r.load()).goals.single;
      await r.saveMilestone(
        motivation: 'Mein nächster Schritt zum Ziel',
        goalId: g.id,
        title: 'Alt',
        progress: 20,
      );
      milestoneId = (await r.load()).milestones.single.id;
      await r.todos.save(
        title: 'Alt',
        frequency: TodoFrequency.weekly,
        target: 5,
      );
      final entry = (await r.load()).todoEntries.single;
      await r.todos.changeCount(entry, 1);
      await db.close();
      final old = sqlite.sqlite3.open(file.path);
      removeTodoLinks(old);
      old.execute('PRAGMA user_version=7');
      old.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db, now: () => fixedNow);
      expect((await r.load()).todoEntries.single.completed, 1);
      await r.todos.save(
        id: entry.templateId,
        title: 'Alt',
        frequency: entry.frequency,
        target: 5,
        milestoneId: milestoneId,
        progressIncrement: 10,
      );
      await r.todos.changeCount(entry, 1);
      final backup = await r.exportBackup();
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      r = GoalsRepository(db, now: () => fixedNow);
      expect(await r.exportBackup(), backup);
      await r.deleteAllContents();
      await db.customStatement(
        "CREATE TRIGGER fail_credit_import BEFORE INSERT ON todo_progress_credits BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(r.importBackup(backup), throwsA(anything));
      expect((await r.load()).isEmpty, isTrue);
      await db.customStatement('DROP TRIGGER fail_credit_import');
      await r.importBackup(backup);
      expect(await r.exportBackup(), backup);
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (v) => v['todoTemplates'][0]['milestoneId'] = 9999,
        (v) => v['todoEntries'][0]['progressIncrement'] = maxMetricValue + 1,
        (v) => v['todoCredits'][0]['ordinal'] = 999,
        (v) => v['todoCredits'].add(v['todoCredits'][0]),
      ]) {
        final invalid = jsonDecode(backup) as Map<String, dynamic>;
        mutate(invalid);
        expect(
          () => BackupCodec.decode(jsonEncode(invalid)),
          throwsA(isA<RuleViolation>()),
        );
      }
      await r.todos.changeCount(entry, -1);
      await r.todos.changeCount(
        entry,
        -1,
      ); // Legacy completion had no contribution.
      expect((await r.load()).milestones.single.progress, 20);
      final legacy = jsonDecode(backup) as Map<String, dynamic>;
      legacy['version'] = 6;
      expect(
        BackupCodec.decode(jsonEncode(legacy)).todoTemplates.single.milestoneId,
        isNull,
      );
      await db.close();
      db = AppDatabase(NativeDatabase.memory());
      await dir.delete(recursive: true);
    },
  );

  testWidgets('choose link, enable progress, complete and undo through UI', (
    tester,
  ) async {
    final c = GoalsController(r);
    await c.load();
    await tester.pumpWidget(GuideApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tagesaufgabe hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Spaziergang');
    await tester.tap(find.byKey(const ValueKey('todo-milestone')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Zwischenziel suchen'),
      'Beweg',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bewegen'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('todo-track-progress')),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(
      tester
          .widget<ProgressIncrementPicker>(find.byType(ProgressIncrementPicker))
          .value,
      2.5,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CupertinoPicker).first);
    await tester.drag(
      find.byType(CupertinoPicker).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    final wheel = tester.widget<CupertinoPicker>(
      find.byType(CupertinoPicker).first,
    );
    expect(wheel.scrollController!.selectedItem, greaterThan(2));
    wheel.scrollController!.animateToItem(
      8,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Speichern'));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(c.snapshot.todoTemplates.single.milestoneId, milestoneId);
    expect(c.snapshot.todoTemplates.single.progressIncrement, 8.5);
    expect(find.text('+8,5 %'), findsOneWidget);
    expect(find.textContaining('Gesundheit · Bewegen'), findsNothing);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(c.snapshot.milestones.single.progress, 98.5);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(c.snapshot.milestones.single.progress, 90);
    await tester.tap(find.byTooltip('Spaziergang bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Gesundheit · Bewegen'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoPicker>(find.byType(CupertinoPicker).first)
          .scrollController!
          .selectedItem,
      8,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'goal selector disappears down and reappears after small upward scroll',
    (tester) async {
      await r.saveGoal(
        motivation: 'Meine persönliche Richtung',
        title: 'Zweites Ziel',
      );
      for (var i = 0; i < 20; i++) {
        await r.saveMilestone(
          motivation: 'Mein nächster Schritt zum Ziel',
          goalId: goalId,
          title: 'Schritt $i',
        );
      }
      final c = GoalsController(r);
      await c.load();
      await tester.pumpWidget(GuideApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zwischenziele').last);
      await tester.pumpAndSettle();
      final selector = find.byKey(ValueKey('goal-jump-$goalId'));
      expect(selector.hitTestable(), findsOneWidget);
      Iterable<Semantics> selectedEmojis() => tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byKey(const ValueKey('goal-emoji-selector')),
              matching: find.byType(Semantics),
            ),
          )
          .where((widget) => widget.properties.selected == true);
      await tester.tap(selector);
      await tester.pump(const Duration(milliseconds: 70));
      expect(selectedEmojis(), hasLength(1));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      final fade = tester.widget<Opacity>(
        find.ancestor(of: selector, matching: find.byType(Opacity)).first,
      );
      expect(fade.opacity, greaterThan(0));
      expect(fade.opacity, lessThan(1));
      await tester.pumpAndSettle();
      expect(selector.hitTestable(), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(selector.hitTestable(), findsOneWidget);
      expect(selectedEmojis(), isEmpty);
      await tester.tap(selector);
      await tester.pump(const Duration(milliseconds: 70));
      expect(selectedEmojis(), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
