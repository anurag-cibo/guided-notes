import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/models.dart';
import 'common.dart';
import 'goal_detail.dart';
import 'goal_editor.dart';

class GoalList extends StatelessWidget {
  const GoalList({super.key, required this.controller, this.archived = false});
  final GoalsController controller;
  final bool archived;
  @override
  Widget build(BuildContext context) {
    final goals = controller.snapshot.goals
        .where((g) => g.archived == archived)
        .toList();
    return ListView(
      padding: pagePadding,
      children: [
        if (goals.isEmpty)
          EmptyMessage(
            archived ? 'Keine archivierten Ziele' : 'Noch keine Ziele',
            archived
                ? 'Archivierte Ziele und ihre Zwischenziele bleiben hier erhalten.'
                : 'Was möchtest du erreichen? Beginne mit einem Ziel.',
          ),
        for (final goal in goals)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      GoalDetail(controller: controller, goalId: goal.id),
                ),
              ),
              child: Padding(
                padding: pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    gap,
                    ProgressSummary(controller.snapshot.progressFor(goal.id)),
                    const SizedBox(height: 8),
                    Text(deadlineLabel(goal.dueDate, achieved: goal.achieved)),
                  ],
                ),
              ),
            ),
          ),
        if (!archived && goals.length < 5)
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GoalEditor(controller: controller),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Ziel hinzufügen'),
          ),
        if (!archived) ...[
          gap,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Archiv'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ArchiveScreen(controller: controller),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, required this.controller});
  final GoalsController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Archiv')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (_, _) => GoalList(controller: controller, archived: true),
    ),
  );
}
