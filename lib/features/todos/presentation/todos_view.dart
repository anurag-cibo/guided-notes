import 'package:flutter/material.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/presentation/common.dart';
import '../domain/todo_models.dart';

class TodosView extends StatelessWidget {
  const TodosView({super.key, required this.controller});
  final GoalsController controller;

  @override
  Widget build(BuildContext context) {
    final now = controller.repository.now();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: pagePadding,
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeading(
                          title: frequency == TodoFrequency.daily
                              ? 'Heute'
                              : 'Diese Woche',
                          addLabel: frequency == TodoFrequency.daily
                              ? 'Tagesaufgabe hinzufügen'
                              : 'Wochenaufgabe hinzufügen',
                          onAdd: controller.saving
                              ? null
                              : () => _openEditor(context, frequency),
                        ),
                        const SizedBox(height: 4),
                        Text(_periodLabel(context, frequency, now)),
                        gap,
                        if (!controller.snapshot.todoEntries.any(
                          (e) => e.frequency == frequency && e.isCurrent(now),
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              frequency == TodoFrequency.daily
                                  ? 'Was möchtest du jeden Tag tun?'
                                  : 'Was möchtest du mehrmals pro Woche tun?',
                            ),
                          ),
                        for (final entry
                            in controller.snapshot.todoEntries.where(
                              (e) =>
                                  e.frequency == frequency && e.isCurrent(now),
                            ))
                          _TodoCard(controller: controller, entry: entry),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        BottomPanel(
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
      ],
    );
  }

  void _openEditor(BuildContext context, TodoFrequency frequency) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              TodoEditor(controller: controller, frequency: frequency),
        ),
      );
}

String _periodLabel(
  BuildContext context,
  TodoFrequency frequency,
  DateTime now,
) {
  final start = DateTime.parse(periodStart(frequency, now));
  final format = MaterialLocalizations.of(context).formatMediumDate;
  return frequency == TodoFrequency.daily
      ? format(start)
      : '${format(start)} – ${format(DateTime(start.year, start.month, start.day + 6))}';
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({required this.controller, required this.entry});
  final GoalsController controller;
  final TodoEntry entry;

  @override
  Widget build(BuildContext context) {
    final template = controller.snapshot.todoTemplates.firstWhere(
      (t) => t.id == entry.templateId,
    );
    final done = entry.completed == entry.target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.frequency == TodoFrequency.daily)
                Checkbox(
                  value: done,
                  onChanged: controller.saving
                      ? null
                      : (value) => runMutation(
                          context,
                          controller,
                          (r) => r.todos.changeCount(
                            entry,
                            value == true ? 1 : -1,
                          ),
                        ),
                  semanticLabel: entry.title,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
              if (template.active)
                IconButton(
                  tooltip: '${entry.title} bearbeiten',
                  icon: const Icon(Icons.more_horiz),
                  onPressed: controller.saving
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TodoEditor(
                              controller: controller,
                              frequency: template.frequency,
                              template: template,
                            ),
                          ),
                        ),
                ),
            ],
          ),
          if (entry.frequency == TodoFrequency.weekly)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: '${entry.title}: einmal rückgängig',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: controller.saving || entry.completed == 0
                      ? null
                      : () => runMutation(
                          context,
                          controller,
                          (r) => r.todos.changeCount(entry, -1),
                        ),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    '${entry.completed} von ${entry.target} erledigt',
                  ),
                ),
                IconButton(
                  tooltip: '${entry.title}: einmal erledigt',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: controller.saving || done
                      ? null
                      : () => runMutation(
                          context,
                          controller,
                          (r) => r.todos.changeCount(entry, 1),
                        ),
                ),
              ],
            ),
          if (!template.active) const Text('Endet nach diesem Zeitraum.'),
          if (template.active &&
              (template.title != entry.title ||
                  template.target != entry.target))
            const Text('Änderung gilt ab dem nächsten Zeitraum.'),
        ],
      ),
    );
  }
}

class TodoEditor extends StatefulWidget {
  const TodoEditor({
    super.key,
    required this.controller,
    required this.frequency,
    this.template,
  });
  final GoalsController controller;
  final TodoFrequency frequency;
  final TodoTemplate? template;
  @override
  State<TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<TodoEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.template?.title ?? '');
  late final _target = TextEditingController(
    text: '${widget.template?.target ?? 3}',
  );
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final saved = await runMutation(
      context,
      widget.controller,
      (r) => r.todos.save(
        id: widget.template?.id,
        title: _title.text,
        frequency: widget.frequency,
        target: widget.frequency == TodoFrequency.daily
            ? 1
            : int.parse(_target.text.trim()),
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufgabe beenden?'),
        content: const Text(
          'Ab dem nächsten Zeitraum erscheint diese Aufgabe nicht mehr. Der aktuelle Stand und die Historie bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final saved = await runMutation(
      context,
      widget.controller,
      (r) => r.todos.stop(widget.template!.id),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template != null
              ? 'Aufgabe bearbeiten'
              : widget.frequency == TodoFrequency.daily
              ? 'Neue Tagesaufgabe'
              : 'Neue Wochenaufgabe',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: pagePadding,
          children: [
            TextFormField(
              controller: _title,
              enabled: !_busy,
              autofocus: widget.template == null,
              decoration: const InputDecoration(labelText: 'Aufgabe'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bitte eine Aufgabe eingeben.'
                  : null,
            ),
            gap,
            if (widget.frequency == TodoFrequency.weekly) ...[
              TextFormField(
                controller: _target,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Wie oft pro Woche?',
                ),
                validator: (value) {
                  final count = int.tryParse(value?.trim() ?? '');
                  return count == null || count < 1 || count > 999
                      ? 'Bitte eine Zahl von 1 bis 999 eingeben.'
                      : null;
                },
              ),
              gap,
            ],
            Text(
              widget.frequency == TodoFrequency.daily
                  ? 'Jeden Tag einmal. Ein neuer Tag beginnt um Mitternacht.'
                  : 'Eine Woche geht von Montag bis Sonntag. Du kannst Erledigungen jederzeit in der laufenden Woche zurücknehmen.',
            ),
            if (widget.template != null) ...[
              gap,
              const Text(
                'Änderungen gelten ab dem nächsten Zeitraum. Der aktuelle Stand bleibt erhalten.',
              ),
            ],
            gap,
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Speichern'),
            ),
            if (widget.template != null) ...[
              gap,
              TextButton(
                onPressed: _busy ? null : _stop,
                child: const Text('Aufgabe beenden'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
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
                        '${e.frequency.label} · ${_periodLabel(context, e.frequency, DateTime.parse(e.period))}\n${e.completed} von ${e.target} erledigt',
                      ),
                    ),
                  );
                },
              ),
      );
    },
  );
}
