import 'dart:convert';
import 'dart:typed_data';

import 'cover_image.dart';

import '../domain/models.dart';
import '../../todos/domain/todo_models.dart';

/// Portable, versioned backup, independent of the SQLite schema.
class BackupCodec {
  static const maxBytes = 10 * 1024 * 1024;

  static String encode(GoalSnapshot snapshot) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': 'the-guide',
        'version': 4,
        'todoTemplates': [
          for (final t in snapshot.todoTemplates)
            {
              'id': t.id,
              'title': t.title,
              'frequency': t.frequency.name,
              'target': t.target,
              'active': t.active,
            },
        ],
        'todoEntries': [
          for (final e in snapshot.todoEntries)
            {
              'templateId': e.templateId,
              'period': e.period,
              'title': e.title,
              'frequency': e.frequency.name,
              'target': e.target,
              'completed': e.completed,
            },
        ],
        'goals': [
          for (final g in snapshot.goals)
            {
              'id': g.id,
              'title': g.title,
              'emoji': g.emoji,
              'color': g.color.name,
              'motivation': g.motivation,
              'dueDate': date(g.dueDate),
              'achieved': g.achieved,
              'archived': g.archived,
              'coverImage': g.coverImage == null
                  ? null
                  : base64Encode(g.coverImage!),
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
          ![1, 2, 3, 4].contains(root['version'])) {
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
          coverImage: root['version'] >= 3 ? _cover(g['coverImage']) : null,
          color: root['version'] >= 4
              ? GoalColor.values.byName(g['color'] as String)
              : GoalColor.forest,
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
      final templates = <TodoTemplate>[];
      final entries = <TodoEntry>[];
      if (root['version'] >= 2) {
        for (final value in root['todoTemplates'] as List) {
          final t = value as Map<String, dynamic>;
          final frequency = TodoFrequency.values.byName(
            t['frequency'] as String,
          );
          templates.add(
            TodoTemplate(
              id: _id(t['id']),
              title: _title(t['title']),
              frequency: frequency,
              target: _target(t['target'], frequency),
              active: t['active'] as bool,
            ),
          );
        }
        final byId = {for (final t in templates) t.id: t};
        if (byId.length != templates.length) throw const FormatException();
        final keys = <String>{};
        for (final value in root['todoEntries'] as List) {
          final e = value as Map<String, dynamic>;
          final id = _id(e['templateId']);
          final frequency = TodoFrequency.values.byName(
            e['frequency'] as String,
          );
          final period = _date(e['period']);
          final target = _target(e['target'], frequency);
          final completed = e['completed'] as int;
          if (period == null ||
              periodStart(frequency, period) != e['period'] ||
              byId[id]?.frequency != frequency ||
              completed < 0 ||
              completed > target ||
              !keys.add('$id/${e['period']}')) {
            throw const FormatException();
          }
          entries.add(
            TodoEntry(
              templateId: id,
              period: e['period'] as String,
              title: _title(e['title']),
              frequency: frequency,
              target: target,
              completed: completed,
            ),
          );
        }
      }
      return GoalSnapshot(
        goals,
        milestones,
        todoTemplates: templates,
        todoEntries: entries,
      );
    } catch (_) {
      throw const RuleViolation(
        'Diese Datei ist keine gültige, unterstützte The-Guide-Sicherung (Version 1–4, höchstens 10 MB).',
      );
    }
  }

  static Uint8List? _cover(dynamic value) {
    if (value == null) return null;
    if (value is! String ||
        value.length > (CoverImages.maxBytes * 4 / 3).ceil() + 4) {
      throw const FormatException();
    }
    final bytes = base64Decode(value);
    if (bytes.isEmpty || bytes.length > CoverImages.maxBytes) {
      throw const FormatException();
    }
    return bytes;
  }

  static int _target(dynamic value, TodoFrequency frequency) {
    if (value is! int ||
        value < 1 ||
        value > 999 ||
        (frequency == TodoFrequency.daily && value != 1)) {
      throw const FormatException();
    }
    return value;
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
