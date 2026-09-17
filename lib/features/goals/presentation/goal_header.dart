import 'package:flutter/material.dart';

import '../domain/models.dart';

/// A shallow cover stays independent of the goal's content and future images.
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
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 88,
                width: double.infinity,
                child: CustomPaint(painter: _CoverPainter(theme.colorScheme)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 62, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        goal.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frist: ${goal.dueDate == null ? 'Ohne Frist' : MaterialLocalizations.of(context).formatMediumDate(goal.dueDate!)}${goal.dueDate != null && !goal.achieved ? ' · ${deadlineLabel(goal.dueDate)}' : ''}',
                  ),
                  if (progress == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Noch keine Zwischenziele',
                      style: theme.textTheme.bodySmall,
                    ),
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
              ),
            ),
            if (progress != null) ...[
              const SizedBox(width: 16),
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
                        Text('$progress %', style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter(this.colors);
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.primaryContainer,
    );
    canvas.drawCircle(
      Offset(size.width * .77, 20),
      30,
      Paint()..color = colors.primary.withValues(alpha: .12),
    );
    final hills = Path()
      ..moveTo(0, size.height * .8)
      ..quadraticBezierTo(
        size.width * .25,
        5,
        size.width * .5,
        size.height * .7,
      )
      ..quadraticBezierTo(size.width * .8, size.height * 1.1, size.width, 25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hills,
      Paint()..color = colors.primary.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(_CoverPainter oldDelegate) => oldDelegate.colors != colors;
}
