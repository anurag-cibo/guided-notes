import 'package:flutter/material.dart';

import '../application/goals_controller.dart';
import '../domain/models.dart';
import 'common.dart';
import 'measurement_slider.dart';
import '../../todos/domain/todo_models.dart';
import '../../todos/presentation/todo_group.dart';

class MilestoneEditor extends StatefulWidget {
  const MilestoneEditor({
    super.key,
    required this.controller,
    required this.goal,
    this.milestone,
  });
  final GoalsController controller;
  final Goal goal;
  final Milestone? milestone;
  @override
  State<MilestoneEditor> createState() => _MilestoneEditorState();
}

class _MilestoneEditorState extends State<MilestoneEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.milestone?.title);
  late final _start = TextEditingController(
    text: formatProgress(widget.milestone?.scale.start ?? 0),
  );
  late final _target = TextEditingController(
    text: formatProgress(widget.milestone?.scale.target ?? 100),
  );
  late final _current = TextEditingController(
    text: formatProgress(widget.milestone?.currentValue ?? 0),
  );
  late final _unit = TextEditingController(
    text: widget.milestone?.scale.unit ?? '%',
  );
  static const _units = {'%': 'Prozent (%)', '': 'Ohne Einheit'};
  late bool _customUnit = !_units.containsKey(_unit.text);

  MetricScale? get _scale {
    try {
      final start = parseMetric(_start.text),
          target = parseMetric(_target.text);
      if (start == null || target == null) return null;
      final scale = MetricScale(
        start: start,
        target: target,
        unit: _unit.text.trim(),
      );
      scale.validate();
      return scale;
    } on ArgumentError {
      return null;
    }
  }

  double get _progress {
    try {
      return _scale?.percent(parseMetric(_current.text) ?? 0) ?? 0;
    } on ArgumentError {
      return 0;
    }
  }

  void _setCurrent(num value) => _current.text = formatProgress(value);
  void _measurementChanged({bool clamp = false}) {
    final scale = _scale;
    var value = parseMetric(_current.text);
    if (scale == null || value == null) return;
    if (clamp) {
      try {
        final bounded = scale.clampUnits(metricUnits(value)) / 100;
        if (bounded != value) _setCurrent(bounded);
        value = bounded;
      } on ArgumentError {
        return;
      }
    }
    if (value == scale.target) {
      _status = MilestoneStatus.achieved;
    } else if (_status == MilestoneStatus.achieved ||
        (_status == MilestoneStatus.notStarted && value != scale.start)) {
      _status = MilestoneStatus.onTrack;
    }
  }

  late MilestoneStatus _status =
      widget.milestone?.status ?? MilestoneStatus.notStarted;
  late DateTime? _due = widget.milestone?.dueDate;
  bool _saving = false;
  late double _persistedProgress = widget.milestone?.currentValue ?? 0;
  late MilestoneStatus _persistedStatus =
      widget.milestone?.status ?? MilestoneStatus.notStarted;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refreshTodos);
  }

  void _refreshTodos() {
    final milestone = widget.milestone == null
        ? null
        : widget.controller.snapshot.milestone(widget.milestone!.id);
    setState(() {
      if (milestone != null &&
          (milestone.currentValue != _persistedProgress ||
              milestone.status != _persistedStatus)) {
        _persistedProgress = milestone.currentValue;
        _setCurrent(milestone.currentValue);
        _status = _persistedStatus = milestone.status;
      }
    });
  }

  Future<bool> _beforeTodoAction() async {
    if (_saving) return false;
    final saved = widget.controller.snapshot.milestone(widget.milestone!.id);
    if (saved != null &&
        saved.title == _title.text.trim() &&
        saved.currentValue == parseMetric(_current.text) &&
        saved.scale.start == parseMetric(_start.text) &&
        saved.scale.target == parseMetric(_target.text) &&
        saved.scale.unit == _unit.text.trim() &&
        saved.status == _status &&
        saved.dueDate == _due) {
      return true;
    }
    // Commit a manual progress draft before crediting a Todo. Otherwise saving
    // the editor later could overwrite the new contribution with a stale value.
    return _save(close: false);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refreshTodos);
    _title.dispose();
    for (final field in [_start, _target, _current, _unit]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<bool> _save({bool close = true}) async {
    if (_saving || !_form.currentState!.validate()) return false;
    setState(() => _saving = true);
    final saved = await runMutation(
      context,
      widget.controller,
      (r) => r.saveMilestone(
        id: widget.milestone?.id,
        goalId: widget.goal.id,
        title: _title.text,
        currentValue: parseMetric(_current.text),
        scale: _scale,
        status: _status,
        dueDate: _due,
      ),
    );
    if (!mounted) return false;
    if (saved && close) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
    return saved;
  }

  Widget _numberField(
    String label,
    String key,
    TextEditingController controller, {
    bool current = false,
  }) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    decoration: InputDecoration(
      labelText: label,
      errorMaxLines: 3,
      suffixText: !current || _unit.text.isEmpty ? null : _unit.text,
    ),
    onChanged: (_) => setState(() => _measurementChanged(clamp: !current)),
    validator: (text) {
      final value = parseMetric(text ?? '');
      try {
        if (value == null) throw ArgumentError();
        metricUnits(value);
      } on ArgumentError {
        return 'Zahl mit maximal 2 Nachkommastellen eingeben.';
      }
      final scale = _scale;
      if (scale == null) return 'Start und Ziel müssen verschieden sein.';
      if (current &&
          scale.clampUnits(metricUnits(value)) != metricUnits(value)) {
        return 'Wert muss zwischen Start und Ziel liegen.';
      }
      return null;
    },
  );

  Widget _measurementFields(BuildContext context) {
    final unit = DropdownButtonFormField<String>(
      key: ValueKey('metric-unit-$_customUnit'),
      initialValue: _customUnit ? '__custom' : _unit.text,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Einheit'),
      items: [
        for (final entry in _units.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        const DropdownMenuItem(
          value: '__custom',
          child: Text('Eigene Einheit'),
        ),
      ],
      onChanged: (value) => setState(() {
        _customUnit = value == '__custom';
        _unit.text = _customUnit ? '' : value!;
      }),
    );
    final current = _numberField(
      'Aktueller Wert',
      'metric-current',
      _current,
      current: true,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(16) > 22) {
              return Column(children: [unit, gap, current]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: unit),
                const SizedBox(width: 12),
                Expanded(child: current),
              ],
            );
          },
        ),
        if (_customUnit) ...[
          gap,
          TextFormField(
            key: const ValueKey('metric-custom-unit'),
            controller: _unit,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'Eigene Einheit',
              hintText: 'z. B. Gläser',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        gap,
        LayoutBuilder(
          builder: (context, constraints) {
            final start = _numberField('Startwert', 'metric-start', _start);
            final target = _numberField('Zielwert', 'metric-target', _target);
            final slider = MeasurementSlider(
              progress: _progress,
              valueLabel: formatProgress(parseMetric(_current.text) ?? 0),
              onChanged: _scale == null
                  ? null
                  : (value) => setState(() {
                      _setCurrent(_scale!.valueForPercent(value));
                      _measurementChanged();
                    }),
            );
            if (constraints.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(16) > 22) {
              return Column(children: [start, slider, target]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 92, child: start),
                Expanded(child: slider),
                SizedBox(width: 92, child: target),
              ],
            );
          },
        ),
        if (widget.milestone != null &&
            (_unit.text != widget.milestone!.scale.unit ||
                parseMetric(_start.text) != widget.milestone!.scale.start ||
                parseMetric(_target.text) != widget.milestone!.scale.target) &&
            widget.controller.snapshot.todoTemplates.any(
              (t) => t.active && t.milestoneId == widget.milestone!.id,
            ))
          const Text(
            'Todo-Beiträge verwenden diese Einheit. Bei einer Änderung der Einheit bleiben die Zahlenwerte erhalten.',
          ),
      ],
    );
  }

  Widget _statusAndDue(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final status = DropdownButtonFormField<MilestoneStatus>(
        key: ValueKey(_status),
        initialValue: _status,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Status'),
        items: MilestoneStatus.values
            .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
            .toList(),
        onChanged: (s) {
          if (s == null) return;
          setState(() {
            _status = s;
            if (s == MilestoneStatus.achieved) {
              _setCurrent(_scale?.target ?? 100);
            } else if (s == MilestoneStatus.notStarted) {
              _setCurrent(_scale?.start ?? 0);
            } else if (_progress == 100) {
              _setCurrent(_scale?.valueForPercent(99) ?? 99);
            }
          });
        },
      );
      final due = DueDateField(
        value: _due,
        compact: true,
        onChanged: (date) => setState(() => _due = date),
      );
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(children: [status, gap, due]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: status),
          const SizedBox(width: 12),
          Expanded(child: due),
        ],
      );
    },
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.milestone == null
            ? 'Neues Zwischenziel'
            : 'Zwischenziel bearbeiten',
      ),
    ),
    body: Form(
      key: _form,
      child: SingleChildScrollView(
        padding: pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.goal.emoji} ${widget.goal.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            gap,
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titel'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Bitte einen Titel eingeben.'
                  : null,
            ),
            gap,
            _statusAndDue(context),
            gap,
            _measurementFields(context),
            gap,
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Wird gespeichert …' : 'Speichern'),
            ),
            if (widget.milestone == null) ...[
              gap,
              const Text('Speichere das Zwischenziel, um Todos hinzuzufügen.'),
            ],
            if (widget.milestone != null) ...[
              gap,
              Text(
                'Verknüpfte Todos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Todo-Aktionen speichern auch deine Änderungen am Zwischenziel.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final frequency in TodoFrequency.values)
                TodoGroup(
                  controller: widget.controller,
                  frequency: frequency,
                  milestoneId: widget.milestone!.id,
                  beforeAction: _beforeTodoAction,
                  previewScale:
                      _scale ??
                      MetricScale(
                        start: widget.milestone!.scale.start,
                        target: widget.milestone!.scale.target,
                        unit: _unit.text.trim(),
                      ),
                ),
              gap,
              TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!await confirmDeletion(
                          context,
                          'Dieses Zwischenziel wird gelöscht. Der Zielfortschritt wird neu berechnet.',
                        )) {
                          return;
                        }
                        if (!context.mounted) return;
                        setState(() => _saving = true);
                        final saved = await runMutation(
                          context,
                          widget.controller,
                          (r) => r.deleteMilestone(
                            widget.milestone!.id,
                            widget.goal.id,
                          ),
                        );
                        if (!context.mounted) return;
                        if (saved) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _saving = false);
                        }
                      },
                child: const Text('Zwischenziel löschen'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
