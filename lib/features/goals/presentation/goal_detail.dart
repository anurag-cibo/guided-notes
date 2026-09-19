import 'package:flutter/material.dart';

import '../domain/progress_amount.dart';

import '../application/goals_controller.dart';
import 'common.dart';
import 'goal_editor.dart';
import 'goal_header.dart';
import 'goal_theme.dart';
import 'milestone_editor.dart';

class GoalDetail extends StatelessWidget {
  const GoalDetail({super.key, required this.controller, required this.goalId});
  final GoalsController controller;
  final int goalId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final goal = controller.snapshot.goal(goalId);
      if (goal == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Ziel nicht mehr vorhanden.')),
        );
      }
      final milestones = controller.snapshot.forGoal(goalId);
      return GoalTheme(
        color: goal.color,
        colors: controller.snapshot.theme(goal.customThemeId)?.colors,
        child: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Zieldetails'),
              actions: [
                if (!goal.archived)
                  IconButton(
                    tooltip: 'Ziel bearbeiten',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            GoalEditor(controller: controller, goal: goal),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: goal.archived
                ? null
                : BottomPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.saving
                                ? null
                                : () async {
                                    if (await runMutation(
                                          context,
                                          controller,
                                          (r) => r.setArchived(goalId, true),
                                        ) &&
                                        context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: const Text(
                              'Ziel archivieren',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MergeSemantics(
                            child: Row(
                              children: [
                                const Expanded(child: Text('Ziel erreicht')),
                                Switch(
                                  key: const ValueKey('goal-achieved'),
                                  value: goal.achieved,
                                  onChanged: controller.saving
                                      ? null
                                      : (value) => runMutation(
                                          context,
                                          controller,
                                          (r) => r.setAchieved(goalId, value),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            body: ListView(
              padding: pagePadding,
              children: [
                GoalHeader(
                  now: controller.repository.now(),
                  goal: goal,
                  progress: controller.snapshot.progressFor(goalId),
                ),
                gap,
                Text(
                  'Warum ist dir dieses Ziel wichtig?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      goal.motivation.isEmpty
                          ? 'Was macht dieses Ziel für dich wichtig?'
                          : goal.motivation,
                    ),
                  ),
                ),
                gap,
                SectionHeading(
                  title: 'Zwischenziele',
                  addLabel: goal.archived ? null : 'Zwischenziel hinzufügen',
                  onAdd: controller.saving
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => MilestoneEditor(
                              controller: controller,
                              goal: goal,
                            ),
                          ),
                        ),
                ),
                if (milestones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Ein kleiner nächster Schritt ist ein guter Anfang.',
                    ),
                  ),
                for (final milestone in milestones)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(milestone.title),
                      subtitle: Text(
                        '${milestone.status.label} · ${formatProgress(milestone.progress)} %',
                      ),
                      trailing: goal.archived
                          ? null
                          : const Icon(Icons.chevron_right),
                      onTap: goal.archived
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => MilestoneEditor(
                                  controller: controller,
                                  goal: goal,
                                  milestone: milestone,
                                ),
                              ),
                            ),
                    ),
                  ),
                if (goal.archived) ...[
                  gap,
                  const Text('Archiviert · Zwischenziele bleiben erhalten.'),
                  gap,
                  FilledButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            if (await runMutation(
                                  context,
                                  controller,
                                  (r) => r.setArchived(goalId, false),
                                ) &&
                                context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: const Text('Wiederherstellen'),
                  ),
                  gap,
                  TextButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            if (!await confirmDeletion(
                              context,
                              '„${goal.title}“ und alle ${milestones.length} Zwischenziele werden unwiderruflich gelöscht.',
                            )) {
                              return;
                            }
                            if (!context.mounted) return;
                            if (await runMutation(
                                  context,
                                  controller,
                                  (r) => r.deleteGoal(goalId),
                                ) &&
                                context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: const Text('Ziel endgültig löschen'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
