import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/goals_controller.dart';
import '../data/backup_codec.dart';
import '../domain/models.dart';
import 'common.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key, required this.controller});
  final GoalsController controller;
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  static const channel = MethodChannel('de.anurag.guided_notes/backup');
  bool _busy = false;
  String? _message;

  Future<void> _run(bool importing) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (importing) {
        final source = await channel.invokeMethod<String>('open');
        if (source == null || !mounted) return;
        final preview = BackupCodec.decode(source);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sicherung wiederherstellen?'),
            content: Text(
              '${preview.goals.length} Ziele (davon ${preview.goals.where((g) => g.archived).length} archiviert), ${preview.milestones.length} Zwischenziele, ${preview.todoTemplates.length} Todo-Vorlagen und ${preview.todoEntries.length} Tages-/Wochenstände sowie ${preview.customThemes.length} eigene Themes werden übernommen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Wiederherstellen'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        final error = await widget.controller.mutate(
          (r) => r.importBackup(source),
        );
        _message = error ?? 'Sicherung wiederhergestellt.';
      } else {
        final source = await widget.controller.repository.exportBackup();
        if (utf8.encode(source).length > BackupCodec.maxBytes) {
          throw const RuleViolation(
            'Diese Sicherung überschreitet die unterstützte Größe von 10 MB.',
          );
        }
        final saved = await channel.invokeMethod<bool>('save', {
          'contents': source,
        });
        if (saved == true) _message = 'Sicherung gespeichert. Bewahre die Datei an einem sicheren Ort auf.';
      }
    } on RuleViolation catch (e) {
      _message = e.message;
    } catch (_) {
      _message = 'Die Datei konnte nicht verarbeitet werden. Bitte erneut versuchen. Deine Ziele bleiben erhalten.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Datensicherung')),
      body: ListView(
        padding: pagePadding,
        children: [
          const Icon(Icons.shield_outlined, size: 48),
          gap,
          Text(
            'Deine Ziele bleiben bei dir.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          gap,
          const Text(
            'Sichere Ziele, Motivation, Zwischenziele, Todos, Archive und eigene Themes in einer Datei. Du wählst selbst den Speicherort. Die Datei ist unverschlüsselt.',
          ),
          gap,
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(false),
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Sicherung exportieren'),
          ),
          const SizedBox(height: 32),
          Text(
            'Wiederherstellen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          gap,
          const Text(
            'Der Import ist nur in einer leeren App möglich, zum Beispiel auf einem neuen Gerät. Vorhandene Ziele, Todos, eigene Themes und archivierte Inhalte werden nicht überschrieben oder zusammengeführt.',
          ),
          gap,
          OutlinedButton.icon(
            onPressed: _busy || !widget.controller.snapshot.isEmpty
                ? null
                : () => _run(true),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Sicherung auswählen'),
          ),
          if (_busy) ...[gap, const LinearProgressIndicator()],
          if (_message != null) ...[
            gap,
            Semantics(liveRegion: true, child: Text(_message!)),
          ],
        ],
      ),
    ),
  );
}
