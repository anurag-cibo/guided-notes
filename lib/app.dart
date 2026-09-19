import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/goals/application/goals_controller.dart';
import 'features/goals/presentation/home_screen.dart';
import 'features/settings/application/settings_controller.dart';
import 'features/settings/data/settings_repository.dart';
import 'theme/guide_theme.dart';

class GuideApp extends StatefulWidget {
  const GuideApp({super.key, required this.controller});
  final GoalsController controller;
  @override
  State<GuideApp> createState() => _GuideAppState();
}

class _GuideAppState extends State<GuideApp> {
  late final settings = SettingsController(
    SettingsRepository(widget.controller.repository.database),
  );
  @override
  void initState() {
    super.initState();
    settings.load(startLight: true);
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      title: 'The Guide',
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: guideTheme(Brightness.light),
      darkTheme: guideTheme(Brightness.dark),
      themeMode: switch (settings.appearance) {
        AppAppearance.system => ThemeMode.system,
        AppAppearance.light => ThemeMode.light,
        AppAppearance.dark => ThemeMode.dark,
      },
      home: HomeScreen(controller: widget.controller, settings: settings),
    ),
  );
}
