import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/goals/application/goals_controller.dart';
import 'features/goals/presentation/home_screen.dart';

class GuideApp extends StatelessWidget {
  const GuideApp({super.key, required this.controller});
  final GoalsController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'The Guide',
    debugShowCheckedModeBanner: false,
    locale: const Locale('de'),
    supportedLocales: const [Locale('de')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff466553)),
      scaffoldBackgroundColor: const Color(0xfff7f8f4),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff7f8f4),
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home: HomeScreen(controller: controller),
  );
}
