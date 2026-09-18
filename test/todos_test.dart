import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/data/backup_codec.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';
import 'package:guided_notes/features/todos/domain/todo_models.dart';

void main() {
  late AppDatabase database;
  late GoalsRepository repository;
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 9, 20, 23, 59); // Sunday
    database = AppDatabase(NativeDatabase.memory());
    repository = GoalsRepository(database, now: () => now);
  });
  tearDown(() => database.close());

  Future<void> seed() async {
    await repository.todos.save(
      title: 'Lesen',
      frequency: TodoFrequency.daily,
      target: 1,
    );
    await repository.todos.save(
      title: 'Laufen',
      frequency: TodoFrequency.weekly,
      target: 3,
    );
  }

  test('periods follow calendar dates across year and DST boundaries', () {
    expect(
      periodStart(TodoFrequency.weekly, DateTime(2027, 1, 1)),
      '2026-12-28',
    );
    expect(
      periodStart(TodoFrequency.weekly, DateTime(2026, 3, 29, 23)),
      '2026-03-23',
    );
    expect(
      periodStart(TodoFrequency.weekly, DateTime(2026, 3, 30)),
      '2026-03-30',
    );
    expect(
      periodStart(TodoFrequency.daily, DateTime(2026, 10, 25, 2)),
      '2026-10-25',
    );
  });

  test(
    'counts, undo, immutable snapshots, missed periods and clock rollback',
    () async {
      await seed();
      var snapshot = await repository.load();
      final daily = snapshot.todoEntries.firstWhere(
        (e) => e.frequency == TodoFrequency.daily,
      );
      final weekly = snapshot.todoEntries.firstWhere(
        (e) => e.frequency == TodoFrequency.weekly,
      );
      await repository.todos.changeCount(daily, 1);
      await expectLater(
        repository.todos.changeCount(daily, 1),
        throwsA(isA<RuleViolation>()),
      );
      await repository.todos.changeCount(daily, -1);
      await expectLater(
        repository.todos.changeCount(daily, -1),
        throwsA(isA<RuleViolation>()),
      );
      for (var i = 0; i < 3; i++) {
        await repository.todos.changeCount(weekly, 1);
      }
      await expectLater(
        repository.todos.changeCount(weekly, 1),
        throwsA(isA<RuleViolation>()),
      );
      await repository.todos.save(
        id: weekly.templateId,
        title: 'Joggen',
        frequency: TodoFrequency.weekly,
        target: 2,
      );
      expect(
        (await repository.load()).todoEntries
            .firstWhere((e) => e.frequency == TodoFrequency.weekly)
            .title,
        'Laufen',
      );
      now = DateTime(2026, 9, 21);
      snapshot = await repository.load();
      final current = snapshot.todoEntries
          .where((e) => e.isCurrent(now))
          .toList();
      expect(current, hasLength(2));
      expect(current.every((e) => e.completed == 0), isTrue);
      expect(
        current.firstWhere((e) => e.frequency == TodoFrequency.weekly).target,
        2,
      );
      expect(
        current.firstWhere((e) => e.frequency == TodoFrequency.weekly).title,
        'Joggen',
      );
      await expectLater(
        repository.todos.changeCount(weekly, -1),
        throwsA(isA<RuleViolation>()),
      );
      expect((await repository.load()).todoEntries, hasLength(4));
      now = DateTime(2026, 10, 5);
      expect(
        (await repository.load()).todoEntries,
        hasLength(6),
      ); // No invented skipped periods.
      now = DateTime(2026, 9, 20);
      snapshot = await repository.load();
      expect(snapshot.todoEntries, hasLength(6));
      final restored = snapshot.todoEntries.firstWhere(
        (e) => e.frequency == TodoFrequency.weekly && e.isCurrent(now),
      );
      expect(restored.title, 'Laufen');
      expect(restored.completed, 3);
    },
  );

  test(
    'stopping keeps current and historical results, and validates targets',
    () async {
      await seed();
      final before = await repository.load();
      for (final t in before.todoTemplates) {
        await repository.todos.stop(t.id);
      }
      expect((await repository.load()).todoEntries, hasLength(2));
      now = DateTime(2026, 9, 21);
      final after = await repository.load();
      expect(after.todoEntries.where((e) => e.isCurrent(now)), isEmpty);
      expect(after.todoEntries, hasLength(2));
      for (final target in [0, -1, 1000]) {
        await expectLater(
          repository.todos.save(
            title: 'X',
            frequency: TodoFrequency.weekly,
            target: target,
          ),
          throwsA(isA<RuleViolation>()),
        );
      }
      await expectLater(
        repository.todos.save(
          title: 'X',
          frequency: TodoFrequency.daily,
          target: 2,
        ),
        throwsA(isA<RuleViolation>()),
      );
      await expectLater(
        repository.todos.save(
          title: ' ',
          frequency: TodoFrequency.daily,
          target: 1,
        ),
        throwsA(isA<RuleViolation>()),
      );
    },
  );

  test(
    'v2 backup preserves routines and rejects malformed or occupied imports',
    () async {
      await seed();
      await repository.todos.changeCount(
        (await repository.load()).todoEntries.first,
        1,
      );
      now = DateTime(2026, 9, 21);
      final backup = await repository.exportBackup();
      final target = AppDatabase(NativeDatabase.memory());
      final restored = GoalsRepository(target, now: () => now);
      try {
        await restored.importBackup(backup);
        expect(await restored.exportBackup(), backup);
        await expectLater(
          restored.importBackup(backup),
          throwsA(isA<RuleViolation>()),
        );
        for (final edit in <void Function(Map<String, dynamic>)>[
          (d) => d['todoTemplates'][0]['target'] = 0,
          (d) => d['todoEntries'][0]['templateId'] = 999,
          (d) => d['todoEntries'][0]['period'] = '2026-02-30',
          (d) => d['todoEntries'][0]['completed'] = 1000,
          (d) => d['todoEntries'].add(d['todoEntries'][0]),
          (d) => d['todoTemplates'].add(d['todoTemplates'][0]),
          (d) => d['todoEntries'][0]['frequency'] = 'monthly',
        ]) {
          final data = jsonDecode(backup) as Map<String, dynamic>;
          edit(data);
          expect(
            () => BackupCodec.decode(jsonEncode(data)),
            throwsA(isA<RuleViolation>()),
          );
        }
      } finally {
        await target.close();
      }
    },
  );

  test(
    'legacy v1 backup imports, and todo import rolls back on database failure',
    () async {
      await repository.importBackup(
        jsonEncode({
          'format': 'the-guide',
          'version': 1,
          'goals': [],
          'milestones': [],
        }),
      );
      expect((await repository.load()).isEmpty, isTrue);
      await seed();
      final backup = await repository.exportBackup();
      final target = AppDatabase(NativeDatabase.memory());
      final restored = GoalsRepository(target, now: () => now);
      try {
        await restored.load();
        await target.customStatement(
          "CREATE TRIGGER fail_todo BEFORE INSERT ON todo_entries BEGIN SELECT RAISE(ABORT, 'test'); END",
        );
        await expectLater(restored.importBackup(backup), throwsA(anything));
        expect((await restored.load()).isEmpty, isTrue);
      } finally {
        await target.close();
      }
    },
  );

  test(
    'real v1 migration preserves goals and routines survive full reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('guide_todos_');
      final file = File('${directory.path}/legacy.sqlite');
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute(await File('test/fixtures/schema_v1.sql').readAsString());
      legacy.execute(
        "INSERT INTO goals(id,title,motivation,archived,due_date) VALUES(42,'Alt','Bleibt',1,'2027-01-01')",
      );
      legacy.execute(
        "INSERT INTO milestones(id,goal_id,title,status,progress) VALUES(7,42,'Schritt','onHold',30)",
      );
      legacy.close();
      var migrated = AppDatabase(NativeDatabase(file));
      try {
        var repo = GoalsRepository(migrated, now: () => now);
        final before = await repo.load();
        expect(before.goals.single.id, 42);
        expect(before.goals.single.archived, isTrue);
        expect(before.goals.single.motivation, 'Bleibt');
        expect(before.goals.single.dueDate, DateTime(2027, 1, 1));
        expect(before.milestones.single.progress, 30);
        expect(before.milestones.single.id, 7);
        await repo.todos.save(
          title: 'Lesen',
          frequency: TodoFrequency.daily,
          target: 1,
        );
        await repo.todos.changeCount((await repo.load()).todoEntries.single, 1);
        final backup = await repo.exportBackup();
        expect(
          await migrated.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        await migrated.close();
        migrated = AppDatabase(NativeDatabase(file));
        repo = GoalsRepository(migrated, now: () => now);
        expect(await repo.exportBackup(), backup);
      } finally {
        await migrated.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
