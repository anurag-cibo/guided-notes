import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../data/goals_repository.dart';

const pagePadding = EdgeInsets.all(20);
const gap = SizedBox(height: 16);

Future<bool> runMutation(
  BuildContext context,
  GoalsController controller,
  Future<void> Function(GoalsRepository) action,
) async {
  final message = await controller.mutate(action);
  if (!context.mounted) return false;
  if (message != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
  return true;
}

Future<bool> confirmDeletion(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Endgültig löschen?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    ) ??
    false;

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.title, this.description, {super.key});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        gap,
        Text(description),
      ],
    ),
  );
}

class DueDateField extends StatelessWidget {
  const DueDateField({super.key, required this.value, required this.onChanged});
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 8,
    children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.event_outlined),
        label: Text(
          value == null
              ? 'Frist hinzufügen'
              : 'Frist: ${MaterialLocalizations.of(context).formatMediumDate(value!)}',
        ),
        onPressed: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2200),
          );
          if (selected != null) onChanged(selected);
        },
      ),
      if (value != null)
        IconButton(
          tooltip: 'Frist entfernen',
          onPressed: () => onChanged(null),
          icon: const Icon(Icons.close),
        ),
    ],
  );
}
