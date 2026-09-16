enum TodoFrequency {
  daily('Täglich'),
  weekly('Wöchentlich');

  const TodoFrequency(this.label);
  final String label;
}

String calendarDate(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

String periodStart(TodoFrequency frequency, DateTime now) {
  final day = DateTime.utc(now.year, now.month, now.day);
  return calendarDate(
    frequency == TodoFrequency.daily
        ? day
        : day.subtract(Duration(days: day.weekday - DateTime.monday)),
  );
}

class TodoTemplate {
  const TodoTemplate({
    required this.id,
    required this.title,
    required this.frequency,
    required this.target,
    required this.active,
  });
  final int id;
  final String title;
  final TodoFrequency frequency;
  final int target;
  final bool active;
}

/// A period owns its title and target, independent of later template edits.
class TodoEntry {
  const TodoEntry({
    required this.templateId,
    required this.period,
    required this.title,
    required this.frequency,
    required this.target,
    required this.completed,
  });
  final int templateId;
  final String period;
  final String title;
  final TodoFrequency frequency;
  final int target;
  final int completed;
  bool isCurrent(DateTime now) => period == periodStart(frequency, now);
}
