import 'progress_amount.dart';

/// Measurement values use integer hundredths, independent of normalized percent.
const maxMetricValue = 1000000000.0;
int metricUnits(num value) {
  if (!value.isFinite ||
      value.abs() > maxMetricValue ||
      (value * 100 - (value * 100).round()).abs() > .00001) {
    throw ArgumentError.value(value, 'value', 'Expected at most two decimals');
  }
  return (value * 100).round();
}

double? parseMetric(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

class MetricScale {
  const MetricScale({this.start = 0, this.target = 100, this.unit = '%'});
  final double start;
  final double target;
  final String unit;
  bool get descending => target < start;
  bool get isStandardPercent => start == 0 && target == 100 && unit == '%';
  int get startUnits => metricUnits(start);
  int get targetUnits => metricUnits(target);
  int get direction => descending ? -1 : 1;
  double get span => (target - start).abs();
  void validate() {
    metricUnits(start);
    metricUnits(target);
    if (start == target || span > maxMetricValue || unit.trim().length > 30) {
      throw ArgumentError(
        'Start und Ziel müssen verschieden sein; Einheit maximal 30 Zeichen.',
      );
    }
  }

  int clampUnits(int value) => value.clamp(
    descending ? targetUnits : startUnits,
    descending ? startUnits : targetUnits,
  );
  double percent(num value) {
    final current = metricUnits(value);
    final fraction = (current - startUnits) / (targetUnits - startUnits);
    // Incomplete measurements must never become "achieved" through rounding.
    if (current == targetUnits) return 100;
    if (current == startUnits) return 0;
    return ((fraction * 10000).round().clamp(1, 9999)) / 100;
  }

  double valueForPercent(num progress) =>
      (startUnits + ((targetUnits - startUnits) * progress / 100).round()) /
      100;
  String format(num value) =>
      '${formatProgress(value)}${unit.isEmpty ? '' : ' $unit'}';
  String contribution(num amount) =>
      '${descending ? '−' : '+'}${format(amount)}';
}
