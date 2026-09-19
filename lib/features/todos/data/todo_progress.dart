import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../goals/domain/models.dart';
import '../domain/todo_models.dart';

/// Called only inside the same transaction as the todo count change.
class TodoProgress {
  TodoProgress(this.database);
  final AppDatabase database;

  Future<QueryRow?> _milestone(int? id) => database
      .customSelect(
        'SELECT m.*, g.archived FROM milestones m JOIN goals g ON g.id=m.goal_id WHERE m.id=?',
        variables: [Variable(id)],
      )
      .getSingleOrNull();

  Future<void> complete(TodoEntry entry, int ordinal) async {
    final row = await _milestone(entry.milestoneId);
    var amount = 0;
    var valueAmount = 0;
    var previous = MilestoneStatus.notStarted;
    if (row != null) {
      previous = MilestoneStatus.values.byName(row.read<String>('status'));
      final before = row.read<int>('current_value');
      final scale = _scale(row);
      if (row.read<int>('archived') == 0 &&
          (entry.progressMode == TodoProgressMode.perCompletion ||
              ordinal == entry.target)) {
        final after = scale.clampUnits(
          before + metricUnits(entry.progressIncrement) * scale.direction,
        );
        valueAmount = after - before;
        amount =
            (progressUnits(scale.percent(after / 100)) -
                    row.read<int>('progress'))
                .clamp(0, 10000);
        if (valueAmount != 0) {
          await _update(entry.milestoneId!, after, previous, scale);
        }
      }
    }
    await database.customStatement(
      'INSERT INTO todo_progress_credits(template_id,period,ordinal,milestone_id,amount,previous_status,value_amount) VALUES(?,?,?,?,?,?,?)',
      [
        entry.templateId,
        entry.period,
        ordinal,
        entry.milestoneId,
        amount,
        previous.name,
        valueAmount,
      ],
    );
  }

  Future<void> undo(TodoEntry entry, int ordinal) async {
    final credit = await database
        .customSelect(
          'SELECT * FROM todo_progress_credits WHERE template_id=? AND period=? AND ordinal=?',
          variables: [
            Variable(entry.templateId),
            Variable(entry.period),
            Variable(ordinal),
          ],
        )
        .getSingleOrNull();
    if (credit == null) return; // Existing completions from before linking.
    final id = credit.readNullable<int>('milestone_id');
    final row = await _milestone(id);
    final amount = credit.read<int>('value_amount');
    if (row != null && amount != 0) {
      final scale = _scale(row);
      final current = scale.clampUnits(row.read<int>('current_value') - amount);
      final progress = scale.percent(current / 100);
      var status = MilestoneStatus.values.byName(row.read<String>('status'));
      if (status == MilestoneStatus.achieved && progress < 100) {
        status = MilestoneStatus.values.byName(
          credit.read<String>('previous_status'),
        );
        if (status == MilestoneStatus.achieved) {
          status = MilestoneStatus.onTrack;
        }
      }
      await _update(id!, current, status, scale);
    }
    await database.customStatement(
      'DELETE FROM todo_progress_credits WHERE template_id=? AND period=? AND ordinal=?',
      [entry.templateId, entry.period, ordinal],
    );
  }

  static MetricScale _scale(QueryRow row) => MetricScale(
    start: row.read<int>('start_value') / 100,
    target: row.read<int>('target_value') / 100,
    unit: row.read<String>('unit'),
  );

  Future<void> _update(
    int id,
    int current,
    MilestoneStatus status,
    MetricScale scale,
  ) async {
    final normalized = normalizeProgress(scale.percent(current / 100), status);
    await database.customStatement(
      'UPDATE milestones SET progress=?,status=?,current_value=? WHERE id=?',
      [progressUnits(normalized.progress), normalized.status.name, current, id],
    );
  }

  Future<List<TodoProgressCredit>> load({TodoEntry? entry}) async => [
    for (final r
        in await database
            .customSelect(
              'SELECT * FROM todo_progress_credits '
              '${entry == null ? '' : 'WHERE template_id=? AND period=? '}'
              'ORDER BY template_id,period,ordinal',
              variables: entry == null
                  ? []
                  : [Variable(entry.templateId), Variable(entry.period)],
            )
            .get())
      TodoProgressCredit(
        templateId: r.read<int>('template_id'),
        period: r.read<String>('period'),
        ordinal: r.read<int>('ordinal'),
        milestoneId: r.readNullable<int>('milestone_id'),
        amount: progressPercent(r.read<int>('amount')),
        previousStatus: r.read<String>('previous_status'),
        valueAmount: r.read<int>('value_amount') / 100,
      ),
  ];
}
