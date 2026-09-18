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
    this.milestoneId,
    this.progressIncrement = 0,
  });
  final int id;
  final String title;
  final TodoFrequency frequency;
  final int target;
  final bool active;
  final int? milestoneId;
  final int progressIncrement;
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
    this.milestoneId,
    this.progressIncrement = 0,
  });
  final int templateId;
  final String period;
  final String title;
  final TodoFrequency frequency;
  final int target;
  final int completed;
  final int? milestoneId;
  final int progressIncrement;
  bool isCurrent(DateTime now) => period == periodStart(frequency, now);
}

/// Actual contribution of a single completion, used for exact undo after edits.
class TodoProgressCredit {
  const TodoProgressCredit({
    required this.templateId,
    required this.period,
    required this.ordinal,
    required this.milestoneId,
    required this.amount,
    required this.previousStatus,
  });
  final int templateId;
  final String period;
  final int ordinal;
  final int? milestoneId;
  final int amount;
  final String previousStatus;
}
