import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../goals/application/goals_controller.dart';
import '../../goals/domain/models.dart';
import '../../goals/presentation/common.dart';
import '../../goals/presentation/goal_theme.dart';

class CustomThemesScreen extends StatelessWidget {
  const CustomThemesScreen({super.key, required this.controller});
  final GoalsController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Eigene Themes')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: pagePadding,
        children: [
          SectionHeading(
            title: 'Deine Themes',
            addLabel: 'Eigenes Theme erstellen',
            onAdd: controller.saving
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<int>(
                      builder: (_) => ThemeEditor(controller: controller),
                    ),
                  ),
          ),
          const Text(
            'Vier Farben, dein Stil. Änderungen gelten für alle Ziele mit diesem Theme.',
          ),
          gap,
          if (controller.snapshot.customThemes.isEmpty)
            const EmptyMessage(
              'Noch keine eigenen Themes',
              'Erstelle ein Theme und wähle es anschließend bei einem Ziel aus.',
            ),
          for (final theme in controller.snapshot.customThemes)
            GoalTheme(
              color: GoalColor.forest,
              colors: theme.colors,
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(theme.colors.primary),
                  ),
                  title: Text(theme.name),
                  subtitle: const Text('Farben und Name bearbeiten'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: controller.saving
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<int>(
                            builder: (_) => ThemeEditor(
                              controller: controller,
                              theme: theme,
                            ),
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class ThemeEditor extends StatefulWidget {
  const ThemeEditor({
    super.key,
    required this.controller,
    this.theme,
    this.initialColors,
  });
  final GoalsController controller;
  final CustomGoalTheme? theme;
  final ThemeColors? initialColors;
  @override
  State<ThemeEditor> createState() => _ThemeEditorState();
}

class _ThemeEditorState extends State<ThemeEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.theme?.name);
  late final List<int> _colors = [
    (widget.theme?.colors ?? widget.initialColors ?? GoalColor.forest.colors)
        .primary,
    (widget.theme?.colors ?? widget.initialColors ?? GoalColor.forest.colors)
        .secondary,
    (widget.theme?.colors ?? widget.initialColors ?? GoalColor.forest.colors)
        .accent,
    (widget.theme?.colors ?? widget.initialColors ?? GoalColor.forest.colors)
        .surface,
  ];
  bool _saving = false;
  ThemeColors get _palette => ThemeColors(
    primary: _colors[0],
    secondary: _colors[1],
    accent: _colors[2],
    surface: _colors[3],
  );
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    int? id;
    final saved = await runMutation(context, widget.controller, (r) async {
      id = await r.saveTheme(
        id: widget.theme?.id,
        name: _name.text,
        colors: _palette,
      );
    });
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, id);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => GoalTheme(
    color: GoalColor.forest,
    colors: _palette,
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.theme == null ? 'Theme erstellen' : 'Theme bearbeiten',
          ),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: pagePadding,
            children: [
              TextFormField(
                key: const ValueKey('theme-name'),
                controller: _name,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Name des Themes'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Bitte einen Namen eingeben.'
                    : null,
              ),
              gap,
              for (var i = 0; i < 4; i++)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Color(_colors[i])),
                    title: Text(
                      [
                        'Primärfarbe',
                        'Sekundärfarbe',
                        'Akzentfarbe',
                        'Flächenton',
                      ][i],
                    ),
                    subtitle: Text(
                      [
                        'Schaltflächen und Fortschritt',
                        'Ergänzende Flächen und Cover',
                        'Akzente im Cover und Details',
                        'Sanfte Tönung der Karten',
                      ][i],
                    ),
                    trailing: const Icon(Icons.colorize_outlined),
                    onTap: _saving
                        ? null
                        : () async {
                            final color = await showDialog<int>(
                              context: context,
                              builder: (_) => _ColorPicker(value: _colors[i]),
                            );
                            if (mounted && color != null) {
                              setState(() => _colors[i] = color);
                            }
                          },
                  ),
                ),
              const Text(
                'Die Vorschau passt Farben für gute Lesbarkeit an Hell- und Dunkelmodus an.',
              ),
              gap,
              Card(
                child: Padding(
                  padding: pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('So wirkt dein Ziel')),
                        ],
                      ),
                      gap,
                      const LinearProgressIndicator(value: .6),
                      gap,
                      Chip(
                        label: const Text('Ein kleiner Schritt'),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              gap,
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Wird gespeichert …' : 'Theme speichern'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.value});
  final int value;
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  final _form = GlobalKey<FormState>();
  late final _hex = TextEditingController(
    text: widget.value.toRadixString(16).substring(2).toUpperCase(),
  );
  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Farbe wählen'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final value in [
                0xff187c68,
                0xff427344,
                0xff347d82,
                0xff286eaa,
                0xff455ca8,
                0xff8060a8,
                0xffaa536c,
                0xffb45c40,
                0xff9a6b23,
                0xffc3a546,
                0xff6b7581,
                0xff3c4549,
              ])
                IconButton(
                  tooltip:
                      '#${value.toRadixString(16).substring(2).toUpperCase()}',
                  onPressed: () => setState(
                    () => _hex.text = value
                        .toRadixString(16)
                        .substring(2)
                        .toUpperCase(),
                  ),
                  icon: Icon(Icons.circle, color: Color(value), size: 32),
                ),
            ],
          ),
          gap,
          TextFormField(
            key: const ValueKey('theme-hex'),
            controller: _hex,
            decoration: const InputDecoration(
              labelText: 'Eigene Farbe (Hex)',
              prefixText: '#',
            ),
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-fA-F0-9]')),
            ],
            validator: (value) =>
                value != null && RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(value)
                ? null
                : 'Sechs Zeichen, z. B. 187C68',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              0xff000000 | int.parse(_hex.text, radix: 16),
            );
          }
        },
        child: const Text('Übernehmen'),
      ),
    ],
  );
}
