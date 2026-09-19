import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'goal_theme.dart';

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
  bool _showSelector = true;
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
          child: GoalTheme(
            color: goal.color,
            colors: snapshot.theme(goal.customThemeId)?.colors,
            child: SectionHeading(
              title: '${goal.emoji} ${goal.title}',
              addLabel: 'Zwischenziel hinzufügen',
              onAdd: widget.controller.saving
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MilestoneEditor(
                          controller: widget.controller,
                          goal: goal,
                        ),
                      ),
                    ),
            ),
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
          child: GoalTheme(
            color: goal.color,
            colors: snapshot.theme(goal.customThemeId)?.colors,
            child: Builder(
              builder: (context) => Card(
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
                      Text(
                        '${milestone.status.label} · ${formatProgress(milestone.progress)} %',
                      ),
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
                            achieved:
                                milestone.status == MilestoneStatus.achieved,
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
            ),
          ),
        ));
      }
    }
    final target = _focusMilestone != null
        ? 'milestone-$_focusMilestone'
        : 'goal-$_focusGoal';
    final index = rows.indexWhere((r) => r.id == target);
    final split = index < 0 ? 0 : index;
    return Column(
      children: [
        if (goals.length > 1)
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: ClipRect(
              child: Align(
                heightFactor: _showSelector ? 1 : 0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 4, 32, 0),
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('selector-$_jump'),
                      isExpanded: true,
                      initialValue: goals.any((g) => g.id == _focusGoal)
                          ? _focusGoal
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Zu Ziel springen',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
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
                        _showSelector = true;
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.depth != 0 ||
                  notification.direction == ScrollDirection.idle) {
                return false;
              }
              final show = notification.direction == ScrollDirection.forward;
              if (show != _showSelector) setState(() => _showSelector = show);
              return false;
            },
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
        ),
      ],
    );
  }
}
