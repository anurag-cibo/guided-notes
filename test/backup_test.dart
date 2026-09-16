import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/data/backup_codec.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';

void main() {
  late AppDatabase database;
  late GoalsRepository repository;
  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = GoalsRepository(database);
  });
  tearDown(() => database.close());

  Future<String> fixture() async {
    await repository.saveGoal(
      title: 'Bücher 📚',
      emoji: '📚',
      motivation: 'Für mich\nMit Freude',
      dueDate: DateTime(2027, 2, 3),
    );
    final id = (await repository.load()).goals.single.id;
    for (final status in MilestoneStatus.values) {
      await repository.saveMilestone(
        goalId: id,
        title: status.label,
        status: status,
        progress: status == MilestoneStatus.notStarted ? 0 : 40,
        dueDate: DateTime(2027, 1, 1),
      );
    }
    await repository.setAchieved(id, true);
    await repository.setArchived(id, true);
    await repository.saveGoal(title: 'Aktives Ziel');
    return repository.exportBackup();
  }

  test(
    'complete backup round trip survives reopening and future edits',
    () async {
      final backup = await fixture();
      final directory = await Directory.systemTemp.createTemp('guide_backup_');
      final file = File('${directory.path}/restored.sqlite');
      var target = AppDatabase(NativeDatabase(file));
      try {
        await GoalsRepository(target).importBackup(backup);
        expect(await GoalsRepository(target).exportBackup(), backup);
        await target.close();
        target = AppDatabase(NativeDatabase(file));
        final restored = GoalsRepository(target);
        expect(await restored.exportBackup(), backup);
        final snapshot = await restored.load();
        expect(snapshot.activeGoals, hasLength(1));
        expect(snapshot.goals.first.achieved, isTrue);
        expect(snapshot.forGoal(snapshot.goals.first.id), hasLength(5));
        await restored.setArchived(snapshot.goals.first.id, false);
        expect(
          (await restored.load()).progressFor(snapshot.goals.first.id),
          44,
        );
        await restored.saveGoal(title: 'Danach');
        expect(
          (await restored.load()).goals.last.id,
          greaterThan(snapshot.goals.last.id),
        );
      } finally {
        await target.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'existing data including archives cannot be overwritten or duplicated',
    () async {
      final backup = await fixture();
      await expectLater(
        repository.importBackup(backup),
        throwsA(isA<RuleViolation>()),
      );
      expect(await repository.exportBackup(), backup);
    },
  );

  test('malformed backups leave empty and existing stores intact', () async {
    final backup = await fixture();
    final variants = <String>['invalid', '[]'];
    void variant(void Function(Map<String, dynamic>) change) {
      final data = jsonDecode(backup) as Map<String, dynamic>;
      change(data);
      variants.add(jsonEncode(data));
    }

    variant((d) => d['version'] = 2);
    variant((d) => d['version'] = 1.0);
    variant((d) => d['goals'][0]['dueDate'] = '2027-02-30');
    variant((d) => d['goals'][0]['title'] = '  ');
    variant((d) => d['goals'][0]['archived'] = 1);
    variant((d) => d['goals'][0]['id'] = -1);
    variant((d) => d['goals'].add(d['goals'][0]));
    variant((d) => d['milestones'].add(d['milestones'][0]));
    variant((d) => d['milestones'][0]['goalId'] = 900);
    variant((d) => d['milestones'][0]['status'] = 'unknown');
    variant((d) => d['milestones'][0]['progress'] = 100);
    variant((d) => d['milestones'][0]['progress'] = -1);
    variant(
      (d) => d['goals'] = List.generate(
        6,
        (i) => {...d['goals'][1] as Map, 'id': i + 1},
      ),
    );
    final empty = AppDatabase(NativeDatabase.memory());
    try {
      for (final source in variants) {
        await expectLater(
          repository.importBackup(source),
          throwsA(isA<RuleViolation>()),
        );
        expect(await repository.exportBackup(), backup);
        await expectLater(
          GoalsRepository(empty).importBackup(source),
          throwsA(isA<RuleViolation>()),
        );
        expect((await GoalsRepository(empty).load()).goals, isEmpty);
      }
    } finally {
      await empty.close();
    }
    expect(
      () => BackupCodec.decode(' ' * (BackupCodec.maxBytes + 1)),
      throwsA(isA<RuleViolation>()),
    );
  });

  test('database error midway through import rolls back all rows', () async {
    final backup = await fixture();
    final target = AppDatabase(NativeDatabase.memory());
    try {
      await GoalsRepository(target).load();
      await target.customStatement(
        "CREATE TRIGGER fail_import BEFORE INSERT ON milestones BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(
        GoalsRepository(target).importBackup(backup),
        throwsA(anything),
      );
      expect((await GoalsRepository(target).load()).goals, isEmpty);
      expect((await GoalsRepository(target).load()).milestones, isEmpty);
    } finally {
      await target.close();
    }
  });
}
