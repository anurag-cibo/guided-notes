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
        if (!archived) ...[
          Text(
            'Schön, dass du da bist.',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Kleine Schritte. Deine Richtung.'),
          const SizedBox(height: 28),
          Text(
            'Deine Ziele · ${goals.length} von 5',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          gap,
        ],
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
              borderRadius: BorderRadius.circular(20),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffedf3ee),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            goal.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                controller.snapshot.forGoal(goal.id).isEmpty
                                    ? 'Noch keine Zwischenziele'
                                    : '${controller.snapshot.forGoal(goal.id).where((m) => m.status == MilestoneStatus.achieved).length}/${controller.snapshot.forGoal(goal.id).length} Zwischenziele erreicht',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    if (controller.snapshot.progressFor(goal.id) != null) ...[
                      gap,
                      ProgressSummary(controller.snapshot.progressFor(goal.id)),
                    ],
                    if (goal.achieved || goal.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        deadlineLabel(goal.dueDate, achieved: goal.achieved),
                      ),
                    ],
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
        if (!archived && goals.length == 5)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Fünf Ziele im Fokus. Archiviere eines, um Platz für ein neues zu schaffen.',
            ),
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
