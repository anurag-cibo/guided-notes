import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/models.dart';

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
    final hasImage = goal.coverImage != null;
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
                if (hasImage)
                  Positioned.fill(
                    child: Image.memory(
                      goal.coverImage!,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) =>
                          ColoredBox(color: theme.colorScheme.primary),
                    ),
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
                  padding: const EdgeInsets.all(20),
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
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: foreground),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null || goal.achieved || goal.dueDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (progress != null) ...[
                      Text(
                        '${formatProgress(progress)} %',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(8),
                        semanticsLabel: 'Zwischenzielfortschritt',
                        // Flutter's progressBar role requires a parseable number.
                        semanticsValue:
                            '${formatProgress(progress).replaceAll(',', '.')} %',
                      ),
                    ],
                    if (goal.achieved || goal.dueDate != null) ...[
                      if (progress != null) const SizedBox(height: 8),
                      Text(
                        deadlineLabel(goal.dueDate, achieved: goal.achieved),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
