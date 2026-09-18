import 'dart:typed_data';

import '../../todos/domain/todo_models.dart';
import 'theme_colors.dart';
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
  });
  final int id;
  final int goalId;
  final String title;
  final int progress;
  final MilestoneStatus status;
  final DateTime? dueDate;
}

class GoalSnapshot {
  GoalSnapshot(
    Iterable<Goal> goals,
    Iterable<Milestone> milestones, {
    Iterable<TodoTemplate> todoTemplates = const [],
    Iterable<TodoEntry> todoEntries = const [],
    Iterable<CustomGoalTheme> customThemes = const [],
  }) : goals = List.unmodifiable(goals),
       milestones = List.unmodifiable(milestones),
       todoTemplates = List.unmodifiable(todoTemplates),
       todoEntries = List.unmodifiable(todoEntries),
       customThemes = List.unmodifiable(customThemes);
  final List<CustomGoalTheme> customThemes;
  CustomGoalTheme? theme(int? id) =>
      customThemes.where((t) => t.id == id).firstOrNull;
  final List<Goal> goals;
  final List<Milestone> milestones;
  final List<TodoTemplate> todoTemplates;
  final List<TodoEntry> todoEntries;
  bool get isEmpty =>
      goals.isEmpty &&
      milestones.isEmpty &&
      todoTemplates.isEmpty &&
      todoEntries.isEmpty &&
      customThemes.isEmpty;
  List<Goal> get activeGoals => goals.where((g) => !g.archived).toList();
  List<Milestone> forGoal(int id) =>
      milestones.where((m) => m.goalId == id).toList();
  Goal? goal(int id) {
    for (final goal in goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  int? progressFor(int id) {
    final entries = forGoal(id);
    if (entries.isEmpty) return null;
    return (entries.fold<int>(0, (sum, m) => sum + m.progress) / entries.length)
        .round();
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

({int progress, MilestoneStatus status}) normalizeProgress(
  int progress,
  MilestoneStatus status,
) {
  if (progress < 0 || progress > 100) {
    throw const RuleViolation('Fortschritt muss zwischen 0 und 100 liegen.');
  }
  if (status == MilestoneStatus.achieved || progress == 100) {
    return (progress: 100, status: MilestoneStatus.achieved);
  }
  if (status == MilestoneStatus.notStarted && progress > 0) {
    return (progress: progress, status: MilestoneStatus.onTrack);
  }
  return (progress: progress, status: status);
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
