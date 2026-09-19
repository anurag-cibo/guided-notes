import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../data/goals_repository.dart';

const pagePadding = EdgeInsets.all(20);
const gap = SizedBox(height: 16);

class AddCircleButton extends StatelessWidget {
  const AddCircleButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      shape: const CircleBorder(),
      minimumSize: const Size(48, 48),
    ),
    icon: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: onPressed == null
              ? Theme.of(context).disabledColor
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      child: const Icon(Icons.add, size: 18),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.addLabel,
    this.onAdd,
  });
  final String title;
  final String? addLabel;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (addLabel != null) ...[
        const SizedBox(width: 12),
        AddCircleButton(label: addLabel!, onPressed: onAdd),
      ],
    ],
  );
}

class BottomPanel extends StatelessWidget {
  const BottomPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: child,
    ),
  );
}

Future<bool> runMutation(
  BuildContext context,
  GoalsController controller,
  Future<void> Function(GoalsRepository) action,
) => showMutationResult(context, controller.mutate(action));

Future<bool> showMutationResult(
  BuildContext context,
  Future<String?> mutation,
) async {
  final message = await mutation;
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
