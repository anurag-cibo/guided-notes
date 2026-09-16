import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import 'common.dart';
import 'goal_editor.dart';
import 'goal_list.dart';
import 'milestones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final GoalsController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
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
          appBar: AppBar(title: Text(_tab == 0 ? 'Ziele' : 'Zwischenziele')),
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
              : MilestonesView(controller: c),
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
            ],
          ),
        ),
      );
    },
  );
}

void openGoalEditor(BuildContext context, GoalsController controller) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalEditor(controller: controller),
      ),
    );
