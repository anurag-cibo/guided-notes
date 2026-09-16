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
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff187c68))
          .copyWith(
            primary: const Color(0xff187c68),
            onSurface: const Color(0xff20364a),
            surface: const Color(0xfffffdfa),
          ),
      scaffoldBackgroundColor: const Color(0xfffaf8f5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfffaf8f5),
        foregroundColor: Color(0xff20364a),
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xfffffdfa),
        indicatorColor: Color(0xffdceee7),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: Color(0xffe5e8e6)),
        ),
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
