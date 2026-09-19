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
        'version': 11,
        'todoCredits': [
          for (final c in snapshot.todoCredits)
            {
              'templateId': c.templateId,
              'period': c.period,
              'ordinal': c.ordinal,
              'milestoneId': c.milestoneId,
              'amount': c.amount,
              'previousStatus': c.previousStatus,
              'valueAmount': c.valueAmount,
            },
        ],
        'customThemes': [
          for (final t in snapshot.customThemes)
            {
              'id': t.id,
              'name': t.name,
              'primary': t.colors.primary,
              'secondary': t.colors.secondary,
              'accent': t.colors.accent,
              'surface': t.colors.surface,
            },
        ],
        'todoTemplates': [
          for (final t in snapshot.todoTemplates)
            {
              'id': t.id,
              'title': t.title,
              'frequency': t.frequency.name,
              'target': t.target,
              'active': t.active,
              'milestoneId': t.milestoneId,
              'progressIncrement': t.progressIncrement,
              'progressMode': t.progressMode.name,
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
              'milestoneId': e.milestoneId,
              'progressIncrement': e.progressIncrement,
              'progressMode': e.progressMode.name,
            },
        ],
        'goals': [
          for (final g in snapshot.goals)
            {
              'id': g.id,
              'title': g.title,
              'emoji': g.emoji,
              'color': g.color.name,
              'customThemeId': g.customThemeId,
              'motivation': g.motivation,
              'dueDate': date(g.dueDate),
              'startedOn': date(g.startedOn),
              'achieved': g.achieved,
              'archived': g.archived,
              'showCardCover': g.showCardCover,
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
              'motivation': m.motivation,
              'startValue': m.scale.start,
              'targetValue': m.scale.target,
              'currentValue': m.currentValue,
              'unit': m.scale.unit,
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
          ![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].contains(root['version'])) {
        throw const FormatException();
      }
      final themes = <CustomGoalTheme>[];
      if (root['version'] >= 5) {
        for (final value in root['customThemes'] as List) {
          final t = value as Map<String, dynamic>;
          final colors = ThemeColors(
            primary: t['primary'] as int,
            secondary: t['secondary'] as int,
            accent: t['accent'] as int,
            surface: t['surface'] as int,
          );
          if (!colors.isValid) throw const FormatException();
          themes.add(
            CustomGoalTheme(
              id: _id(t['id']),
              name: _title(t['name']),
              colors: colors,
            ),
          );
        }
      }
      final themeIds = themes.map((t) => t.id).toSet();
      if (themeIds.length != themes.length) throw const FormatException();
      final goals = (root['goals'] as List).map((value) {
        final g = value as Map<String, dynamic>;
        final themeId = root['version'] >= 5 && g['customThemeId'] != null
            ? _id(g['customThemeId'])
            : null;
        if (themeId != null && !themeIds.contains(themeId)) {
          throw const FormatException();
        }
        return Goal(
          id: _id(g['id']),
          title: _title(g['title']),
          customThemeId: themeId,
          emoji: g['emoji'] as String,
          motivation: g['motivation'] as String,
          dueDate: _date(g['dueDate']),
          startedOn: root['version'] >= 6 ? _date(g['startedOn']) : null,
          achieved: g['achieved'] as bool,
          archived: g['archived'] as bool,
          showCardCover: root['version'] >= 9
              ? g['showCardCover'] as bool
              : true,
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
        final progress = _percent(m['progress']);
        final status = MilestoneStatus.values.byName(m['status'] as String);
        if (progress < 0 ||
            progress > 100 ||
            (status == MilestoneStatus.achieved) != (progress == 100) ||
            (status == MilestoneStatus.notStarted && progress != 0) ||
            !ids.contains(m['goalId'])) {
          throw const FormatException();
        }
        final scale = root['version'] >= 11
            ? MetricScale(
                start: _metric(m['startValue']),
                target: _metric(m['targetValue']),
                unit: m['unit'] as String,
              )
            : const MetricScale();
        scale.validate();
        final current = root['version'] >= 11
            ? _metric(m['currentValue'])
            : progress;
        if (scale.clampUnits(metricUnits(current)) != metricUnits(current) ||
            scale.percent(current) != progress) {
          throw const FormatException();
        }
        return Milestone(
          motivation: root['version'] >= 11 ? m['motivation'] as String : '',
          scale: scale,
          currentValue: current,
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
      final milestoneIds = milestones.map((m) => m.id).toSet();
      int? linkId(Map<String, dynamic> value) {
        if (root['version'] < 7 || value['milestoneId'] == null) return null;
        final id = _id(value['milestoneId']);
        if (!milestoneIds.contains(id)) throw const FormatException();
        return id;
      }

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
              milestoneId: linkId(t),
              progressMode: _mode(t, root['version'] as int, frequency),
              progressIncrement: root['version'] >= 7
                  ? _increment(t['progressIncrement'], root['version'] as int)
                  : 0,
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
              milestoneId: linkId(e),
              progressMode: _mode(e, root['version'] as int, frequency),
              progressIncrement: root['version'] >= 7
                  ? _increment(e['progressIncrement'], root['version'] as int)
                  : 0,
            ),
          );
        }
      }
      final credits = <TodoProgressCredit>[];
      if (root['version'] >= 7) {
        final keys = <String>{};
        final byPeriod = {
          for (final e in entries) '${e.templateId}/${e.period}': e,
        };
        for (final value in root['todoCredits'] as List) {
          final c = value as Map<String, dynamic>;
          final id = _id(c['templateId']);
          final period = date(_date(c['period']));
          final ordinal = _id(c['ordinal']);
          final entry = byPeriod['$id/$period'];
          if (entry == null ||
              ordinal > entry.completed ||
              !keys.add('$id/$period/$ordinal')) {
            throw const FormatException();
          }
          credits.add(
            TodoProgressCredit(
              templateId: id,
              period: period!,
              ordinal: ordinal,
              milestoneId: linkId(c),
              amount: _percent(c['amount']),
              valueAmount: root['version'] >= 11
                  ? _metric(c['valueAmount'])
                  : _percent(c['amount']),
              previousStatus: MilestoneStatus.values
                  .byName(c['previousStatus'] as String)
                  .name,
            ),
          );
        }
      }
      return GoalSnapshot(
        goals,
        milestones,
        todoTemplates: templates,
        todoEntries: entries,
        customThemes: themes,
        todoCredits: credits,
      );
    } catch (_) {
      throw const RuleViolation(
        'Diese Datei ist keine gültige, unterstützte The-Guide-Sicherung (Version 1–11, höchstens 10 MB).',
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

  static double _metric(dynamic value) {
    if (value is! num) throw const FormatException();
    return metricUnits(value) / 100;
  }

  static double _increment(dynamic value, int version) {
    final number = version < 11 ? _percent(value) : _metric(value);
    if (number < 0) throw const FormatException();
    return number;
  }

  static double _percent(dynamic value) {
    if (value is! num || !value.isFinite || value < 0 || value > 100) {
      throw const FormatException();
    }
    return progressPercent(progressUnits(value));
  }

  static TodoProgressMode _mode(
    Map<String, dynamic> value,
    int version,
    TodoFrequency frequency,
  ) {
    final mode = version < 8
        ? TodoProgressMode.perCompletion
        : TodoProgressMode.values.byName(value['progressMode'] as String);
    if (frequency == TodoFrequency.daily &&
        mode != TodoProgressMode.perCompletion) {
      throw const FormatException();
    }
    return mode;
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
