import 'package:flutter/material.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/presentation/common.dart';
import '../domain/todo_models.dart';
import 'todo_editor.dart';
export 'todo_editor.dart';

class TodosView extends StatelessWidget {
  const TodosView({super.key, required this.controller});
  final GoalsController controller;

  @override
  Widget build(BuildContext context) {
    final now = controller.repository.now();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: pagePadding,
          sliver: SliverList.list(
            children: [
              Text(
                'Kleine Schritte, jeden Tag.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hake ab, was du geschafft hast. Morgen beginnt ein neuer Tag.',
              ),
              const SizedBox(height: 28),
              for (final frequency in TodoFrequency.values)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PeriodHeading(
                          frequency: frequency,
                          now: now,
                          onAdd: controller.saving
                              ? null
                              : () => _openEditor(context, frequency),
                        ),
                        const SizedBox(height: 8),
                        if (!controller.snapshot.todoEntries.any(
                          (e) => e.frequency == frequency && e.isCurrent(now),
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              frequency == TodoFrequency.daily
                                  ? 'Was möchtest du jeden Tag tun?'
                                  : 'Was möchtest du mehrmals pro Woche tun?',
                            ),
                          ),
                        for (final entry
                            in controller.snapshot.todoEntries.where(
                              (e) =>
                                  e.frequency == frequency && e.isCurrent(now),
                            ))
                          _TodoCard(controller: controller, entry: entry),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: BottomPanel(
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.history),
                  title: const Text('Vergangene Zeiträume'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TodoHistoryScreen(controller: controller),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context, TodoFrequency frequency) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              TodoEditor(controller: controller, frequency: frequency),
        ),
      );
}

class _PeriodHeading extends StatelessWidget {
  const _PeriodHeading({
    required this.frequency,
    required this.now,
    this.onAdd,
  });

  final TodoFrequency frequency;
  final DateTime now;
  final VoidCallback? onAdd;

  String get _compactDate {
    final start = DateTime.parse(periodStart(frequency, now));
    String date(DateTime value) => '${value.day}.${value.month}.';
    if (frequency == TodoFrequency.daily) return date(start);
    final end = DateTime(start.year, start.month, start.day + 6);
    return start.month == end.month
        ? '${start.day}.–${date(end)}'
        : '${date(start)}–${date(end)}';
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
              frequency == TodoFrequency.daily ? 'Heute' : 'Diese Woche',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18),
            ),
            Tooltip(
              message: _periodLabel(context, frequency, now),
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

String _periodLabel(
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

class _TodoCard extends StatelessWidget {
  const _TodoCard({required this.controller, required this.entry});
  final GoalsController controller;
  final TodoEntry entry;

  Future<bool> _changeCount(BuildContext context, int delta) =>
      showMutationResult(context, controller.changeTodoCount(entry, delta));

  @override
  Widget build(BuildContext context) {
    final template = controller.snapshot.todoTemplate(entry.templateId)!;
    final done = entry.completed == entry.target;
    final milestone = entry.milestoneId == null
        ? null
        : controller.snapshot.milestone(entry.milestoneId!);
    final goal = milestone == null
        ? null
        : controller.snapshot.goal(milestone.goalId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.frequency == TodoFrequency.daily)
                Checkbox(
                  value: done,
                  onChanged: controller.saving
                      ? null
                      : (value) =>
                            _changeCount(context, value == true ? 1 : -1),
                  semanticLabel: entry.title,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                      if (goal != null &&
                          !goal.archived &&
                          entry.progressIncrement > 0)
                        Semantics(
                          label:
                              '${entry.progressIncrement} Prozentpunkte pro Erledigung',
                          excludeSemantics: true,
                          child: Text(
                            '+${entry.progressIncrement} %',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xff80d6ad)
                                      : const Color(0xff187347),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (template.active)
                IconButton(
                  tooltip: '${entry.title} bearbeiten',
                  icon: const Icon(Icons.more_horiz),
                  onPressed: controller.saving
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TodoEditor(
                              controller: controller,
                              frequency: template.frequency,
                              template: template,
                            ),
                          ),
                        ),
                ),
            ],
          ),
          if (entry.frequency == TodoFrequency.weekly)
            Row(
              children: [
                IconButton(
                  tooltip: '${entry.title}: einmal rückgängig',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: controller.saving || entry.completed == 0
                      ? null
                      : () => _changeCount(context, -1),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Semantics(
                      liveRegion: true,
                      label: entry.title,
                      value: '${entry.completed} von ${entry.target}',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entry.completed} von ${entry.target}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.completed / entry.target,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '${entry.title}: einmal erledigt',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: controller.saving || done
                      ? null
                      : () => _changeCount(context, 1),
                ),
              ],
            ),
          if (!template.active) const Text('Endet nach diesem Zeitraum.'),
          if (template.active &&
              (template.title != entry.title ||
                  template.target != entry.target))
            const Text('Änderung gilt ab dem nächsten Zeitraum.'),
        ],
      ),
    );
  }
}

class TodoHistoryScreen extends StatelessWidget {
  const TodoHistoryScreen({super.key, required this.controller});
  final GoalsController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final entries = controller.snapshot.todoEntries
          .where((e) => !e.isCurrent(controller.repository.now()))
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Vergangene Zeiträume')),
        body: entries.isEmpty
            ? ListView(
                padding: pagePadding,
                children: const [
                  EmptyMessage(
                    'Noch keine vergangenen Zeiträume',
                    'Hier bleiben deine Tages- und Wochenstände erhalten. Zeiträume ohne App-Nutzung werden nicht nachträglich angelegt.',
                  ),
                ],
              )
            : ListView.builder(
                padding: pagePadding,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final e = entries[index];
                  return Card(
                    child: ListTile(
                      title: Text(e.title),
                      subtitle: Text(
                        '${e.frequency.label} · ${_periodLabel(context, e.frequency, DateTime.parse(e.period))}\n${e.completed} von ${e.target} erledigt',
                      ),
                    ),
                  );
                },
              ),
      );
    },
  );
}
