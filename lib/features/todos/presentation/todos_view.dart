import 'todo_group.dart';

import 'package:flutter/material.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/presentation/common.dart';
import '../domain/todo_models.dart';
export 'todo_editor.dart';

class TodosView extends StatelessWidget {
  const TodosView({super.key, required this.controller});
  final GoalsController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: pagePadding,
          sliver: SliverList.list(
            children: [
              Text(
                'Kleine Schritte, jeden Tag.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hake ab, was du geschafft hast. Morgen beginnt ein neuer Tag.',
              ),
              const SizedBox(height: 28),
              for (final frequency in TodoFrequency.values)
                TodoGroup(controller: controller, frequency: frequency),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: BottomPanel(
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.history),
                  title: const Text('Vergangene Zeiträume'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TodoHistoryScreen(controller: controller),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TodoHistoryScreen extends StatelessWidget {
  const TodoHistoryScreen({super.key, required this.controller});
  final GoalsController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final entries = controller.snapshot.todoEntries
          .where((e) => !e.isCurrent(controller.repository.now()))
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Vergangene Zeiträume')),
        body: entries.isEmpty
            ? ListView(
                padding: pagePadding,
                children: const [
                  EmptyMessage(
                    'Noch keine vergangenen Zeiträume',
                    'Hier bleiben deine Tages- und Wochenstände erhalten. Zeiträume ohne App-Nutzung werden nicht nachträglich angelegt.',
                  ),
                ],
              )
            : ListView.builder(
                padding: pagePadding,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final e = entries[index];
                  return Card(
                    child: ListTile(
                      title: Text(e.title),
                      subtitle: Text(
                        '${e.frequency.label} · ${todoPeriodLabel(context, e.frequency, DateTime.parse(e.period))}\n${e.completed} von ${e.target} erledigt',
                      ),
                    ),
                  );
                },
              ),
      );
    },
  );
}
