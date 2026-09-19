import 'package:flutter/material.dart';

import '../../goals/domain/metric_scale.dart';

import '../../goals/application/goals_controller.dart';
import 'todo_row.dart';
import '../../goals/presentation/common.dart';
import '../domain/todo_models.dart';
import 'todo_editor.dart';

class TodoGroup extends StatelessWidget {
  const TodoGroup({
    super.key,
    required this.controller,
    required this.frequency,
    this.milestoneId,
    this.beforeAction,
    this.previewScale,
  });
  final GoalsController controller;
  final TodoFrequency frequency;
  final int? milestoneId;
  final Future<bool> Function()? beforeAction;
  final MetricScale? previewScale;

  @override
  Widget build(BuildContext context) {
    final now = controller.repository.now();
    final entries = controller.snapshot.todoEntries
        .where(
          (entry) =>
              entry.frequency == frequency &&
              entry.isCurrent(now) &&
              controller.snapshot.todoTemplate(entry.templateId)?.active ==
                  true &&
              (milestoneId == null || entry.milestoneId == milestoneId),
        )
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TodoPeriodHeading(
              frequency: frequency,
              now: now,
              title: milestoneId == null
                  ? null
                  : (frequency == TodoFrequency.daily
                        ? 'Täglich'
                        : 'Wöchentlich'),
              onAdd: controller.saving
                  ? null
                  : () async {
                      if (beforeAction != null && !await beforeAction!()) {
                        return;
                      }
                      if (!context.mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => TodoEditor(
                            controller: controller,
                            frequency: frequency,
                            initialMilestoneId: milestoneId,
                          ),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  milestoneId != null
                      ? 'Noch keine verknüpften Aufgaben.'
                      : (frequency == TodoFrequency.daily
                            ? 'Was möchtest du jeden Tag tun?'
                            : 'Was möchtest du mehrmals pro Woche tun?'),
                ),
              ),
            for (final entry in entries)
              TodoRow(
                key: ValueKey('${entry.templateId}:${entry.period}'),
                controller: controller,
                entry: entry,
                beforeAction: beforeAction,
                previewScale: previewScale,
              ),
          ],
        ),
      ),
    );
  }
}

class TodoPeriodHeading extends StatelessWidget {
  const TodoPeriodHeading({
    super.key,
    required this.frequency,
    required this.now,
    this.onAdd,
    this.title,
  });

  final TodoFrequency frequency;
  final DateTime now;
  final VoidCallback? onAdd;
  final String? title;

  String get _compactDate {
    final start = DateTime.parse(periodStart(frequency, now));
    String date(DateTime value) => '${value.day}.${value.month}';
    if (frequency == TodoFrequency.daily) return date(start);
    final end = DateTime(start.year, start.month, start.day + 6);
    return '${date(start)}-${date(end)}';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title ??
                  (frequency == TodoFrequency.daily ? 'Heute' : 'Diese Woche'),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18),
            ),
            Tooltip(
              message: todoPeriodLabel(context, frequency, now),
              child: Text(
                _compactDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      AddCircleButton(
        label: frequency == TodoFrequency.daily
            ? 'Tagesaufgabe hinzufügen'
            : 'Wochenaufgabe hinzufügen',
        onPressed: onAdd,
      ),
    ],
  );
}

String todoPeriodLabel(
  BuildContext context,
  TodoFrequency frequency,
  DateTime now,
) {
  final start = DateTime.parse(periodStart(frequency, now));
  final format = MaterialLocalizations.of(context).formatMediumDate;
  return frequency == TodoFrequency.daily
      ? format(start)
      : '${format(start)} – ${format(DateTime(start.year, start.month, start.day + 6))}';
}
