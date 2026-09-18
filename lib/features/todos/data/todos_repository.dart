import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../goals/domain/models.dart';
import '../domain/todo_models.dart';
import 'todo_progress.dart';

class TodosRepository {
  TodosRepository(this.database, this.now);
  final AppDatabase database;
  final DateTime Function() now;
  late final progress = TodoProgress(database);

  Future<List<TodoTemplate>> templates() async => [
    for (final r
        in await database
            .customSelect('SELECT * FROM todo_templates ORDER BY id')
            .get())
      TodoTemplate(
        id: r.read<int>('id'),
        title: r.read<String>('title'),
        frequency: TodoFrequency.values.byName(r.read<String>('frequency')),
        target: r.read<int>('target'),
        active: r.read<int>('active') == 1,
        milestoneId: r.readNullable<int>('milestone_id'),
        progressIncrement: r.read<int>('progress_increment'),
      ),
  ];

  Future<void> ensureCurrentPeriods() async {
    final today = now();
    for (final t in await templates()) {
      if (!t.active) continue;
      await database.customStatement(
        '''INSERT OR IGNORE INTO todo_entries
        (template_id, period, title, frequency, target, completed, milestone_id, progress_increment)
        VALUES (?, ?, ?, ?, ?, 0, ?, ?)''',
        [
          t.id,
          periodStart(t.frequency, today),
          t.title,
          t.frequency.name,
          t.target,
          t.milestoneId,
          t.progressIncrement,
        ],
      );
    }
  }

  Future<List<TodoEntry>> entries() async => [
    for (final r
        in await database
            .customSelect(
              'SELECT * FROM todo_entries ORDER BY period DESC, template_id',
            )
            .get())
      _readEntry(r),
  ];

  static TodoEntry _readEntry(QueryRow r) => TodoEntry(
    templateId: r.read<int>('template_id'),
    period: r.read<String>('period'),
    title: r.read<String>('title'),
    frequency: TodoFrequency.values.byName(r.read<String>('frequency')),
    target: r.read<int>('target'),
    completed: r.read<int>('completed'),
    milestoneId: r.readNullable<int>('milestone_id'),
    progressIncrement: r.read<int>('progress_increment'),
  );

  Future<void> save({
    int? id,
    required String title,
    required TodoFrequency frequency,
    required int target,
    int? milestoneId,
    int progressIncrement = 0,
  }) => database.transaction(() async {
    final name = requiredTitle(title);
    if (progressIncrement < 0 ||
        progressIncrement > 100 ||
        (milestoneId == null && progressIncrement != 0)) {
      throw const RuleViolation(
        'Bitte einen Fortschritt von 1 bis 100 Prozentpunkten und ein Zwischenziel wählen.',
      );
    }
    if (milestoneId != null) {
      final linked = await database
          .customSelect(
            'SELECT m.id, g.archived FROM milestones m JOIN goals g ON g.id=m.goal_id WHERE m.id=?',
            variables: [Variable(milestoneId)],
          )
          .getSingleOrNull();
      final existing = id == null ? null : await _requireTemplate(id);
      if (linked == null ||
          (linked.read<int>('archived') != 0 &&
              existing?.milestoneId != milestoneId)) {
        throw const RuleViolation(
          'Bitte ein Zwischenziel eines aktiven Ziels auswählen.',
        );
      }
    }
    if (target < 1 ||
        target > 999 ||
        (frequency == TodoFrequency.daily && target != 1)) {
      throw const RuleViolation(
        'Bitte eine Wochenanzahl zwischen 1 und 999 eingeben.',
      );
    }
    await ensureCurrentPeriods();
    if (id == null) {
      await database.customStatement(
        'INSERT INTO todo_templates(title,frequency,target,active,milestone_id,progress_increment) VALUES(?,?,?,1,?,?)',
        [name, frequency.name, target, milestoneId, progressIncrement],
      );
    } else {
      final t = await _requireTemplate(id);
      if (!t.active || t.frequency != frequency) {
        throw const RuleViolation(
          'Diese Aufgabe kann nicht mehr geändert werden.',
        );
      }
      await database.customStatement(
        'UPDATE todo_templates SET title=?,target=?,milestone_id=?,progress_increment=? WHERE id=?',
        [name, target, milestoneId, progressIncrement, id],
      );
      // Linking affects future completions immediately, never past credits.
      await database.customStatement(
        'UPDATE todo_entries SET milestone_id=?,progress_increment=? WHERE template_id=? AND period=?',
        [milestoneId, progressIncrement, id, periodStart(frequency, now())],
      );
    }
    await ensureCurrentPeriods();
  });

  Future<TodoTemplate> _requireTemplate(int id) async {
    for (final t in await templates()) {
      if (t.id == id) return t;
    }
    throw const RuleViolation('Diese Aufgabe existiert nicht mehr.');
  }

  Future<void> stop(int id) => database.transaction(() async {
    await _requireTemplate(id);
    await ensureCurrentPeriods();
    await database.customStatement(
      'UPDATE todo_templates SET active=0 WHERE id=?',
      [id],
    );
  });

  Future<void> changeCount(TodoEntry entry, int delta) =>
      database.transaction(() async {
        if (!entry.isCurrent(now())) {
          throw const RuleViolation(
            'Der Zeitraum ist vorbei. Bitte den aktuellen Stand verwenden.',
          );
        }
        if (delta != 1 && delta != -1) throw ArgumentError.value(delta);
        final row = await database
            .customSelect(
              'SELECT * FROM todo_entries WHERE template_id=? AND period=?',
              variables: [Variable(entry.templateId), Variable(entry.period)],
            )
            .getSingleOrNull();
        final current = row == null ? null : _readEntry(row);
        if (current == null || !current.isCurrent(now())) {
          throw const RuleViolation(
            'Der Stand wurde bereits geändert. Bitte erneut laden.',
          );
        }
        final changed = await database.customUpdate(
          '''UPDATE todo_entries SET completed=completed+?
      WHERE template_id=? AND period=? AND completed+? BETWEEN 0 AND target''',
          variables: [
            Variable(delta),
            Variable(entry.templateId),
            Variable(entry.period),
            Variable(delta),
          ],
        );
        if (changed != 1) {
          throw const RuleViolation(
            'Der Stand wurde bereits geändert. Bitte erneut laden.',
          );
        }
        if (delta > 0) {
          await progress.complete(current, current.completed + 1);
        } else {
          await progress.undo(current, current.completed);
        }
      });
}
