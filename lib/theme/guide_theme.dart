import 'package:flutter/material.dart';

import '../features/goals/domain/models.dart';

/// Central palette shared by every screen, including forms and dialogs.
ThemeData guideTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = Color(dark ? 0xff101923 : 0xfffaf8f5);
  final surface = Color(dark ? 0xff1d2b39 : 0xfffffefd);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff187c68),
        brightness: brightness,
      ).copyWith(
        primary: Color(dark ? 0xff7cdbb3 : 0xff187c68),
        onPrimary: Color(dark ? 0xff003828 : 0xffffffff),
        surface: surface,
        onSurface: Color(dark ? 0xffe5edf5 : 0xff20364a),
        onSurfaceVariant: Color(dark ? 0xffb5c3d2 : 0xff526579),
        outlineVariant: Color(dark ? 0xff334454 : 0xffe1e5e7),
        primaryContainer: Color(dark ? 0xff23473f : 0xffe4f1e9),
        onPrimaryContainer: Color(dark ? 0xffbcf3db : 0xff204c3e),
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: scheme.primaryContainer,
      height: 72,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
  );
}

Color milestoneSurface(BuildContext context, MilestoneStatus status) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    MilestoneStatus.achieved ||
    MilestoneStatus.onTrack => Color(dark ? 0xff203e37 : 0xffeaf6ee),
    MilestoneStatus.offTrack => Color(dark ? 0xff443825 : 0xfffff1df),
    MilestoneStatus.onHold => Color(dark ? 0xff38334b : 0xfff0edf7),
    MilestoneStatus.notStarted => Color(dark ? 0xff233547 : 0xffedf2f7),
  };
}
