import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/models.dart';
import 'common.dart';
import 'milestone_editor.dart';

class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({
    super.key,
    required this.controller,
    this.focusGoalId,
    this.focusMilestoneId,
  });
  final GoalsController controller;
  final int? focusGoalId;
  final int? focusMilestoneId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Zwischenziele')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (_, _) => MilestonesView(
        controller: controller,
        focusGoalId: focusGoalId,
        focusMilestoneId: focusMilestoneId,
      ),
    ),
  );
}

/// A lazily built list split around its target gives exact jumps even for long lists
/// and variable row heights (large text), without an additional scrolling package.
class MilestonesView extends StatefulWidget {
  const MilestonesView({
    super.key,
    required this.controller,
    this.focusGoalId,
    this.focusMilestoneId,
  });
  final GoalsController controller;
  final int? focusGoalId;
  final int? focusMilestoneId;
  @override
  State<MilestonesView> createState() => _MilestonesViewState();
}

class _MilestonesViewState extends State<MilestonesView> {
  late int? _focusGoal = widget.focusGoalId;
  late int? _focusMilestone = widget.focusMilestoneId;
  int _jump = 0;
  final _center = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final snapshot = widget.controller.snapshot;
    final goals = snapshot.activeGoals;
    if (goals.isEmpty) {
      return ListView(
        padding: pagePadding,
        children: const [
          EmptyMessage(
            'Noch keine Zwischenziele',
            'Lege zuerst im Bereich Ziele ein Ziel an.',
          ),
        ],
      );
    }
    final rows = <({String id, Widget child})>[];
    for (final goal in goals) {
      rows.add((
        id: 'goal-${goal.id}',
        child: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            '${goal.emoji} ${goal.title}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ));
      final milestones = snapshot.forGoal(goal.id);
      if (milestones.isEmpty) {
        rows.add((
          id: 'empty-${goal.id}',
          child: const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Noch keine Zwischenziele'),
          ),
        ));
      }
      for (final milestone in milestones) {
        rows.add((
          id: 'milestone-${milestone.id}',
          child: Card(
            color: switch (milestone.status) {
              MilestoneStatus.achieved ||
              MilestoneStatus.onTrack => const Color(0xffeaf6ee),
              MilestoneStatus.offTrack => const Color(0xfffff1df),
              MilestoneStatus.onHold => const Color(0xfff0edf7),
              MilestoneStatus.notStarted => const Color(0xffedf2f7),
            },
            shape: milestone.id == _focusMilestone
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  )
                : null,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(milestone.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('${milestone.status.label} · ${milestone.progress} %'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: milestone.progress / 100,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  if (milestone.dueDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      deadlineLabel(
                        milestone.dueDate,
                        achieved: milestone.status == MilestoneStatus.achieved,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MilestoneEditor(
                    controller: widget.controller,
                    goal: goal,
                    milestone: milestone,
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      rows.add((
        id: 'add-${goal.id}',
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    MilestoneEditor(controller: widget.controller, goal: goal),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Zwischenziel hinzufügen'),
          ),
        ),
      ));
    }
    final target = _focusMilestone != null
        ? 'milestone-$_focusMilestone'
        : 'goal-$_focusGoal';
    final index = rows.indexWhere((r) => r.id == target);
    final split = index < 0 ? 0 : index;
    return Column(
      children: [
        if (goals.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DropdownButtonFormField<int>(
              key: ValueKey('selector-$_jump'),
              isExpanded: true,
              initialValue: goals.any((g) => g.id == _focusGoal)
                  ? _focusGoal
                  : null,
              decoration: const InputDecoration(labelText: 'Zu Ziel springen'),
              items: goals
                  .map(
                    (g) => DropdownMenuItem(
                      value: g.id,
                      child: Text(
                        '${g.emoji} ${g.title}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) => setState(() {
                _focusGoal = id;
                _focusMilestone = null;
                _jump++;
              }),
            ),
          ),
        Expanded(
          child: CustomScrollView(
            key: ValueKey('scroll-$_jump'),
            center: _center,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => rows[split - i - 1].child,
                    childCount: split,
                  ),
                ),
              ),
              SliverPadding(
                key: _center,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => rows[split + i].child,
                    childCount: rows.length - split,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
