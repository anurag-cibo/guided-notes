import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/models.dart';
import 'common.dart';

class GoalEditor extends StatefulWidget {
  const GoalEditor({super.key, required this.controller, this.goal});
  final GoalsController controller;
  final Goal? goal;
  @override
  State<GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<GoalEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.goal?.title);
  late final _emoji = TextEditingController(text: widget.goal?.emoji ?? '◎');
  late final _motivation = TextEditingController(text: widget.goal?.motivation);
  late DateTime? _due = widget.goal?.dueDate;
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _emoji.dispose();
    _motivation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await runMutation(
      context,
      widget.controller,
      (r) => r.saveGoal(
        id: widget.goal?.id,
        title: _title.text,
        emoji: _emoji.text,
        motivation: _motivation.text,
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
      title: Text(widget.goal == null ? 'Neues Ziel' : 'Ziel bearbeiten'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: pagePadding,
        children: [
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titel'),
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Bitte einen Titel eingeben.'
                : null,
          ),
          gap,
          TextFormField(
            controller: _emoji,
            decoration: const InputDecoration(
              labelText: 'Emoji oder Symbol (optional)',
            ),
            maxLength: 8,
          ),
          gap,
          TextFormField(
            controller: _motivation,
            decoration: const InputDecoration(
              labelText: 'Warum ist dir das wichtig? (optional)',
            ),
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
          ),
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
        ],
      ),
    ),
  );
}
