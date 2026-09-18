import 'package:flutter/material.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/presentation/common.dart';
import '../domain/todo_models.dart';
import 'milestone_picker.dart';
import 'progress_increment_picker.dart';

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
  late int? _milestoneId = widget.template?.milestoneId;
  late bool _trackProgress =
      _milestoneId != null && (widget.template?.progressIncrement ?? 0) > 0;
  late int _increment = (widget.template?.progressIncrement ?? 0) > 0
      ? widget.template!.progressIncrement
      : 5;
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
        milestoneId: _milestoneId,
        progressIncrement: _milestoneId != null && _trackProgress
            ? _increment
            : 0,
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
                  ? '• Einmal täglich · neuer Tag um Mitternacht'
                  : '• Montag–Sonntag\n• Erledigungen in der laufenden Woche rücknehmbar',
            ),
            gap,
            ListTile(
              key: const ValueKey('todo-milestone'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Zwischenziel (optional)'),
              subtitle: Text(_linkLabel()),
              trailing: const Icon(Icons.expand_more),
              onTap: _busy
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();
                      final selected = await pickMilestone(
                        context,
                        widget.controller.snapshot,
                        _milestoneId,
                      );
                      if (!mounted || selected == null) return;
                      setState(() {
                        _milestoneId = selected == -1 ? null : selected;
                        if (_milestoneId == null) _trackProgress = false;
                      });
                    },
            ),
            if (_milestoneId != null) ...[
              SwitchListTile(
                key: const ValueKey('todo-track-progress'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Fortschritt automatisch erhöhen'),
                value: _trackProgress,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _trackProgress = value),
              ),
              if (_trackProgress) ...[
                ProgressIncrementPicker(
                  key: const ValueKey('todo-progress-increment'),
                  value: _increment,
                  onChanged: _busy ? null : (value) => _increment = value,
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Beitrag je Erledigung, auch bei Wochen-Wiederholungen\n• Fortschritt bis maximal 100 %\n• Rückgängig nimmt den Beitrag zurück',
                ),
              ],
            ],
            if (widget.template != null) ...[
              gap,
              const Text(
                '• Titel und Anzahl: ab nächstem Zeitraum\n• Zuordnung und Beitrag: ab nächster Erledigung\n• Bisherige Beiträge bleiben erhalten',
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

  String _linkLabel() {
    final snapshot = widget.controller.snapshot;
    final milestone = snapshot.milestones
        .where((m) => m.id == _milestoneId)
        .firstOrNull;
    if (milestone == null) return 'Keine Zuordnung';
    final goal = snapshot.goal(milestone.goalId)!;
    return '${goal.title} · ${milestone.title}${goal.archived ? ' (archiviert – neue Beiträge pausiert)' : ''}';
  }
}
