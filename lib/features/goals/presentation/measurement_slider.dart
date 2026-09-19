import 'package:flutter/material.dart';

/// Keeps the measurement visible above the thumb, including while idle.
class MeasurementSlider extends StatelessWidget {
  const MeasurementSlider({
    super.key,
    required this.progress,
    required this.valueLabel,
    required this.onChanged,
  });

  final double progress;
  final String valueLabel;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = Theme.of(context).textTheme.labelLarge!;
      final painter = TextPainter(
        text: TextSpan(text: valueLabel, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final width = (painter.width + 12).clamp(0.0, constraints.maxWidth);
      final labelHeight = painter.height + 8;
      final fraction = Directionality.of(context) == TextDirection.rtl
          ? 1 - progress / 100
          : progress / 100;
      final center = 16 + (constraints.maxWidth - 32) * fraction;
      painter.dispose();
      return Column(
        children: [
          SizedBox(
            height: labelHeight,
            child: Stack(
              children: [
                Positioned(
                  left: (center - width / 2).clamp(
                    0.0,
                    constraints.maxWidth - width,
                  ),
                  width: width,
                  child: ExcludeSemantics(
                    child: Text(
                      valueLabel,
                      key: const ValueKey('metric-slider-value'),
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              showValueIndicator: ShowValueIndicator.never,
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              key: const ValueKey('metric-slider'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              value: progress,
              min: 0,
              max: 100,
              semanticFormatterCallback: (_) => valueLabel,
              onChanged: onChanged,
            ),
          ),
        ],
      );
    },
  );
}
