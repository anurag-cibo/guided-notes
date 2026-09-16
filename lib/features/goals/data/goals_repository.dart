import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../domain/models.dart';
import 'backup_codec.dart';
import '../../todos/data/todos_repository.dart';

class GoalsRepository {
  GoalsRepository(this.database, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final AppDatabase database;
  final DateTime Function() now;
  late final TodosRepository todos = TodosRepository(database, now);

  Future<String> exportBackup() async => BackupCodec.encode(await load());

  /// Import only into an empty store; validation and writes are all-or-nothing.
  Future<void> importBackup(String source) async {
    final snapshot = BackupCodec.decode(source);
    await database.transaction(() async {
      final current = await load();
      if (!current.isEmpty) {
        throw const RuleViolation(
          'Wiederherstellen ist nur in einer leeren App möglich. Vorhandene Ziele, Todos und Archive bleiben unverändert.',
        );
      }
      for (final g in snapshot.goals) {
        await database.customStatement(
          'INSERT INTO goals(id,title,emoji,motivation,due_date,achieved,archived) VALUES (?,?,?,?,?,?,?)',
          [
            g.id,
            g.title,
            g.emoji,
            g.motivation,
            BackupCodec.date(g.dueDate),
            g.achieved ? 1 : 0,
            g.archived ? 1 : 0,
          ],
        );
      }
      for (final m in snapshot.milestones) {
        await database.customStatement(
          'INSERT INTO milestones(id,goal_id,title,progress,status,due_date) VALUES (?,?,?,?,?,?)',
          [
            m.id,
            m.goalId,
            m.title,
            m.progress,
            m.status.name,
            BackupCodec.date(m.dueDate),
          ],
        );
      }
      for (final t in snapshot.todoTemplates) {
        await database.customStatement(
          'INSERT INTO todo_templates(id,title,frequency,target,active) VALUES(?,?,?,?,?)',
          [t.id, t.title, t.frequency.name, t.target, t.active ? 1 : 0],
        );
      }
      for (final e in snapshot.todoEntries) {
        await database.customStatement(
          'INSERT INTO todo_entries(template_id,period,title,frequency,target,completed) VALUES(?,?,?,?,?,?)',
          [
            e.templateId,
            e.period,
            e.title,
            e.frequency.name,
            e.target,
            e.completed,
          ],
        );
      }
    });
  }

  Future<GoalSnapshot> load() => database.transaction(() async {
    await todos.ensureCurrentPeriods();
    final goals = await database
        .customSelect('SELECT * FROM goals ORDER BY id')
        .get();
    final milestones = await database
        .customSelect('SELECT * FROM milestones ORDER BY goal_id, id')
        .get();
    return GoalSnapshot(
      goals.map(_readGoal),
      milestones.map(
        (r) => Milestone(
          id: r.read<int>('id'),
          goalId: r.read<int>('goal_id'),
          title: r.read<String>('title'),
          progress: r.read<int>('progress'),
          status: MilestoneStatus.values.byName(r.read<String>('status')),
          dueDate: _date(r.readNullable<String>('due_date')),
        ),
      ),
      todoTemplates: await todos.templates(),
      todoEntries: await todos.entries(),
    );
  });

  Future<void> saveGoal({
    int? id,
    required String title,
    String emoji = '◎',
    String motivation = '',
    DateTime? dueDate,
  }) => database.transaction(() async {
    final name = requiredTitle(title);
    final symbol = emoji.trim().isEmpty ? '◎' : emoji.trim();
    if (id == null) {
      await _checkCapacity();
      await database.customStatement(
        'INSERT INTO goals(title, emoji, motivation, due_date) VALUES (?, ?, ?, ?)',
        [name, symbol, motivation.trim(), _encodeDate(dueDate)],
      );
    } else {
      await _requireGoal(id);
      await database.customStatement(
        'UPDATE goals SET title = ?, emoji = ?, motivation = ?, due_date = ? WHERE id = ?',
        [name, symbol, motivation.trim(), _encodeDate(dueDate), id],
      );
    }
  });

  Future<void> saveMilestone({
    int? id,
    required int goalId,
    required String title,
    int progress = 0,
    MilestoneStatus status = MilestoneStatus.notStarted,
    DateTime? dueDate,
  }) => database.transaction(() async {
    await _requireGoal(goalId, active: true);
    final name = requiredTitle(title);
    final normalized = normalizeProgress(progress, status);
    final values = [
      name,
      normalized.progress,
      normalized.status.name,
      _encodeDate(dueDate),
    ];
    if (id == null) {
      await database.customStatement(
        'INSERT INTO milestones(title, progress, status, due_date, goal_id) VALUES (?, ?, ?, ?, ?)',
        [...values, goalId],
      );
    } else {
      final existing = await database
          .customSelect(
            'SELECT id FROM milestones WHERE id = ? AND goal_id = ?',
            variables: [Variable(id), Variable(goalId)],
          )
          .getSingleOrNull();
      if (existing == null) {
        throw const RuleViolation('Dieses Zwischenziel existiert nicht mehr.');
      }
      await database.customStatement(
        'UPDATE milestones SET title = ?, progress = ?, status = ?, due_date = ? WHERE id = ? AND goal_id = ?',
        [...values, id, goalId],
      );
    }
  });

  Future<void> setArchived(int id, bool archived) =>
      database.transaction(() async {
        final goal = await _requireGoal(id);
        if (!archived && goal.archived) await _checkCapacity();
        await database.customStatement(
          'UPDATE goals SET archived = ? WHERE id = ?',
          [archived ? 1 : 0, id],
        );
      });

  Future<void> setAchieved(int id, bool achieved) =>
      database.transaction(() async {
        await _requireGoal(id, active: true);
        await database.customStatement(
          'UPDATE goals SET achieved = ? WHERE id = ?',
          [achieved ? 1 : 0, id],
        );
      });

  Future<void> deleteGoal(int id) => database.transaction(() async {
    final goal = await _requireGoal(id);
    if (!goal.archived) {
      throw const RuleViolation('Bitte das Ziel zuerst archivieren.');
    }
    await database.customStatement('DELETE FROM goals WHERE id = ?', [id]);
  });

  Future<void> deleteMilestone(int id, int goalId) =>
      database.transaction(() async {
        await _requireGoal(goalId, active: true);
        await database.customStatement(
          'DELETE FROM milestones WHERE id = ? AND goal_id = ?',
          [id, goalId],
        );
      });

  Future<Goal> _requireGoal(int id, {bool active = false}) async {
    final row = await database
        .customSelect(
          'SELECT * FROM goals WHERE id = ?',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw const RuleViolation('Dieses Ziel existiert nicht mehr.');
    }
    final goal = _readGoal(row);
    if (active && goal.archived) {
      throw const RuleViolation('Bitte das Ziel zuerst wiederherstellen.');
    }
    return goal;
  }

  Future<void> _checkCapacity() async {
    final row = await database
        .customSelect('SELECT count(*) AS total FROM goals WHERE archived = 0')
        .getSingle();
    if (row.read<int>('total') >= 5) {
      throw const RuleViolation(
        'Du hast bereits fünf aktive Ziele. Archiviere zuerst eines.',
      );
    }
  }

  static DateTime? _date(String? date) =>
      date == null ? null : DateTime.parse(date);
  static Goal _readGoal(QueryRow row) => Goal(
    id: row.read<int>('id'),
    title: row.read<String>('title'),
    emoji: row.read<String>('emoji'),
    motivation: row.read<String>('motivation'),
    dueDate: _date(row.readNullable<String>('due_date')),
    achieved: row.read<int>('achieved') == 1,
    archived: row.read<int>('archived') == 1,
  );
  static String? _encodeDate(DateTime? date) => date == null
      ? null
      : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
