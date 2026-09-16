import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/data/app_database.dart';
import 'package:guided_notes/features/goals/data/goals_repository.dart';
import 'package:guided_notes/features/goals/domain/models.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase database;
  late GoalsRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('guide_test_');
    file = File('${directory.path}/test.sqlite');
    database = AppDatabase(NativeDatabase(file));
    repository = GoalsRepository(database);
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  test(
    'full close/reopen retains IDs, edits, status, dates and archived children',
    () async {
      await repository.saveGoal(
        title: 'Buch',
        motivation: 'Etwas erzählen',
        dueDate: DateTime(2027, 2, 3),
      );
      final id = (await repository.load()).goals.single.id;
      await repository.saveMilestone(
        goalId: id,
        title: 'Entwurf',
        progress: 25,
        status: MilestoneStatus.onHold,
      );
      final milestoneId = (await repository.load()).milestones.single.id;
      await repository.saveMilestone(
        id: milestoneId,
        goalId: id,
        title: 'Erster Entwurf',
        status: MilestoneStatus.achieved,
      );
      await repository.setAchieved(id, true);
      await repository.setArchived(id, true);
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      repository = GoalsRepository(database);
      final restored = await repository.load();
      expect(restored.activeGoals, isEmpty);
      expect(restored.goals.single.id, id);
      expect(restored.goals.single.motivation, 'Etwas erzählen');
      expect(restored.goals.single.dueDate, DateTime(2027, 2, 3));
      expect(restored.goals.single.achieved, isTrue);
      expect(restored.milestones.single.id, milestoneId);
      expect(restored.milestones.single.title, 'Erster Entwurf');
      expect(restored.progressFor(id), 100);
      await repository.setArchived(id, false);
      expect((await repository.load()).activeGoals, hasLength(1));
    },
  );
  test('rapid creates and restores cannot exceed five active goals', () async {
    final outcomes = await Future.wait(
      List.generate(8, (i) async {
        try {
          await repository.saveGoal(title: 'Ziel $i');
          return true;
        } on RuleViolation {
          return false;
        }
      }),
    );
    expect(outcomes.where((saved) => saved), hasLength(5));
    final id = (await repository.load()).goals.first.id;
    await repository.setArchived(id, true);
    await repository.saveGoal(title: 'Neues Ziel');
    await expectLater(
      repository.setArchived(id, false),
      throwsA(isA<RuleViolation>()),
    );
    expect((await repository.load()).goal(id)!.archived, isTrue);
    await expectLater(
      database.customStatement("INSERT INTO goals(title) VALUES ('Bypass')"),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement('UPDATE goals SET archived = 0 WHERE id = ?', [
        id,
      ]),
      throwsA(anything),
    );
    expect((await repository.load()).activeGoals, hasLength(5));
  });
  test(
    'foreign keys, rollback, cascade and validation preserve integrity',
    () async {
      await expectLater(
        repository.saveMilestone(goalId: 999, title: 'Orphan'),
        throwsA(isA<RuleViolation>()),
      );
      await expectLater(
        database.customStatement(
          "INSERT INTO milestones(goal_id,title) VALUES(999,'Orphan')",
        ),
        throwsA(anything),
      );
      await repository.saveGoal(title: 'Original');
      final id = (await repository.load()).goals.single.id;
      await repository.saveMilestone(goalId: id, title: 'Kind');
      await expectLater(
        database.transaction(() async {
          await database.customStatement(
            "UPDATE goals SET title='Changed' WHERE id=?",
            [id],
          );
          await database.customStatement(
            "INSERT INTO milestones(goal_id,title,progress) VALUES(?, 'Bad', 101)",
            [id],
          );
        }),
        throwsA(anything),
      );
      expect((await repository.load()).goals.single.title, 'Original');
      await expectLater(
        repository.deleteGoal(id),
        throwsA(isA<RuleViolation>()),
      );
      await repository.setArchived(id, true);
      await expectLater(
        repository.saveMilestone(goalId: id, title: 'Hidden'),
        throwsA(isA<RuleViolation>()),
      );
      await repository.deleteGoal(id);
      expect((await repository.load()).milestones, isEmpty);
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );
}
