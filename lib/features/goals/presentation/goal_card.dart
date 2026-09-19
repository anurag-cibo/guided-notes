import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/goal_time.dart';
import '../domain/models.dart';
import 'goal_cover.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.controller,
    required this.goal,
    required this.onTap,
  });
  final GoalsController controller;
  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestones = controller.snapshot.forGoal(goal.id);
    final progress = controller.snapshot.progressFor(goal.id);
    final hasImage = goal.showCardCover && goal.coverImage != null;
    final foreground = hasImage ? Colors.white : theme.colorScheme.onSurface;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (goal.showCardCover)
                  Positioned.fill(
                    child: GoalCoverContent(image: goal.coverImage),
                  ),
                if (hasImage)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x99000000), Color(0xb3000000)],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    goal.showCardCover ? 16 : 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: foreground,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              milestones.isEmpty
                                  ? 'Noch keine Zwischenziele'
                                  : '${milestones.where((m) => m.status == MilestoneStatus.achieved).length}/${milestones.length} Zwischenziele erreicht',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: foreground,
                              ),
                            ),
                            if (goal.achieved || goal.dueDate != null) ...[
                              const SizedBox(height: 4),
                              _GoalCardTime(goal: goal, foreground: foreground),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: foreground),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  goal.showCardCover ? 12 : 4,
                  20,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(8),
                            semanticsLabel: 'Zwischenzielfortschritt',
                            // Flutter's progressBar role requires a parseable number.
                            semanticsValue:
                                '${formatProgress(progress).replaceAll(',', '.')} %',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${formatProgress(progress)} %',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small ring keeps the deadline within the existing card's text row.
class _GoalCardTime extends StatelessWidget {
  const _GoalCardTime({required this.goal, required this.foreground});

  final Goal goal;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(color: foreground);
    if (goal.achieved) return Text('Erreicht', style: style);
    final time = GoalTime(goal, DateTime.now());
    final days = time.remainingDays;
    final label = switch (days) {
      null => 'Ohne Frist',
      0 => 'Heute fällig',
      1 => '1 Tag',
      final int value when value > 1 => '$value Tage',
      -1 => '1 Tag überfällig',
      final int value => '${-value} Tage überfällig',
    };
    return Semantics(
      label: 'Zeit bis zur Frist',
      value: time.label.replaceAll('\n', ' '),
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                value: time.elapsed,
                strokeWidth: 2,
                strokeCap: StrokeCap.round,
                color: foreground,
                backgroundColor: foreground.withValues(alpha: 0.22),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}
