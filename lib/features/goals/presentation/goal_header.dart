import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/goal_time.dart';
import 'goal_cover.dart';

/// Cover, title row and deadline remain independent of the goal's content.
class GoalHeader extends StatelessWidget {
  const GoalHeader({
    super.key,
    required this.goal,
    required this.progress,
    this.now,
  });
  final Goal goal;
  final int? progress;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = GoalTime(goal, now ?? DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GoalCover(image: goal.coverImage, height: 112),
            Padding(
              padding: const EdgeInsets.only(top: 82, left: 8, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: Text(
                      goal.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        goal.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ...[
                    const SizedBox(width: 12),
                    Semantics(
                      label: 'Zeit bis zur Frist',
                      value: time.label.replaceAll('\n', ' '),
                      child: ExcludeSemantics(
                        child: Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: time.elapsed,
                                  strokeWidth: 5,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: FittedBox(
                                  child: Text(
                                    time.label,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (progress ?? 0) / 100,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
                semanticsLabel: 'Zwischenzielfortschritt',
                semanticsValue: '${progress ?? 0} %',
              ),
            ),
            const SizedBox(width: 12),
            Text('${progress ?? 0} %', style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Frist: ${goal.dueDate == null ? 'Ohne Frist' : MaterialLocalizations.of(context).formatMediumDate(goal.dueDate!)}',
        ),
        if (progress == null) ...[
          const SizedBox(height: 6),
          Text('Noch keine Zwischenziele', style: theme.textTheme.bodySmall),
        ],
        if (goal.achieved || goal.archived) ...[
          const SizedBox(height: 6),
          Text(
            [
              if (goal.achieved) 'Ziel erreicht',
              if (goal.archived) 'Archiviert',
            ].join(' · '),
          ),
        ],
      ],
    );
  }
}
