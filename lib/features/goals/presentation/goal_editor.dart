import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/cover_image.dart';
import 'goal_cover.dart';
import 'goal_theme.dart';
import '../../settings/presentation/custom_themes_screen.dart';

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
  late final _emoji = TextEditingController(
    text: (widget.goal?.emoji ?? '◎').characters.take(1).toString(),
  );
  late final _motivation = TextEditingController(text: widget.goal?.motivation);
  late DateTime? _due = widget.goal?.dueDate;
  bool _saving = false;
  bool _picking = false;
  late Uint8List? _cover = widget.goal?.coverImage;
  late GoalColor _color = widget.goal?.color ?? GoalColor.forest;
  late int? _customThemeId = widget.goal?.customThemeId;
  @override
  void dispose() {
    _title.dispose();
    _emoji.dispose();
    _motivation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
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
        coverImage: _cover,
        removeCoverImage: _cover == null,
        color: _color,
        customThemeId: _customThemeId,
        clearCustomTheme: _customThemeId == null,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickCover() async {
    setState(() => _picking = true);
    try {
      final image = await CoverImages.pick();
      if (mounted && image != null) setState(() => _cover = image);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is RuleViolation
                  ? error.message
                  : error is PlatformException
                  ? error.message ?? 'Das Bild konnte nicht geladen werden.'
                  : 'Die Bildauswahl ist nicht verfügbar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => GoalTheme(
    color: _color,
    colors: widget.controller.snapshot.theme(_customThemeId)?.colors,
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.goal == null ? 'Neues Ziel' : 'Ziel bearbeiten'),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: pagePadding,
            children: [
              Semantics(
                label: 'Hintergrundbild-Vorschau',
                child: GoalCover(image: _cover, height: 120),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving || _picking ? null : _pickCover,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _picking
                          ? 'Bild wird geladen …'
                          : _cover == null
                          ? 'Hintergrundbild auswählen'
                          : 'Hintergrundbild ändern',
                    ),
                  ),
                  if (_cover != null)
                    IconButton(
                      tooltip: 'Hintergrundbild entfernen',
                      onPressed: _saving || _picking
                          ? null
                          : () => setState(() => _cover = null),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      key: const ValueKey('goal-emoji'),
                      controller: _emoji,
                      onTap: () => _emoji.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _emoji.text.length,
                      ),
                      enabled: !_saving,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Emoji',
                        counterText: '',
                      ),
                      maxLength: 1,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.characters.length <= 1) {
                            return newValue;
                          }
                          final symbol = newValue.text.characters.first;
                          return TextEditingValue(
                            text: symbol,
                            selection: TextSelection.collapsed(
                              offset: symbol.length,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('goal-title'),
                      controller: _title,
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: 'Titel'),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Bitte einen Titel eingeben.'
                          : null,
                    ),
                  ),
                ],
              ),
              gap,
              GoalColorSelector(
                value: _color,
                customThemes: widget.controller.snapshot.customThemes,
                customThemeId: _customThemeId,
                onCustomChanged: _saving
                    ? null
                    : (id) => setState(() => _customThemeId = id),
                onCreate: _saving
                    ? null
                    : () async {
                        final id = await Navigator.push<int>(
                          context,
                          MaterialPageRoute<int>(
                            builder: (_) => ThemeEditor(
                              controller: widget.controller,
                              initialColors:
                                  widget.controller.snapshot
                                      .theme(_customThemeId)
                                      ?.colors ??
                                  _color.colors,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            if (id != null) _customThemeId = id;
                          });
                        }
                      },
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                        _color = value;
                        _customThemeId = null;
                      }),
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
                onPressed: _saving || _picking ? null : _save,
                child: Text(_saving ? 'Wird gespeichert …' : 'Speichern'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
