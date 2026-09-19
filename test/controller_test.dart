import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/application/goals_controller.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/data/backup_codec.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  test('failed load is visible and retry can recover', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = _FailingRepository(database);
    final controller = GoalsController(repository);
    await controller.load();
    expect(controller.loading, isFalse);
    expect(controller.error, contains('nicht geladen'));
    repository.fail = false;
    await controller.load();
    expect(controller.error, isNull);
    controller.dispose();
    await database.close();
  });

  test('write failure and double save never silently succeed', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final controller = GoalsController(GoalsRepository(database));
    await controller.load();
    final error = await controller.mutate(
      (_) => Future.error(StateError('disk full')),
    );
    expect(error, contains('nicht bestätigt'));
    expect(controller.snapshot.goals, isEmpty);
    expect(controller.saving, isFalse);
    final gate = Completer<void>();
    var notifications = 0;
    controller.addListener(() => notifications++);
    final first = controller.mutate((r) async {
      await gate.future;
      await r.saveGoal(title: 'Einmal');
    });
    expect(controller.saving, isTrue);
    expect(notifications, 0, reason: 'No intermediate disabled UI frame');
    expect(
      await controller.mutate((r) => r.saveGoal(title: 'Doppelt')),
      contains('Bitte kurz warten'),
    );
    gate.complete();
    expect(await first, isNull);
    expect(notifications, 1);
    expect(controller.snapshot.goals.single.title, 'Einmal');
    controller.dispose();
    await database.close();
  });

  test('count changes reuse static data and match full reload after relinking and undo', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repository = _CountingRepository(db);
    final c = GoalsController(repository);
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    await repository.saveGoal(title: 'Ziel');
    final goalId = (await repository.load()).goals.single.id;
    await repository.saveMilestone(goalId: goalId, title: 'A', progress: 95);
    await repository.saveMilestone(goalId: goalId, title: 'B', progress: 20);
    final milestones = (await repository.load()).milestones;
    await repository.todos.save(
      title: 'Wochenaufgabe',
      frequency: TodoFrequency.weekly,
      target: 5,
      milestoneId: milestones.first.id,
      progressIncrement: 8,
    );
    await repository.todos.save(
      title: 'Andere Aufgabe',
      frequency: TodoFrequency.daily,
      target: 1,
    );
    await c.load();
    final staticGoal = c.snapshot.goals.single;
    final untouched = c.snapshot.todoEntries.firstWhere(
      (e) => e.frequency == TodoFrequency.daily,
    );
    var loadCount = repository.loads;
    var entry = c.snapshot.todoEntries.firstWhere(
      (e) => e.frequency == TodoFrequency.weekly,
    );
    expect(await c.changeTodoCount(entry, 1), isNull);
    expect(
      repository.loads,
      loadCount,
      reason: 'No full database reload per click',
    );
    expect(identical(c.snapshot.goals.single, staticGoal), isTrue);
    expect(c.snapshot.todoEntries.any((e) => identical(e, untouched)), isTrue);
    expect(c.snapshot.milestones.first.progress, 100);
    expect(BackupCodec.encode(c.snapshot), await repository.exportBackup());
    await c.mutate(
      (r) => r.todos.save(
        id: entry.templateId,
        title: entry.title,
        frequency: entry.frequency,
        target: 5,
        milestoneId: milestones.last.id,
        progressIncrement: 3,
      ),
    );
    entry = c.snapshot.todoEntries.firstWhere(
      (e) => e.frequency == TodoFrequency.weekly,
    );
    for (final delta in [1, -1, -1]) {
      loadCount = repository.loads;
      expect(await c.changeTodoCount(entry, delta), isNull);
      expect(repository.loads, loadCount);
      expect(BackupCodec.encode(c.snapshot), await repository.exportBackup());
    }
    expect(c.snapshot.milestones.map((m) => m.progress), [95, 20]);
    final before = BackupCodec.encode(c.snapshot);
    await db.customStatement(
      "CREATE TRIGGER fail_credit BEFORE INSERT ON todo_progress_credits BEGIN SELECT RAISE(ABORT, 'test'); END",
    );
    expect(await c.changeTodoCount(entry, 1), contains('nicht bestätigt'));
    expect(BackupCodec.encode(c.snapshot), before);
    expect(await repository.exportBackup(), before);
  });
}

class _CountingRepository extends GoalsRepository {
  _CountingRepository(super.database);
  int loads = 0;
  @override
  load() {
    loads++;
    return super.load();
  }
}

class _FailingRepository extends GoalsRepository {
  _FailingRepository(super.database);
  bool fail = true;
  @override
  load() {
    if (fail) return Future.error(StateError('unavailable'));
    return super.load();
  }
}
