import 'package:flutter/material.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/domain/progress_amount.dart';
import '../../goals/presentation/common.dart';
import '../domain/todo_models.dart';
import 'todo_editor.dart';

class TodoRow extends StatelessWidget {
  const TodoRow({
    super.key,
    required this.controller,
    required this.entry,
    this.beforeAction,
  });
  final GoalsController controller;
  final TodoEntry entry;
  final Future<bool> Function()? beforeAction;

  Future<bool> _changeCount(BuildContext context, int delta) async {
    if (beforeAction != null && !await beforeAction!()) return false;
    if (!context.mounted) return false;
    return showMutationResult(
      context,
      controller.changeTodoCount(entry, delta),
    );
  }

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
                              '${formatProgress(entry.progressIncrement)} Prozentpunkte ${entry.progressMode == TodoProgressMode.onTarget ? 'bei vollständiger Wochenaufgabe' : 'pro Erledigung'}',
                          excludeSemantics: true,
                          child: Text(
                            '+${formatProgress(entry.progressIncrement)} %',
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
                                frequency: template.frequency,
                                template: template,
                              ),
                            ),
                          );
                        },
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
          if (template.active &&
              (template.title != entry.title ||
                  template.target != entry.target))
            const Text('Änderung gilt ab dem nächsten Zeitraum.'),
        ],
      ),
    );
  }
}
