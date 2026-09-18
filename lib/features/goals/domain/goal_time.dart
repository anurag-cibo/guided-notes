import 'models.dart';

/// Local calendar days, independent of daylight-saving hour differences.
class GoalTime {
  GoalTime(Goal goal, DateTime now) {
    final due = goal.dueDate;
    if (due == null) return;
    final today = _day(now);
    remainingDays = _day(due).difference(today).inDays;
    final start = _day(goal.startedOn ?? now);
    final duration = _day(due).difference(start).inDays;
    elapsed = duration <= 0
        ? (remainingDays! <= 0 ? 1 : 0)
        : (today.difference(start).inDays / duration).clamp(0.0, 1.0);
  }

  int? remainingDays;
  double elapsed = 0;
  String get label => switch (remainingDays) {
    null => 'Ohne\nFrist',
    0 => 'Heute\nfällig',
    1 => '1 Tag\nübrig',
    final int days when days > 1 => '$days Tage\nübrig',
    -1 => '1 Tag\nüberfällig',
    final int days => '${-days} Tage\nüberfällig',
  };

  static DateTime _day(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}
