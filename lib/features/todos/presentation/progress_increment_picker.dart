import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../goals/domain/progress_amount.dart';

class ProgressIncrementPicker extends StatefulWidget {
  const ProgressIncrementPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final double value;
  final ValueChanged<double>? onChanged;
  @override
  State<ProgressIncrementPicker> createState() =>
      _ProgressIncrementPickerState();
}

class _ProgressIncrementPickerState extends State<ProgressIncrementPicker> {
  late int _units = progressUnits(widget.value);
  int get _whole => _units ~/ 100;
  int get _fraction => _units % 100;

  @override
  void didUpdateWidget(covariant ProgressIncrementPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _units = progressUnits(widget.value);
  }

  List<int> get _fractions {
    final values = progressFractions(_whole);
    // Preserve an imported contribution even if it is outside the UI presets.
    if (!values.contains(_fraction)) values.add(_fraction);
    return values..sort();
  }

  void _changeWhole(int whole) {
    final options = progressFractions(whole);
    final fraction = options.reduce(
      (a, b) => (a - _fraction).abs() <= (b - _fraction).abs() ? a : b,
    );
    setState(() => _units = whole * 100 + fraction);
    widget.onChanged?.call(progressPercent(_units));
  }

  @override
  Widget build(BuildContext context) {
    final fractions = _fractions;
    final height = MediaQuery.textScalerOf(context).scale(24) + 16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fortschrittsbeitrag'),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 300,
            child: IgnorePointer(
              ignoring: widget.onChanged == null,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _NumberWheel(
                        key: const ValueKey('progress-whole'),
                        labels: [for (var i = 0; i <= 100; i++) '$i'],
                        selected: _whole,
                        itemHeight: height,
                        onChanged: widget.onChanged == null
                            ? null
                            : _changeWhole,
                      ),
                    ),
                    const Text(','),
                    Expanded(
                      flex: 2,
                      child: _NumberWheel(
                        key: ValueKey('progress-fraction-$_whole'),
                        labels: [
                          for (final f in fractions)
                            f % 10 == 0
                                ? '${f ~/ 10}'
                                : f.toString().padLeft(2, '0'),
                        ],
                        selected: fractions.indexOf(_fraction),
                        itemHeight: height,
                        onChanged: widget.onChanged == null
                            ? null
                            : (index) {
                                setState(
                                  () =>
                                      _units = _whole * 100 + fractions[index],
                                );
                                widget.onChanged?.call(progressPercent(_units));
                              },
                      ),
                    ),
                    const Text(' %'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberWheel extends StatefulWidget {
  const _NumberWheel({
    super.key,
    required this.labels,
    required this.selected,
    required this.itemHeight,
    required this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final double itemHeight;
  final ValueChanged<int>? onChanged;
  @override
  State<_NumberWheel> createState() => _NumberWheelState();
}

class _NumberWheelState extends State<_NumberWheel> {
  late final _scroll = FixedExtentScrollController(
    initialItem: widget.selected,
  );
  @override
  void didUpdateWidget(covariant _NumberWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected &&
        _scroll.hasClients &&
        _scroll.selectedItem != widget.selected) {
      _scroll.jumpToItem(widget.selected);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.itemHeight * 3,
    child: CupertinoPicker.builder(
      scrollController: _scroll,
      itemExtent: widget.itemHeight,
      onSelectedItemChanged: widget.onChanged,
      childCount: widget.labels.length,
      itemBuilder: (context, index) => Center(
        child: Text(
          widget.labels[index],
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  );
}
