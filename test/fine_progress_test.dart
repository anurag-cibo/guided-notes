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
  final now = DateTime(2026, 9, 19);
  test('hundredths remain exact, cap at 100 and undo every credit', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final r = GoalsRepository(db, now: () => now);
    await r.saveGoal(title: 'A');
    final goal = (await r.load()).goals.single;
    await r.saveMilestone(goalId: goal.id, title: 'Schritt', progress: 98.9);
    final milestone = (await r.load()).milestones.single;
    await r.todos.save(
      title: 'Klein',
      frequency: TodoFrequency.weekly,
      target: 20,
      milestoneId: milestone.id,
      progressIncrement: 0.1,
    );
    var s = await r.load();
    final entry = s.todoEntries.single;
    for (var i = 0; i < 15; i++) {
      s = await r.changeTodoCount(s, entry, 1);
    }
    expect(s.milestones.single.progress, 100);
    expect(s.todoCredits.where((c) => c.amount > 0), hasLength(11));
    for (var i = 0; i < 15; i++) {
      s = await r.changeTodoCount(s, entry, -1);
    }
    expect(s.milestones.single.progress, 98.9);
    expect(s.todoCredits, isEmpty);
    expect(BackupCodec.encode(s), await r.exportBackup());
    expect(() => progressUnits(0.001), throwsArgumentError);
  });

  test('weekly target credits only final repetition and remains reversible across mode changes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final r = GoalsRepository(db, now: () => now);
    await r.saveGoal(title: 'A');
    final goal = (await r.load()).goals.single;
    await r.saveMilestone(goalId: goal.id, title: 'Schritt', progress: 10);
    final milestone = (await r.load()).milestones.single;
    await r.todos.save(
      title: 'Woche',
      frequency: TodoFrequency.weekly,
      target: 3,
      milestoneId: milestone.id,
      progressIncrement: 2.5,
      progressMode: TodoProgressMode.onTarget,
    );
    final entry = (await r.load()).todoEntries.single;
    for (var i = 0; i < 2; i++) {
      await r.todos.changeCount(entry, 1);
    }
    expect((await r.load()).milestones.single.progress, 10);
    await r.todos.changeCount(entry, 1);
    expect((await r.load()).milestones.single.progress, 12.5);
    final backup = await r.exportBackup();
    await r.deleteAllContents();
    await r.importBackup(backup);
    expect(await r.exportBackup(), backup);
    await r.todos.save(
      id: entry.templateId,
      title: entry.title,
      frequency: entry.frequency,
      target: 3,
      milestoneId: milestone.id,
      progressIncrement: 0.25,
    );
    await r.todos.changeCount(entry, -1);
    expect((await r.load()).milestones.single.progress, 10);
    await r.todos.changeCount(entry, 1);
    expect((await r.load()).milestones.single.progress, 10.25);
    final invalid = jsonDecode(backup) as Map<String, dynamic>;
    invalid['todoTemplates'][0]['progressMode'] = 'unknown';
    expect(
      () => BackupCodec.decode(jsonEncode(invalid)),
      throwsA(isA<RuleViolation>()),
    );
  });

  test('schema 8 migrates integer values and credits without data loss and survives reopen', () async {
    final dir = await Directory.systemTemp.createTemp('guide_fractions_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/store.sqlite');
    final legacy = sqlite.sqlite3.open(file.path);
    legacy.execute(await File('test/fixtures/schema_v1.sql').readAsString());
    legacy.execute(
      await File('test/fixtures/schema_v8_extensions.sql').readAsString(),
    );
    legacy.execute(
      "INSERT INTO goals(id,title,started_on,cover_image) VALUES(1,'Alt','2026-09-01',X'010203')",
    );
    legacy.execute(
      "INSERT INTO milestones(id,goal_id,title,progress,status) VALUES(1,1,'Alt',100,'achieved')",
    );
    legacy.execute(
      "INSERT INTO todo_templates(id,title,frequency,target,active,milestone_id,progress_increment) VALUES(1,'Alt','weekly',3,1,1,5)",
    );
    legacy.execute(
      "INSERT INTO todo_entries VALUES(1,'2026-09-14','Alt','weekly',3,1,1,5)",
    );
    legacy.execute(
      "INSERT INTO todo_progress_credits VALUES(1,'2026-09-14',1,1,3,'offTrack')",
    );
    legacy.execute(
      "UPDATE sqlite_sequence SET seq=50 WHERE name IN ('milestones','todo_templates')",
    );
    legacy.close();
    var db = AppDatabase(NativeDatabase(file));
    var r = GoalsRepository(db, now: () => now);
    var s = await r.load();
    expect(s.goals.single.coverImage, [1, 2, 3]);
    expect(s.milestones.single.progress, 100);
    expect(s.todoTemplates.single.progressIncrement, 5);
    expect(s.todoTemplates.single.progressMode, TodoProgressMode.perCompletion);
    expect(s.todoCredits.single.amount, 3);
    await r.todos.changeCount(s.todoEntries.single, -1);
    expect((await r.load()).milestones.single.progress, 97);
    await r.todos.save(
      id: 1,
      title: 'Alt',
      frequency: TodoFrequency.weekly,
      target: 3,
      milestoneId: 1,
      progressIncrement: 0.25,
      progressMode: TodoProgressMode.onTarget,
    );
    await r.saveMilestone(goalId: 1, title: 'Neu');
    expect((await r.load()).milestones.last.id, greaterThan(50));
    final before = await r.exportBackup();
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    r = GoalsRepository(db, now: () => now);
    expect(await r.exportBackup(), before);
    expect((await db.customSelect('PRAGMA foreign_key_check').get()), isEmpty);
    await db.close();
  });
}
