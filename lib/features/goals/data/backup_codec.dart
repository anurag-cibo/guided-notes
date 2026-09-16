import 'dart:convert';

import '../domain/models.dart';

/// Portable, versioned backup, independent of the SQLite schema.
class BackupCodec {
  static const maxBytes = 10 * 1024 * 1024;

  static String encode(GoalSnapshot snapshot) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': 'the-guide',
        'version': 1,
        'goals': [
          for (final g in snapshot.goals)
            {
              'id': g.id,
              'title': g.title,
              'emoji': g.emoji,
              'motivation': g.motivation,
              'dueDate': date(g.dueDate),
              'achieved': g.achieved,
              'archived': g.archived,
            },
        ],
        'milestones': [
          for (final m in snapshot.milestones)
            {
              'id': m.id,
              'goalId': m.goalId,
              'title': m.title,
              'progress': m.progress,
              'status': m.status.name,
              'dueDate': date(m.dueDate),
            },
        ],
      });

  static String? date(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static GoalSnapshot decode(String source) {
    try {
      if (utf8.encode(source).length > maxBytes) throw const FormatException();
      final root = jsonDecode(source) as Map<String, dynamic>;
      if (root['format'] != 'the-guide' ||
          root['version'] is! int ||
          root['version'] != 1) {
        throw const FormatException();
      }
      final goals = (root['goals'] as List).map((value) {
        final g = value as Map<String, dynamic>;
        return Goal(
          id: _id(g['id']),
          title: _title(g['title']),
          emoji: g['emoji'] as String,
          motivation: g['motivation'] as String,
          dueDate: _date(g['dueDate']),
          achieved: g['achieved'] as bool,
          archived: g['archived'] as bool,
        );
      }).toList();
      final ids = goals.map((g) => g.id).toSet();
      if (ids.length != goals.length ||
          goals.where((g) => !g.archived).length > 5) {
        throw const FormatException();
      }
      final milestones = (root['milestones'] as List).map((value) {
        final m = value as Map<String, dynamic>;
        final progress = m['progress'] as int;
        final status = MilestoneStatus.values.byName(m['status'] as String);
        if (progress < 0 ||
            progress > 100 ||
            (status == MilestoneStatus.achieved) != (progress == 100) ||
            (status == MilestoneStatus.notStarted && progress != 0) ||
            !ids.contains(m['goalId'])) {
          throw const FormatException();
        }
        return Milestone(
          id: _id(m['id']),
          goalId: _id(m['goalId']),
          title: _title(m['title']),
          progress: progress,
          status: status,
          dueDate: _date(m['dueDate']),
        );
      }).toList();
      if (milestones.map((m) => m.id).toSet().length != milestones.length) {
        throw const FormatException();
      }
      return GoalSnapshot(goals, milestones);
    } catch (_) {
      throw const RuleViolation(
        'Diese Datei ist keine gültige, unterstützte The-Guide-Sicherung (Version 1, höchstens 10 MB).',
      );
    }
  }

  static int _id(dynamic value) {
    if (value is! int || value <= 0 || value >= 9223372036854775807) {
      throw const FormatException();
    }
    return value;
  }

  static String _title(dynamic value) {
    if (value is! String || value.trim().isEmpty) throw const FormatException();
    return value;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException();
    }
    final parsed = DateTime.parse(value);
    if (date(parsed) != value || parsed.year < 1900 || parsed.year > 2200) {
      throw const FormatException();
    }
    return parsed;
  }
}
