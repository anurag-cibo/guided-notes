import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'common.dart';

extension GoalPalette on GoalColor {
  ThemeColors get colors => switch (this) {
    GoalColor.forest => const ThemeColors(
      primary: 0xff187c68,
      secondary: 0xff60764a,
      accent: 0xffb48a3c,
      surface: 0xff40846a,
    ),
    GoalColor.ocean => const ThemeColors(
      primary: 0xff286eaa,
      secondary: 0xff347d82,
      accent: 0xff8760a1,
      surface: 0xff417db8,
    ),
    GoalColor.lavender => const ThemeColors(
      primary: 0xff8060a8,
      secondary: 0xffa66889,
      accent: 0xff467d84,
      surface: 0xff9570b5,
    ),
    GoalColor.rose => const ThemeColors(
      primary: 0xffaa536c,
      secondary: 0xff9c6d53,
      accent: 0xff785798,
      surface: 0xffb96a85,
    ),
    GoalColor.amber => const ThemeColors(
      primary: 0xff9a6b23,
      secondary: 0xff9b5740,
      accent: 0xff627746,
      surface: 0xffb98335,
    ),
  };
  Color get seed => Color(colors.primary);
}

/// Scope goal accents without changing the app-wide appearance preference.
class GoalTheme extends StatelessWidget {
  const GoalTheme({
    super.key,
    required this.color,
    this.colors,
    required this.child,
  });
  final GoalColor color;
  final ThemeColors? colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final roles = colors ?? color.colors;
    final palette = ColorScheme.fromSeed(
      seedColor: Color(roles.primary),
      brightness: base.brightness,
    );
    final secondary = ColorScheme.fromSeed(
      seedColor: Color(roles.secondary),
      brightness: base.brightness,
    );
    final accent = ColorScheme.fromSeed(
      seedColor: Color(roles.accent),
      brightness: base.brightness,
    );
    final tone = ColorScheme.fromSeed(
      seedColor: Color(roles.surface),
      brightness: base.brightness,
    );
    final background = Color.alphaBlend(
      tone.primary.withValues(alpha: .045),
      base.scaffoldBackgroundColor,
    );
    final surface = Color.alphaBlend(
      tone.primary.withValues(
        alpha: base.brightness == Brightness.dark ? .16 : .10,
      ),
      base.colorScheme.surface,
    );
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          primaryContainer: palette.primaryContainer,
          onPrimaryContainer: palette.onPrimaryContainer,
          secondary: secondary.primary,
          onSecondary: secondary.onPrimary,
          secondaryContainer: secondary.primaryContainer,
          onSecondaryContainer: secondary.onPrimaryContainer,
          tertiary: accent.primary,
          onTertiary: accent.onPrimary,
          tertiaryContainer: accent.primaryContainer,
          onTertiaryContainer: accent.onPrimaryContainer,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: base.appBarTheme.copyWith(backgroundColor: background),
        cardTheme: base.cardTheme.copyWith(color: surface),
      ),
      child: child,
    );
  }
}

class GoalColorSelector extends StatefulWidget {
  const GoalColorSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.customThemes = const [],
    this.customThemeId,
    this.onCustomChanged,
    this.onCreate,
  });
  final GoalColor value;
  final ValueChanged<GoalColor>? onChanged;
  final List<CustomGoalTheme> customThemes;
  final int? customThemeId;
  final ValueChanged<int>? onCustomChanged;
  final VoidCallback? onCreate;

  @override
  State<GoalColorSelector> createState() => _GoalColorSelectorState();
}

class _GoalColorSelectorState extends State<GoalColorSelector> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final onChanged = widget.onChanged;
    final customThemeId = widget.customThemeId;
    final onCustomChanged = widget.onCustomChanged;
    // A bounded preview always includes the selected theme.
    final presets = _expanded
        ? GoalColor.values
        : GoalColor.values.where(
            (c) => c.index < 3 || (customThemeId == null && c == value),
          );
    final customThemes = _expanded
        ? widget.customThemes
        : widget.customThemes.where((t) => t.id == customThemeId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: 'Farbthema',
          addLabel: widget.onCreate == null ? null : 'Eigenes Theme erstellen',
          onAdd: widget.onCreate,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final color in presets)
              ChoiceChip(
                key: ValueKey('goal-color-${color.name}'),
                label: Text(color.label),
                avatar: CircleAvatar(backgroundColor: color.seed, radius: 8),
                selected: customThemeId == null && value == color,
                onSelected: onChanged == null ? null : (_) => onChanged(color),
              ),
            for (final theme in customThemes)
              ChoiceChip(
                key: ValueKey('custom-theme-${theme.id}'),
                label: Text(theme.name),
                avatar: CircleAvatar(
                  backgroundColor: Color(theme.colors.primary),
                  radius: 8,
                ),
                selected: customThemeId == theme.id,
                onSelected: onCustomChanged == null
                    ? null
                    : (_) => onCustomChanged(theme.id),
              ),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Weniger anzeigen' : 'Mehr anzeigen'),
            ),
          ],
        ),
      ],
    );
  }
}
