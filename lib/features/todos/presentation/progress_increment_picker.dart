import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A bounded wheel: the selected number is the contribution per completion.
class ProgressIncrementPicker extends StatefulWidget {
  const ProgressIncrementPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int>? onChanged;

  @override
  State<ProgressIncrementPicker> createState() =>
      _ProgressIncrementPickerState();
}

class _ProgressIncrementPickerState extends State<ProgressIncrementPicker> {
  late final _scroll = FixedExtentScrollController(
    initialItem: widget.value - 1,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemHeight = MediaQuery.textScalerOf(context).scale(24) + 16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prozentpunkte pro Erledigung'),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 180,
            height: itemHeight * 3,
            child: IgnorePointer(
              ignoring: widget.onChanged == null,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                ),
                child: CupertinoPicker.builder(
                  scrollController: _scroll,
                  itemExtent: itemHeight,
                  onSelectedItemChanged: (index) =>
                      widget.onChanged?.call(index + 1),
                  childCount: 100,
                  itemBuilder: (context, index) => Center(
                    child: Text(
                      '${index + 1} %',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
