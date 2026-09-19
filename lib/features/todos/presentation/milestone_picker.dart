import 'package:flutter/material.dart';

import '../../goals/domain/models.dart';
import '../../goals/presentation/common.dart';

/// Searchable, grouped selection keeps long goal/milestone names readable.
Future<int?> pickMilestone(
  BuildContext context,
  GoalSnapshot snapshot,
  int? selected,
) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _MilestonePicker(snapshot: snapshot, selected: selected),
);

class _MilestonePicker extends StatefulWidget {
  const _MilestonePicker({required this.snapshot, this.selected});
  final GoalSnapshot snapshot;
  final int? selected;
  @override
  State<_MilestonePicker> createState() => _MilestonePickerState();
}

class _MilestonePickerState extends State<_MilestonePicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final available = snapshot.milestones.where((m) {
      final g = snapshot.goal(m.goalId);
      return g != null &&
          !g.archived &&
          '${g.title} ${m.title}'.toLowerCase().contains(_query);
    }).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            children: [
              Padding(
                padding: pagePadding,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Zwischenziel suchen',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text('Keine Zuordnung'),
                      leading: const Icon(Icons.link_off),
                      onTap: () => Navigator.pop(context, -1),
                    ),
                    if (available.isEmpty)
                      const Padding(
                        padding: pagePadding,
                        child: Text(
                          'Keine passenden Zwischenziele. Lege bei einem aktiven Ziel zuerst ein Zwischenziel an.',
                        ),
                      ),
                    for (final goal in snapshot.activeGoals)
                      if (available.any((m) => m.goalId == goal.id)) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            '${goal.emoji} ${goal.title}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        for (final m in available.where(
                          (m) => m.goalId == goal.id,
                        ))
                          ListTile(
                            title: Text(m.title),
                            subtitle: Text(
                              '${m.measurementLabel} · ${m.status.label}',
                            ),
                            selected: m.id == widget.selected,
                            trailing: m.id == widget.selected
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.pop(context, m.id),
                          ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
