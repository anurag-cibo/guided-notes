import 'dart:async';

import 'package:flutter/material.dart';

import '../../todos/presentation/todos_view.dart';
import '../../todos/domain/todo_models.dart';

import '../application/goals_controller.dart';
import 'common.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import 'goal_list.dart';
import 'milestones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.settings,
  });
  final GoalsController controller;
  final SettingsController settings;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _timer;
  late String _day;
  @override
  void initState() {
    super.initState();
    _day = calendarDate(widget.controller.repository.now());
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshPeriod(),
    );
  }

  void _refreshPeriod() {
    final day = calendarDate(widget.controller.repository.now());
    if (day == _day || widget.controller.loading || widget.controller.saving) {
      return;
    }
    _day = day;
    widget.controller.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPeriod();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      return PopScope(
        canPop: _tab == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _tab != 0) setState(() => _tab = 0);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(['The Guide', 'Zwischenziele', 'Todos'][_tab]),
            actions: [
              IconButton(
                tooltip: 'Einstellungen',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        SettingsScreen(goals: c, settings: widget.settings),
                  ),
                ),
              ),
            ],
          ),
          body: c.loading
              ? const Center(child: CircularProgressIndicator())
              : c.error != null
              ? ListView(
                  padding: pagePadding,
                  children: [
                    Text(c.error!),
                    gap,
                    FilledButton(
                      onPressed: c.load,
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                )
              : _tab == 0
              ? GoalList(controller: c)
              : _tab == 1
              ? MilestonesView(controller: c)
              : TodosView(controller: c),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (index) => setState(() => _tab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(Icons.flag),
                label: 'Ziele',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist),
                label: 'Zwischenziele',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_box_outlined),
                selectedIcon: Icon(Icons.check_box),
                label: 'Todos',
              ),
            ],
          ),
        ),
      );
    },
  );
}
