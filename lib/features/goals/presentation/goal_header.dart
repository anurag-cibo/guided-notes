import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'goal_cover.dart';

/// Cover, title row and deadline remain independent of the goal's content.
class GoalHeader extends StatelessWidget {
  const GoalHeader({super.key, required this.goal, required this.progress});
  final Goal goal;
  final int? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoalCover(image: goal.coverImage),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 3),
              ),
              child: Text(goal.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                goal.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(width: 12),
              Semantics(
                label: 'Zwischenzielfortschritt',
                value: '$progress %',
                child: ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress! / 100,
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: FittedBox(
                            child: Text(
                              '$progress %',
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
        const SizedBox(height: 16),
        Text(
          'Frist: ${goal.dueDate == null ? 'Ohne Frist' : MaterialLocalizations.of(context).formatMediumDate(goal.dueDate!)}${goal.dueDate != null && !goal.achieved ? ' · ${deadlineLabel(goal.dueDate)}' : ''}',
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
