import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/models.dart';
import 'common.dart';

class MilestoneEditor extends StatefulWidget {
  const MilestoneEditor({
    super.key,
    required this.controller,
    required this.goal,
    this.milestone,
  });
  final GoalsController controller;
  final Goal goal;
  final Milestone? milestone;
  @override
  State<MilestoneEditor> createState() => _MilestoneEditorState();
}

class _MilestoneEditorState extends State<MilestoneEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.milestone?.title);
  late double _progress = widget.milestone?.progress ?? 0;
  late MilestoneStatus _status =
      widget.milestone?.status ?? MilestoneStatus.notStarted;
  late DateTime? _due = widget.milestone?.dueDate;
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await runMutation(
      context,
      widget.controller,
      (r) => r.saveMilestone(
        id: widget.milestone?.id,
        goalId: widget.goal.id,
        title: _title.text,
        progress: _progress,
        status: _status,
        dueDate: _due,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.milestone == null
            ? 'Neues Zwischenziel'
            : 'Zwischenziel bearbeiten',
      ),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: pagePadding,
        children: [
          Text(
            '${widget.goal.emoji} ${widget.goal.title}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          gap,
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titel'),
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Bitte einen Titel eingeben.'
                : null,
          ),
          gap,
          DropdownButtonFormField<MilestoneStatus>(
            initialValue: _status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Status'),
            items: MilestoneStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (s) {
              if (s == null) return;
              setState(() {
                _status = s;
                if (s == MilestoneStatus.achieved) {
                  _progress = 100;
                } else if (s == MilestoneStatus.notStarted) {
                  _progress = 0;
                } else if (_progress == 100) {
                  _progress = 99;
                }
              });
            },
          ),
          gap,
          Text('Fortschritt: ${formatProgress(_progress)} %'),
          Slider(
            value: _progress.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '${formatProgress(_progress)} %',
            onChanged:
                _status == MilestoneStatus.achieved ||
                    _status == MilestoneStatus.notStarted
                ? null
                : (v) => setState(() {
                    _progress = v.round().clamp(0, 99).toDouble();
                  }),
          ),
          if (_status == MilestoneStatus.notStarted)
            const Text('Wähle „Im Plan“, um den Fortschritt einzutragen.'),
          if (_status != MilestoneStatus.achieved &&
              _status != MilestoneStatus.notStarted)
            const Text('Fertig? Wähle den Status „Erreicht“ für 100 %.'),
          gap,
          DueDateField(
            value: _due,
            onChanged: (date) => setState(() => _due = date),
          ),
          gap,
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Wird gespeichert …' : 'Speichern'),
          ),
          if (widget.milestone != null) ...[
            gap,
            TextButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!await confirmDeletion(
                        context,
                        'Dieses Zwischenziel wird gelöscht. Der Zielfortschritt wird neu berechnet.',
                      )) {
                        return;
                      }
                      if (!context.mounted) return;
                      setState(() => _saving = true);
                      final saved = await runMutation(
                        context,
                        widget.controller,
                        (r) => r.deleteMilestone(
                          widget.milestone!.id,
                          widget.goal.id,
                        ),
                      );
                      if (!context.mounted) return;
                      if (saved) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _saving = false);
                      }
                    },
              child: const Text('Zwischenziel löschen'),
            ),
          ],
        ],
      ),
    ),
  );
}
