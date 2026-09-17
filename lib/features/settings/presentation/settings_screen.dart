import 'package:flutter/material.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/presentation/backup_screen.dart';
import '../../goals/presentation/common.dart';
import '../application/settings_controller.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.goals,
  });
  final SettingsController settings;
  final GoalsController goals;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Einstellungen')),
    body: ListenableBuilder(
      listenable: Listenable.merge([settings, goals]),
      builder: (context, _) => ListView(
        padding: pagePadding,
        children: [
          _heading(context, 'Darstellung'),
          const Text('Wähle, was sich für dich gut anfühlt.'),
          gap,
          Card(
            child: RadioGroup<AppAppearance>(
              groupValue: settings.appearance,
              onChanged: (value) {
                if (value != null) settings.setAppearance(value);
              },
              child: Column(
                children: [
                  for (final mode in AppAppearance.values)
                    RadioListTile<AppAppearance>(
                      value: mode,
                      enabled: !settings.loading && !settings.saving,
                      title: Text(switch (mode) {
                        AppAppearance.system => 'Wie das Gerät',
                        AppAppearance.light => 'Hellmodus',
                        AppAppearance.dark => 'Dunkelmodus',
                      }),
                      secondary: Icon(switch (mode) {
                        AppAppearance.system => Icons.brightness_auto_outlined,
                        AppAppearance.light => Icons.light_mode_outlined,
                        AppAppearance.dark => Icons.dark_mode_outlined,
                      }),
                    ),
                ],
              ),
            ),
          ),
          if (settings.error != null) ...[
            Text(
              settings.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: settings.loading || settings.saving
                  ? null
                  : settings.load,
              child: const Text('Erneut laden'),
            ),
          ],
          gap,
          _heading(context, 'Deine Daten'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Datensicherung'),
                  subtitle: const Text('Exportieren und wiederherstellen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: goals.loading || goals.saving || goals.error != null
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => BackupScreen(controller: goals),
                          ),
                        ),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Alle Inhalte löschen'),
                  subtitle: const Text('Ziele, Todos und Archive'),
                  onTap:
                      goals.loading ||
                          goals.saving ||
                          goals.error != null ||
                          goals.snapshot.isEmpty
                      ? null
                      : () => _deleteAll(context),
                ),
              ],
            ),
          ),
          gap,
          _heading(context, 'Über die App'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.explore_outlined),
                  title: Text('The Guide'),
                  subtitle: Text('Version 0.1.0 · Ziele in kleinen Schritten'),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Daten und Privatsphäre'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Deine Daten bleiben bei dir'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Die App speichert Ziele, Motivation und Todos lokal auf diesem Gerät. Sie benötigt kein Konto und enthält keine Analyse- oder Werbedienste.\n\nExportierte Sicherungen sind unverschlüsselt. Bewahre sie an einem geschützten Ort außerhalb des Geräts auf. Dateien, die du exportiert hast, werden beim Löschen der App-Inhalte nicht entfernt.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Verstanden'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Lizenzen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'The Guide',
                    applicationVersion: '0.1.0',
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Kleine Schritte. Deine Richtung.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _heading(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Future<void> _deleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Alle Inhalte endgültig löschen?'),
        content: const Text(
          'Alle Ziele, Zwischenziele, Todos und vergangenen Stände auf diesem Gerät werden unwiderruflich gelöscht. Exportiere vorher eine Sicherung, wenn du sie behalten möchtest. Deine Darstellungswahl bleibt erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Alle Inhalte löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (await runMutation(context, goals, (r) => r.deleteAllContents()) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alle Inhalte wurden gelöscht.')),
      );
    }
  }
}
