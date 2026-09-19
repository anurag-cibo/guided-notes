import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'goal_theme.dart';

class GoalEmojiSelector extends StatelessWidget {
  const GoalEmojiSelector({
    super.key,
    required this.snapshot,
    required this.selectedId,
    required this.onSelected,
  });
  final GoalSnapshot snapshot;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
    child: Row(
      key: const ValueKey('goal-emoji-selector'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final goal in snapshot.activeGoals)
          GoalTheme(
            color: goal.color,
            colors: snapshot.theme(goal.customThemeId)?.colors,
            child: Builder(
              builder: (context) {
                final selected = goal.id == selectedId;
                return Semantics(
                  selected: selected,
                  button: true,
                  label: 'Zu Ziel ${goal.title} springen',
                  child: Tooltip(
                    message: goal.title,
                    excludeFromSemantics: true,
                    child: InkWell(
                      key: ValueKey('goal-jump-${goal.id}'),
                      borderRadius: BorderRadius.circular(16),
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      onTap: () => onSelected(goal.id),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            goal.emoji,
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}
