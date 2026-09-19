import 'dart:typed_data';

import '../../todos/domain/todo_models.dart';
import 'theme_colors.dart';
import 'progress_amount.dart';
import 'metric_scale.dart';
export 'metric_scale.dart';
export 'progress_amount.dart';
export 'theme_colors.dart';

enum MilestoneStatus {
  notStarted('Noch nicht begonnen'),
  onTrack('Im Plan'),
  offTrack('Außer Plan'),
  onHold('Pausiert'),
  achieved('Erreicht');

  const MilestoneStatus(this.label);
  final String label;
}

enum GoalColor {
  forest('Wald'),
  ocean('Ozean'),
  lavender('Lavendel'),
  rose('Rose'),
  amber('Sonne');

  const GoalColor(this.label);
  final String label;
}

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.emoji = '◎',
    this.motivation = '',
    this.dueDate,
    this.startedOn,
    this.achieved = false,
    this.archived = false,
    this.coverImage,
    this.showCardCover = true,
    this.color = GoalColor.forest,
    this.customThemeId,
  });
  final int id;
  final String title;
  final String emoji;
  final String motivation;
  final DateTime? dueDate;
  final DateTime? startedOn;
  final bool achieved;
  final bool archived;
  final Uint8List? coverImage;
  final bool showCardCover;
  final GoalColor color;
  final int? customThemeId;
}

class Milestone {
  const Milestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.progress = 0,
    this.status = MilestoneStatus.notStarted,
    this.dueDate,
    this.motivation = '',
    this.scale = const MetricScale(),
    double? currentValue,
    // Public argument keeps legacy percent-only model construction compatible.
    // ignore: prefer_initializing_formals
  }) : _currentValue = currentValue;
  final int id;
  final int goalId;
  final String title;
  final double progress;
  final MilestoneStatus status;
  final DateTime? dueDate;
  final String motivation;
  final MetricScale scale;
  final double? _currentValue;
  double get currentValue => _currentValue ?? scale.valueForPercent(progress);
  String get measurementLabel => scale.isStandardPercent
      ? scale.format(currentValue)
      : '${formatProgress(currentValue)} / ${scale.format(scale.target)}';
}

class GoalSnapshot {
  GoalSnapshot(
    Iterable<Goal> goals,
    Iterable<Milestone> milestones, {
    Iterable<TodoTemplate> todoTemplates = const [],
    Iterable<TodoEntry> todoEntries = const [],
    Iterable<CustomGoalTheme> customThemes = const [],
    Iterable<TodoProgressCredit> todoCredits = const [],
  }) : goals = List.unmodifiable(goals),
       milestones = List.unmodifiable(milestones),
       todoTemplates = List.unmodifiable(todoTemplates),
       todoEntries = List.unmodifiable(todoEntries),
       customThemes = List.unmodifiable(customThemes),
       todoCredits = List.unmodifiable(todoCredits);
  final List<TodoProgressCredit> todoCredits;
  final List<CustomGoalTheme> customThemes;
  CustomGoalTheme? theme(int? id) =>
      customThemes.where((t) => t.id == id).firstOrNull;
  final List<Goal> goals;
  final List<Milestone> milestones;
  final List<TodoTemplate> todoTemplates;
  final List<TodoEntry> todoEntries;
  late final _goalsById = {for (final goal in goals) goal.id: goal};
  late final _milestonesById = {
    for (final milestone in milestones) milestone.id: milestone,
  };
  late final _todoTemplatesById = {
    for (final template in todoTemplates) template.id: template,
  };

  Milestone? milestone(int id) => _milestonesById[id];
  TodoTemplate? todoTemplate(int id) => _todoTemplatesById[id];
  bool get isEmpty =>
      goals.isEmpty &&
      milestones.isEmpty &&
      todoTemplates.isEmpty &&
      todoEntries.isEmpty &&
      customThemes.isEmpty;
  List<Goal> get activeGoals => goals.where((g) => !g.archived).toList();
  List<Milestone> forGoal(int id) =>
      milestones.where((m) => m.goalId == id).toList();
  Goal? goal(int id) => _goalsById[id];

  double? progressFor(int id) {
    final entries = forGoal(id);
    if (entries.isEmpty) return null;
    return (entries.fold<double>(0, (sum, m) => sum + m.progress) /
                entries.length *
                100)
            .round() /
        100;
  }
}

class RuleViolation implements Exception {
  const RuleViolation(this.message);
  final String message;
  @override
  String toString() => message;
}

String requiredTitle(String value) {
  final title = value.trim();
  if (title.isEmpty) throw const RuleViolation('Bitte einen Titel eingeben.');
  return title;
}

({double progress, MilestoneStatus status}) normalizeProgress(
  num progress,
  MilestoneStatus status,
) {
  if (!progress.isFinite || progress < 0 || progress > 100) {
    throw const RuleViolation('Fortschritt muss zwischen 0 und 100 liegen.');
  }
  if (status == MilestoneStatus.achieved || progress == 100) {
    return (progress: 100, status: MilestoneStatus.achieved);
  }
  if (status == MilestoneStatus.notStarted && progress > 0) {
    return (
      progress: progressPercent(progressUnits(progress)),
      status: MilestoneStatus.onTrack,
    );
  }
  return (progress: progressPercent(progressUnits(progress)), status: status);
}

String deadlineLabel(DateTime? due, {bool achieved = false, DateTime? now}) {
  if (achieved) return 'Erreicht';
  if (due == null) return 'Ohne Frist';
  final today = now ?? DateTime.now();
  final days = DateTime.utc(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  if (days == 0) return 'Heute fällig';
  if (days == 1) return 'Noch 1 Tag';
  if (days > 1) return 'Noch $days Tage';
  if (days == -1) return '1 Tag überfällig';
  return '${-days} Tage überfällig';
}
