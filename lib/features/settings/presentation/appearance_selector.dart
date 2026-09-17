import 'package:flutter/material.dart';

import '../application/settings_controller.dart';
import '../data/settings_repository.dart';

class AppearanceSelector extends StatelessWidget {
  const AppearanceSelector({super.key, required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final enabled = !settings.loading && !settings.saving;
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final mode in [AppAppearance.light, AppAppearance.dark]) ...[
                if (mode == AppAppearance.dark) const SizedBox(width: 12),
                Expanded(
                  child: _AppearanceTile(
                    title: mode == AppAppearance.light
                        ? 'Hellmodus'
                        : 'Dunkelmodus',
                    icon: mode == AppAppearance.light
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    selected: settings.appearance == mode,
                    onTap: enabled ? () => settings.setAppearance(mode) : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Wie das Gerät'),
          value: settings.appearance == AppAppearance.system,
          onChanged: enabled
              ? (value) => settings.setAppearance(
                  value
                      ? AppAppearance.system
                      : Theme.of(context).brightness == Brightness.dark
                      ? AppAppearance.dark
                      : AppAppearance.light,
                )
              : null,
        ),
      ],
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
