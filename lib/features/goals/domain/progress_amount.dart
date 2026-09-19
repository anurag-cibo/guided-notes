/// Persist and calculate percentages as integer hundredths (100 % = 10000).
int progressUnits(num value) {
  if (!value.isFinite ||
      value < 0 ||
      value > 100 ||
      (value * 100 - (value * 100).round()).abs() > 0.000001) {
    throw ArgumentError.value(
      value,
      'progress',
      'Expected 0–100 with at most two decimals',
    );
  }
  return (value * 100).round();
}

double progressPercent(int units) => units / 100;

String formatProgress(num value) => value
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

List<int> progressFractions(int whole) => switch (whole) {
  0 => [10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90],
  1 => [0, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90],
  2 => [0, 20, 40, 50, 60, 80],
  3 => [0, 25, 50, 75],
  4 => [0, 50],
  _ => [0],
};
