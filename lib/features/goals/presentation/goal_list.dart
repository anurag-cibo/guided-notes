import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import 'common.dart';
import 'drag_order.dart';
import 'goal_detail.dart';
import 'goal_editor.dart';
import 'goal_theme.dart';
import 'goal_card.dart';

class GoalList extends StatelessWidget {
  const GoalList({
    super.key,
    required this.controller,
    this.archived = false,
    this.onOpenMilestones,
  });
  final GoalsController controller;
  final bool archived;
  final ValueChanged<int>? onOpenMilestones;
  @override
  Widget build(BuildContext context) {
    final goals = controller.snapshot.goals
        .where((g) => g.archived == archived)
        .toList();
    final children = <Widget>[
      if (!archived) ...[
        const Text('Kleine Schritte. Deine Richtung.'),
        const SizedBox(height: 28),
        SectionHeading(
          title: 'Deine Ziele · ${goals.length} von 5',
          addLabel: goals.length < 5 ? 'Ziel hinzufügen' : null,
          onAdd: controller.saving
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => GoalEditor(controller: controller),
                  ),
                ),
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
        DragOrder(
          key: ValueKey('drag-goal-${goal.id}'),
          enabled: !archived,
          data: OrderDrag(OrderKind.goal, goal.id),
          accepts: (data) => data.kind == OrderKind.goal,
          onDrop: (data, after) => runMutation(
            context,
            controller,
            (r) => r.moveGoal(data.id, goal.id, after: after),
          ),
          child: GoalTheme(
            color: goal.color,
            colors: controller.snapshot.theme(goal.customThemeId)?.colors,
            child: Builder(
              builder: (context) => GoalCard(
                controller: controller,
                goal: goal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => GoalDetail(
                      controller: controller,
                      goalId: goal.id,
                      onOpenMilestones: onOpenMilestones,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (!archived && goals.length == 5)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Fünf Ziele im Fokus. Archiviere eines, um Platz für ein neues zu schaffen.',
          ),
        ),
    ];
    if (archived) return ListView(padding: pagePadding, children: children);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: pagePadding,
          sliver: SliverList.list(children: children),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
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
              ),
            ),
          ),
        ),
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
