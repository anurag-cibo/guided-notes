import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/models.dart';
import 'common.dart';
import 'goal_editor.dart';
import 'milestone_editor.dart';
import 'milestones_screen.dart';

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
      return Scaffold(
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
        body: ListView(
          padding: pagePadding,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xffe8f1eb),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 44)),
                  gap,
                  Text(
                    goal.title,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  gap,
                  ProgressSummary(controller.snapshot.progressFor(goalId)),
                  if (goal.achieved || goal.archived) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (goal.achieved) 'Ziel erreicht',
                        if (goal.archived) 'Archiviert',
                      ].join(' · '),
                    ),
                  ],
                ],
              ),
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
            Text(
              'Frist: ${goal.dueDate == null ? 'Ohne Frist' : MaterialLocalizations.of(context).formatMediumDate(goal.dueDate!)}${goal.dueDate != null && !goal.achieved ? ' · ${deadlineLabel(goal.dueDate)}' : ''}',
            ),
            gap,
            Text(
              'Zwischenziele',
              style: Theme.of(context).textTheme.titleLarge,
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
                    '${milestone.status.label} · ${milestone.progress} %',
                  ),
                  trailing: goal.archived
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: goal.archived
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => MilestonesScreen(
                              controller: controller,
                              focusGoalId: goalId,
                              focusMilestoneId: milestone.id,
                            ),
                          ),
                        ),
                ),
              ),
            if (!goal.archived) ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        MilestoneEditor(controller: controller, goal: goal),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Zwischenziel hinzufügen'),
              ),
              gap,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ziel erreicht'),
                subtitle: const Text('Bleibt aktiv, bis du es archivierst.'),
                value: goal.achieved,
                onChanged: controller.saving
                    ? null
                    : (value) => runMutation(
                        context,
                        controller,
                        (r) => r.setAchieved(goalId, value),
                      ),
              ),
              gap,
              OutlinedButton.icon(
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
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Ziel archivieren'),
              ),
            ] else ...[
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
      );
    },
  );
}
