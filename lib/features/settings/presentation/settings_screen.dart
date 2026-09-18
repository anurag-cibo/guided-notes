import 'package:flutter/material.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/presentation/backup_screen.dart';
import '../../goals/presentation/common.dart';
import '../application/settings_controller.dart';
import 'appearance_selector.dart';
import 'custom_themes_screen.dart';

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
          AppearanceSelector(settings: settings),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Eigene Themes'),
              subtitle: const Text(
                'Farben für deine Ziele erstellen und bearbeiten',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: goals.loading || goals.error != null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CustomThemesScreen(controller: goals),
                      ),
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
          _heading(context, 'Allgemein'),
          Card(
            child: Column(
              children: [
                const _SettingsStub(
                  icon: Icons.language_outlined,
                  title: 'Sprache',
                  detail: 'Deutsch',
                ),
                const Divider(indent: 56),
                const _SettingsStub(
                  icon: Icons.notifications_outlined,
                  title: 'Benachrichtigungen',
                ),
                const Divider(indent: 56),
                const _SettingsStub(
                  icon: Icons.alarm_outlined,
                  title: 'Erinnerungen',
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Daten exportieren'),
                  subtitle: const Text('Datensicherung und Wiederherstellung'),
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
                  subtitle: const Text(
                    'Ziele, Todos, Archive und eigene Themes',
                  ),
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
                  title: const Text('Datenschutz'),
                  subtitle: const Text(
                    'Informationen zur lokalen Datenhaltung',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Deine Daten bleiben bei dir'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Die App speichert Ziele, Zielbilder, Motivation und Todos lokal auf diesem Gerät. Sie benötigt kein Konto und enthält keine Analyse- oder Werbedienste.\n\nExportierte Sicherungen sind unverschlüsselt und enthalten auch deine Zielbilder. Bewahre sie an einem geschützten Ort außerhalb des Geräts auf. Dateien, die du exportiert hast, werden beim Löschen der App-Inhalte nicht entfernt.',
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
                const _SettingsStub(
                  icon: Icons.description_outlined,
                  title: 'Impressum',
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
          'Alle Ziele, Zwischenziele, Todos, vergangenen Stände und eigenen Themes auf diesem Gerät werden unwiderruflich gelöscht. Exportiere vorher eine Sicherung, wenn du sie behalten möchtest. Deine Darstellungswahl bleibt erhalten.',
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

class _SettingsStub extends StatelessWidget {
  const _SettingsStub({required this.icon, required this.title, this.detail});
  final IconData icon;
  final String title;
  final String? detail;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(
      '${detail == null ? '' : '$detail · '}Platzhalter – noch nicht verfügbar',
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Dieser Bereich ist ein Platzhalter. Die Funktion ist noch nicht implementiert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    ),
  );
}
