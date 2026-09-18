import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../goals/domain/models.dart';
import '../domain/todo_models.dart';

class TodosRepository {
  TodosRepository(this.database, this.now);
  final AppDatabase database;
  final DateTime Function() now;

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
      ),
  ];

  Future<void> ensureCurrentPeriods() async {
    final today = now();
    for (final t in await templates()) {
      if (!t.active) continue;
      await database.customStatement(
        '''INSERT OR IGNORE INTO todo_entries
        (template_id, period, title, frequency, target, completed)
        VALUES (?, ?, ?, ?, ?, 0)''',
        [
          t.id,
          periodStart(t.frequency, today),
          t.title,
          t.frequency.name,
          t.target,
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
      TodoEntry(
        templateId: r.read<int>('template_id'),
        period: r.read<String>('period'),
        title: r.read<String>('title'),
        frequency: TodoFrequency.values.byName(r.read<String>('frequency')),
        target: r.read<int>('target'),
        completed: r.read<int>('completed'),
      ),
  ];

  Future<void> save({
    int? id,
    required String title,
    required TodoFrequency frequency,
    required int target,
  }) => database.transaction(() async {
    final name = requiredTitle(title);
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
        'INSERT INTO todo_templates(title,frequency,target,active) VALUES(?,?,?,1)',
        [name, frequency.name, target],
      );
    } else {
      final t = await _requireTemplate(id);
      if (!t.active || t.frequency != frequency) {
        throw const RuleViolation(
          'Diese Aufgabe kann nicht mehr geändert werden.',
        );
      }
      await database.customStatement(
        'UPDATE todo_templates SET title=?,target=? WHERE id=?',
        [name, target, id],
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
      });
}
