/// User-authored opaque sRGB colors. Rendering derives readable light/dark roles.
class ThemeColors {
  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.surface,
  });
  final int primary;
  final int secondary;
  final int accent;
  final int surface;
  bool get isValid => [
    primary,
    secondary,
    accent,
    surface,
  ].every((c) => c >= 0xff000000 && c <= 0xffffffff);
}

class CustomGoalTheme {
  const CustomGoalTheme({
    required this.id,
    required this.name,
    required this.colors,
  });
  final int id;
  final String name;
  final ThemeColors colors;
}
