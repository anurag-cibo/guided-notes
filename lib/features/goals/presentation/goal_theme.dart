import 'package:flutter/material.dart';

import '../domain/models.dart';

extension GoalPalette on GoalColor {
  Color get seed => switch (this) {
    GoalColor.forest => const Color(0xff187c68),
    GoalColor.ocean => const Color(0xff286eaa),
    GoalColor.lavender => const Color(0xff8060a8),
    GoalColor.rose => const Color(0xffaa536c),
    GoalColor.amber => const Color(0xff9a6b23),
  };
}

/// Scope goal accents without changing the app-wide appearance preference.
class GoalTheme extends StatelessWidget {
  const GoalTheme({super.key, required this.color, required this.child});
  final GoalColor color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final palette = ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: base.brightness,
    );
    final background = Color.alphaBlend(
      palette.primary.withValues(alpha: .045),
      base.scaffoldBackgroundColor,
    );
    final surface = Color.alphaBlend(
      palette.primary.withValues(alpha: .04),
      base.colorScheme.surface,
    );
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          primaryContainer: palette.primaryContainer,
          onPrimaryContainer: palette.onPrimaryContainer,
          secondary: palette.secondary,
          onSecondary: palette.onSecondary,
          secondaryContainer: palette.secondaryContainer,
          onSecondaryContainer: palette.onSecondaryContainer,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: base.appBarTheme.copyWith(backgroundColor: background),
        cardTheme: base.cardTheme.copyWith(color: surface),
      ),
      child: child,
    );
  }
}

class GoalColorSelector extends StatelessWidget {
  const GoalColorSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final GoalColor value;
  final ValueChanged<GoalColor>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Farbthema', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final color in GoalColor.values)
            ChoiceChip(
              key: ValueKey('goal-color-${color.name}'),
              label: Text(color.label),
              avatar: CircleAvatar(backgroundColor: color.seed, radius: 8),
              selected: value == color,
              onSelected: onChanged == null ? null : (_) => onChanged!(color),
            ),
        ],
      ),
    ],
  );
}
