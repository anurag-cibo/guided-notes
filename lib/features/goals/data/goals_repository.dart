import 'package:drift/drift.dart';
import 'package:characters/characters.dart';

import '../../../data/app_database.dart';
import '../domain/models.dart';
import 'backup_codec.dart';
import 'cover_image.dart';
import '../../todos/data/todos_repository.dart';

class GoalsRepository {
  GoalsRepository(this.database, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final AppDatabase database;
  final DateTime Function() now;
  late final TodosRepository todos = TodosRepository(database, now);

  Future<void> deleteAllContents() => database.transaction(() async {
    await database.customStatement('DELETE FROM todo_entries');
    await database.customStatement('DELETE FROM todo_templates');
    await database.customStatement('DELETE FROM milestones');
    await database.customStatement('DELETE FROM goals');
    await database.customStatement('DELETE FROM goal_themes');
  });

  Future<String> exportBackup() async => BackupCodec.encode(await load());

  /// Import only into an empty store; validation and writes are all-or-nothing.
  Future<void> importBackup(String source) async {
    final snapshot = BackupCodec.decode(source);
    for (final goal in snapshot.goals) {
      if (goal.coverImage != null) await CoverImages.validate(goal.coverImage!);
    }
    await database.transaction(() async {
      final current = await load();
      if (!current.isEmpty) {
        throw const RuleViolation(
          'Wiederherstellen ist nur in einer leeren App möglich. Vorhandene Ziele, Todos, Archive und eigene Themes bleiben unverändert.',
        );
      }
      for (final t in snapshot.customThemes) {
        await database.customStatement(
          'INSERT INTO goal_themes(id,name,primary_color,secondary_color,accent_color,surface_color) VALUES(?,?,?,?,?,?)',
          [
            t.id,
            t.name,
            t.colors.primary,
            t.colors.secondary,
            t.colors.accent,
            t.colors.surface,
          ],
        );
      }
      for (final g in snapshot.goals) {
        await database.customStatement(
          'INSERT INTO goals(id,title,emoji,motivation,due_date,achieved,archived,cover_image,color,custom_theme_id,started_on) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
          [
            g.id,
            g.title,
            g.emoji,
            g.motivation,
            BackupCodec.date(g.dueDate),
            g.achieved ? 1 : 0,
            g.archived ? 1 : 0,
            g.coverImage,
            g.color.name,
            g.customThemeId,
            _encodeDate(g.startedOn ?? now()),
          ],
        );
      }
      for (final m in snapshot.milestones) {
        await database.customStatement(
          'INSERT INTO milestones(id,goal_id,title,progress,status,due_date) VALUES (?,?,?,?,?,?)',
          [
            m.id,
            m.goalId,
            m.title,
            m.progress,
            m.status.name,
            BackupCodec.date(m.dueDate),
          ],
        );
      }
      for (final t in snapshot.todoTemplates) {
        await database.customStatement(
          'INSERT INTO todo_templates(id,title,frequency,target,active,milestone_id,progress_increment) VALUES(?,?,?,?,?,?,?)',
          [
            t.id,
            t.title,
            t.frequency.name,
            t.target,
            t.active ? 1 : 0,
            t.milestoneId,
            t.progressIncrement,
          ],
        );
      }
      for (final e in snapshot.todoEntries) {
        await database.customStatement(
          'INSERT INTO todo_entries(template_id,period,title,frequency,target,completed,milestone_id,progress_increment) VALUES(?,?,?,?,?,?,?,?)',
          [
            e.templateId,
            e.period,
            e.title,
            e.frequency.name,
            e.target,
            e.completed,
            e.milestoneId,
            e.progressIncrement,
          ],
        );
      }
      for (final c in snapshot.todoCredits) {
        await database.customStatement(
          'INSERT INTO todo_progress_credits(template_id,period,ordinal,milestone_id,amount,previous_status) VALUES(?,?,?,?,?,?)',
          [
            c.templateId,
            c.period,
            c.ordinal,
            c.milestoneId,
            c.amount,
            c.previousStatus,
          ],
        );
      }
    });
  }

  Future<GoalSnapshot> load() => database.transaction(() async {
    // Older databases have no historical start date. Establish it once only.
    await database.customStatement(
      'UPDATE goals SET started_on = ? WHERE started_on IS NULL',
      [_encodeDate(now())],
    );
    await todos.ensureCurrentPeriods();
    final goals = await database
        .customSelect('SELECT * FROM goals ORDER BY id')
        .get();
    final milestones = await database
        .customSelect('SELECT * FROM milestones ORDER BY goal_id, id')
        .get();
    return GoalSnapshot(
      goals.map(_readGoal),
      milestones.map(
        (r) => Milestone(
          id: r.read<int>('id'),
          goalId: r.read<int>('goal_id'),
          title: r.read<String>('title'),
          progress: r.read<int>('progress'),
          status: MilestoneStatus.values.byName(r.read<String>('status')),
          dueDate: _date(r.readNullable<String>('due_date')),
        ),
      ),
      todoTemplates: await todos.templates(),
      todoEntries: await todos.entries(),
      todoCredits: await todos.progress.load(),
      customThemes: await _loadThemes(),
    );
  });

  Future<List<CustomGoalTheme>> _loadThemes() async => [
    for (final row
        in await database
            .customSelect('SELECT * FROM goal_themes ORDER BY id')
            .get())
      CustomGoalTheme(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        colors: ThemeColors(
          primary: row.read<int>('primary_color'),
          secondary: row.read<int>('secondary_color'),
          accent: row.read<int>('accent_color'),
          surface: row.read<int>('surface_color'),
        ),
      ),
  ];

  Future<int> saveTheme({
    int? id,
    required String name,
    required ThemeColors colors,
  }) => database.transaction(() async {
    final title = requiredTitle(name);
    if (!colors.isValid) {
      throw const RuleViolation('Bitte gültige Farben eingeben.');
    }
    final values = [
      Variable(title),
      Variable(colors.primary),
      Variable(colors.secondary),
      Variable(colors.accent),
      Variable(colors.surface),
    ];
    if (id == null) {
      return database.customInsert(
        'INSERT INTO goal_themes(name,primary_color,secondary_color,accent_color,surface_color) VALUES(?,?,?,?,?)',
        variables: values,
      );
    }
    final changed = await database.customUpdate(
      'UPDATE goal_themes SET name=?,primary_color=?,secondary_color=?,accent_color=?,surface_color=? WHERE id=?',
      variables: [...values, Variable(id)],
    );
    if (changed != 1) {
      throw const RuleViolation('Dieses Theme existiert nicht mehr.');
    }
    return id;
  });

  Future<void> deleteTheme(int id) => database.transaction(() async {
    // Built-in palettes are enums, not rows: they cannot be deleted here.
    await database.customStatement(
      'UPDATE goals SET custom_theme_id = NULL WHERE custom_theme_id = ?',
      [id],
    );
    await database.customStatement('DELETE FROM goal_themes WHERE id = ?', [
      id,
    ]);
  });

  Future<void> saveGoal({
    int? id,
    required String title,
    String emoji = '◎',
    String motivation = '',
    DateTime? dueDate,
    Uint8List? coverImage,
    bool removeCoverImage = false,
    GoalColor? color,
    int? customThemeId,
    bool clearCustomTheme = false,
  }) => database.transaction(() async {
    final name = requiredTitle(title);
    final symbol = emoji.trim().isEmpty ? '◎' : emoji.trim();
    if (symbol.characters.length > 1) {
      throw const RuleViolation('Bitte nur ein Emoji oder Zeichen verwenden.');
    }
    if (coverImage != null) await CoverImages.validate(coverImage);
    if (customThemeId != null &&
        !(await _loadThemes()).any((t) => t.id == customThemeId)) {
      throw const RuleViolation('Dieses Theme ist nicht verfügbar.');
    }
    if (id == null) {
      await _checkCapacity();
      await database.customStatement(
        'INSERT INTO goals(title, emoji, motivation, due_date, cover_image, color, custom_theme_id, started_on) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          name,
          symbol,
          motivation.trim(),
          _encodeDate(dueDate),
          coverImage,
          (color ?? GoalColor.forest).name,
          customThemeId,
          _encodeDate(now()),
        ],
      );
    } else {
      final existing = await _requireGoal(id);
      if (coverImage != null || removeCoverImage) {
        await database.customStatement(
          'UPDATE goals SET cover_image = ? WHERE id = ?',
          [coverImage, id],
        );
      }
      await database.customStatement(
        'UPDATE goals SET title = ?, emoji = ?, motivation = ?, due_date = ?, color = ?, custom_theme_id = ? WHERE id = ?',
        [
          name,
          symbol,
          motivation.trim(),
          _encodeDate(dueDate),
          (color ?? existing.color).name,
          customThemeId ?? (clearCustomTheme ? null : existing.customThemeId),
          id,
        ],
      );
    }
  });

  Future<void> saveMilestone({
    int? id,
    required int goalId,
    required String title,
    int progress = 0,
    MilestoneStatus status = MilestoneStatus.notStarted,
    DateTime? dueDate,
  }) => database.transaction(() async {
    await _requireGoal(goalId, active: true);
    final name = requiredTitle(title);
    final normalized = normalizeProgress(progress, status);
    final values = [
      name,
      normalized.progress,
      normalized.status.name,
      _encodeDate(dueDate),
    ];
    if (id == null) {
      await database.customStatement(
        'INSERT INTO milestones(title, progress, status, due_date, goal_id) VALUES (?, ?, ?, ?, ?)',
        [...values, goalId],
      );
    } else {
      final existing = await database
          .customSelect(
            'SELECT id FROM milestones WHERE id = ? AND goal_id = ?',
            variables: [Variable(id), Variable(goalId)],
          )
          .getSingleOrNull();
      if (existing == null) {
        throw const RuleViolation('Dieses Zwischenziel existiert nicht mehr.');
      }
      await database.customStatement(
        'UPDATE milestones SET title = ?, progress = ?, status = ?, due_date = ? WHERE id = ? AND goal_id = ?',
        [...values, id, goalId],
      );
    }
  });

  Future<void> setArchived(int id, bool archived) =>
      database.transaction(() async {
        final goal = await _requireGoal(id);
        if (!archived && goal.archived) await _checkCapacity();
        await database.customStatement(
          'UPDATE goals SET archived = ? WHERE id = ?',
          [archived ? 1 : 0, id],
        );
      });

  Future<void> setAchieved(int id, bool achieved) =>
      database.transaction(() async {
        await _requireGoal(id, active: true);
        await database.customStatement(
          'UPDATE goals SET achieved = ? WHERE id = ?',
          [achieved ? 1 : 0, id],
        );
      });

  Future<void> deleteGoal(int id) => database.transaction(() async {
    final goal = await _requireGoal(id);
    if (!goal.archived) {
      throw const RuleViolation('Bitte das Ziel zuerst archivieren.');
    }
    await database.customStatement('DELETE FROM goals WHERE id = ?', [id]);
  });

  Future<void> deleteMilestone(int id, int goalId) =>
      database.transaction(() async {
        await _requireGoal(goalId, active: true);
        await database.customStatement(
          'DELETE FROM milestones WHERE id = ? AND goal_id = ?',
          [id, goalId],
        );
      });

  Future<Goal> _requireGoal(int id, {bool active = false}) async {
    final row = await database
        .customSelect(
          'SELECT * FROM goals WHERE id = ?',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw const RuleViolation('Dieses Ziel existiert nicht mehr.');
    }
    final goal = _readGoal(row);
    if (active && goal.archived) {
      throw const RuleViolation('Bitte das Ziel zuerst wiederherstellen.');
    }
    return goal;
  }

  Future<void> _checkCapacity() async {
    final row = await database
        .customSelect('SELECT count(*) AS total FROM goals WHERE archived = 0')
        .getSingle();
    if (row.read<int>('total') >= 5) {
      throw const RuleViolation(
        'Du hast bereits fünf aktive Ziele. Archiviere zuerst eines.',
      );
    }
  }

  static DateTime? _date(String? date) =>
      date == null ? null : DateTime.parse(date);
  static Goal _readGoal(QueryRow row) => Goal(
    id: row.read<int>('id'),
    title: row.read<String>('title'),
    emoji: row.read<String>('emoji'),
    motivation: row.read<String>('motivation'),
    dueDate: _date(row.readNullable<String>('due_date')),
    startedOn: _date(row.readNullable<String>('started_on')),
    achieved: row.read<int>('achieved') == 1,
    archived: row.read<int>('archived') == 1,
    coverImage: row.readNullable<Uint8List>('cover_image'),
    customThemeId: row.readNullable<int>('custom_theme_id'),
    color:
        GoalColor.values
            .where((c) => c.name == row.read<String>('color'))
            .firstOrNull ??
        GoalColor.forest,
  );
  static String? _encodeDate(DateTime? date) => date == null
      ? null
      : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
