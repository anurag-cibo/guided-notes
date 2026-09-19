import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// Small explicit SQLite schema. Drift owns connections, transactions and versions.
/// SQL is kept here/repository; domain and widgets never depend on database rows.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.local() => AppDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File('${directory.path}/guide.sqlite'),
      );
    }),
  );

  @override
  int get schemaVersion => 12;

  Future<void> _addMetricScale() async {
    await customStatement(
      "ALTER TABLE milestones ADD COLUMN motivation TEXT NOT NULL DEFAULT ''",
    );
    await customStatement(
      'ALTER TABLE milestones ADD COLUMN start_value INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'ALTER TABLE milestones ADD COLUMN target_value INTEGER NOT NULL DEFAULT 10000',
    );
    await customStatement(
      "ALTER TABLE milestones ADD COLUMN unit TEXT NOT NULL DEFAULT '%'",
    );
    await customStatement(
      'ALTER TABLE milestones ADD COLUMN current_value INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement('UPDATE milestones SET current_value = progress');

    // Rebuild only Todo tables to widen contribution constraints. Stable IDs,
    // foreign keys, ledger rows and the AUTOINCREMENT high-water mark survive.
    await customStatement(
      "CREATE TEMP TABLE metric_sequence AS SELECT * FROM sqlite_sequence WHERE name='todo_templates'",
    );
    const tables = ['todo_progress_credits', 'todo_entries', 'todo_templates'];
    for (final table in tables) {
      await customStatement(
        'CREATE TEMP TABLE metric_$table AS SELECT * FROM $table',
      );
    }
    for (final table in tables) {
      await customStatement('DROP TABLE $table');
    }
    await _createTodos();
    await _addTodoLinks(scale: 100, maxIncrement: 100000000000);
    await _addProgressMode();
    for (final table in tables.reversed) {
      await customStatement('INSERT INTO $table SELECT * FROM metric_$table');
      await customStatement('DROP TABLE metric_$table');
    }
    await customStatement(
      "UPDATE sqlite_sequence SET seq=MAX(seq,COALESCE((SELECT seq FROM metric_sequence),0)) WHERE name='todo_templates'",
    );
    await customStatement(
      "INSERT INTO sqlite_sequence(name,seq) SELECT name,seq FROM metric_sequence WHERE NOT EXISTS(SELECT 1 FROM sqlite_sequence WHERE name='todo_templates')",
    );
    await customStatement('DROP TABLE metric_sequence');
    await customStatement(
      'ALTER TABLE todo_progress_credits ADD COLUMN value_amount INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE todo_progress_credits SET value_amount = amount',
    );
  }

  Future<void> _addOrdering() async {
    for (final table in ['goals', 'milestones']) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
      await customStatement('UPDATE $table SET sort_order = id');
    }
  }

  Future<void> _addTodoLinks({int scale = 1, int? maxIncrement}) async {
    for (final table in ['todo_templates', 'todo_entries']) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN milestone_id INTEGER REFERENCES milestones(id) ON DELETE SET NULL',
      );
      await customStatement(
        'ALTER TABLE $table ADD COLUMN progress_increment INTEGER NOT NULL DEFAULT 0 CHECK(progress_increment BETWEEN 0 AND ${maxIncrement ?? 100 * scale})',
      );
    }
    await customStatement('''CREATE TABLE todo_progress_credits (
      template_id INTEGER NOT NULL,
      period TEXT NOT NULL,
      ordinal INTEGER NOT NULL CHECK(ordinal BETWEEN 1 AND 999),
      milestone_id INTEGER REFERENCES milestones(id) ON DELETE SET NULL,
      amount INTEGER NOT NULL CHECK(amount BETWEEN 0 AND ${100 * scale}),
      previous_status TEXT NOT NULL CHECK(previous_status IN ('notStarted','onTrack','offTrack','onHold','achieved')),
      PRIMARY KEY(template_id, period, ordinal),
      FOREIGN KEY(template_id, period) REFERENCES todo_entries(template_id, period) ON DELETE CASCADE
    )''');
  }

  Future<void> _addProgressMode() async {
    for (final table in ['todo_templates', 'todo_entries']) {
      await customStatement(
        "ALTER TABLE $table ADD COLUMN progress_mode TEXT NOT NULL DEFAULT 'perCompletion' CHECK(progress_mode IN ('perCompletion','onTarget'))",
      );
    }
  }

  Future<void> _createMilestones() async {
    await customStatement('''CREATE TABLE milestones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      goal_id INTEGER NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
      title TEXT NOT NULL CHECK(length(trim(title)) > 0),
      progress INTEGER NOT NULL DEFAULT 0 CHECK(progress BETWEEN 0 AND 10000),
      status TEXT NOT NULL DEFAULT 'notStarted'
        CHECK(status IN ('notStarted','onTrack','offTrack','onHold','achieved')),
      due_date TEXT,
      CHECK((status = 'achieved') = (progress = 10000)),
      CHECK(status != 'notStarted' OR progress = 0)
    )''');
    await customStatement(
      'CREATE INDEX milestones_goal ON milestones(goal_id, id)',
    );
  }

  Future<void> _migrateProgressUnits() => transaction(() async {
    await customStatement(
      "CREATE TEMP TABLE migration_sequences AS SELECT name,seq FROM sqlite_sequence WHERE name IN ('milestones','todo_templates')",
    );
    // Copy dependants before dropping in FK order. Goals and their images stay
    // untouched; persisted contributions retain exact undo semantics.
    const tables = [
      'todo_progress_credits',
      'todo_entries',
      'todo_templates',
      'milestones',
    ];
    for (final table in tables) {
      await customStatement(
        'CREATE TEMP TABLE migration_$table AS SELECT * FROM $table',
      );
    }
    for (final table in tables) {
      await customStatement('DROP TABLE $table');
    }
    await _createMilestones();
    await _createTodos();
    await _addTodoLinks(scale: 100);
    await _addProgressMode();
    await customStatement(
      'INSERT INTO milestones(id,goal_id,title,progress,status,due_date) SELECT id,goal_id,title,progress*100,status,due_date FROM migration_milestones',
    );
    await customStatement(
      'INSERT INTO todo_templates(id,title,frequency,target,active,milestone_id,progress_increment) SELECT id,title,frequency,target,active,milestone_id,progress_increment*100 FROM migration_todo_templates',
    );
    await customStatement(
      'INSERT INTO todo_entries(template_id,period,title,frequency,target,completed,milestone_id,progress_increment) SELECT template_id,period,title,frequency,target,completed,milestone_id,progress_increment*100 FROM migration_todo_entries',
    );
    await customStatement(
      'INSERT INTO todo_progress_credits(template_id,period,ordinal,milestone_id,amount,previous_status) SELECT template_id,period,ordinal,milestone_id,amount*100,previous_status FROM migration_todo_progress_credits',
    );
    for (final table in tables) {
      await customStatement('DROP TABLE migration_$table');
    }
    await customStatement(
      'UPDATE sqlite_sequence SET seq=MAX(seq, (SELECT seq FROM migration_sequences WHERE name=sqlite_sequence.name)) WHERE name IN (SELECT name FROM migration_sequences)',
    );
    await customStatement(
      'INSERT INTO sqlite_sequence(name,seq) SELECT name,seq FROM migration_sequences WHERE name NOT IN (SELECT name FROM sqlite_sequence)',
    );
    await customStatement('DROP TABLE migration_sequences');
  });

  Future<void> _createGoalThemes() =>
      customStatement('''CREATE TABLE goal_themes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL CHECK(length(trim(name)) > 0),
    primary_color INTEGER NOT NULL CHECK(primary_color BETWEEN 4278190080 AND 4294967295),
    secondary_color INTEGER NOT NULL CHECK(secondary_color BETWEEN 4278190080 AND 4294967295),
    accent_color INTEGER NOT NULL CHECK(accent_color BETWEEN 4278190080 AND 4294967295),
    surface_color INTEGER NOT NULL CHECK(surface_color BETWEEN 4278190080 AND 4294967295)
  )''');

  Future<void> _createSettings() =>
      customStatement('''CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )''');

  Future<void> _createTodos() async {
    await customStatement('''CREATE TABLE todo_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL CHECK(length(trim(title)) > 0),
      frequency TEXT NOT NULL CHECK(frequency IN ('daily','weekly')),
      target INTEGER NOT NULL CHECK(target BETWEEN 1 AND 999),
      active INTEGER NOT NULL CHECK(active IN (0,1)),
      CHECK(frequency != 'daily' OR target = 1)
    )''');
    await customStatement('''CREATE TABLE todo_entries (
      template_id INTEGER NOT NULL REFERENCES todo_templates(id),
      period TEXT NOT NULL,
      title TEXT NOT NULL CHECK(length(trim(title)) > 0),
      frequency TEXT NOT NULL CHECK(frequency IN ('daily','weekly')),
      target INTEGER NOT NULL CHECK(target BETWEEN 1 AND 999),
      completed INTEGER NOT NULL CHECK(completed BETWEEN 0 AND target),
      PRIMARY KEY(template_id, period),
      CHECK(frequency != 'daily' OR target = 1)
    )''');
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await _createGoalThemes();
      await customStatement('''CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        emoji TEXT NOT NULL DEFAULT '◎',
        motivation TEXT NOT NULL DEFAULT '',
        due_date TEXT,
        started_on TEXT,
        achieved INTEGER NOT NULL DEFAULT 0 CHECK(achieved IN (0, 1)),
        archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN (0, 1)),
        cover_image BLOB,
        show_card_cover INTEGER NOT NULL DEFAULT 1 CHECK(show_card_cover IN (0, 1)),
        color TEXT NOT NULL DEFAULT 'forest',
        custom_theme_id INTEGER REFERENCES goal_themes(id)
      )''');
      await _createMilestones();
      await customStatement('''CREATE TRIGGER limit_goal_insert
        BEFORE INSERT ON goals WHEN NEW.archived = 0
        AND (SELECT count(*) FROM goals WHERE archived = 0) >= 5
        BEGIN SELECT RAISE(ABORT, 'active_goal_limit'); END''');
      await customStatement('''CREATE TRIGGER limit_goal_restore
        BEFORE UPDATE OF archived ON goals WHEN OLD.archived = 1 AND NEW.archived = 0
        AND (SELECT count(*) FROM goals WHERE archived = 0) >= 5
        BEGIN SELECT RAISE(ABORT, 'active_goal_limit'); END''');
      await _createTodos();
      await _addTodoLinks(scale: 100);
      await _addProgressMode();
      await _createSettings();
      await _addOrdering();
      await _addMetricScale();
    },
    onUpgrade: (_, from, to) async {
      if (from < 1 || from > 11 || to != 12) {
        throw StateError(
          'Keine Migration von Schema $from nach $to vorhanden.',
        );
      }
      if (from < 2) await _createTodos();
      if (from < 3) await _createSettings();
      if (from < 4) {
        await customStatement('ALTER TABLE goals ADD COLUMN cover_image BLOB');
      }
      if (from < 5) {
        await customStatement(
          "ALTER TABLE goals ADD COLUMN color TEXT NOT NULL DEFAULT 'forest'",
        );
      }
      if (from < 6) {
        await _createGoalThemes();
        await customStatement(
          'ALTER TABLE goals ADD COLUMN custom_theme_id INTEGER REFERENCES goal_themes(id)',
        );
      }
      if (from < 7) {
        await customStatement('ALTER TABLE goals ADD COLUMN started_on TEXT');
      }
      if (from < 8) await _addTodoLinks();
      if (from < 9) await _migrateProgressUnits();
      if (from < 10) {
        await customStatement(
          'ALTER TABLE goals ADD COLUMN show_card_cover INTEGER NOT NULL DEFAULT 1 CHECK(show_card_cover IN (0, 1))',
        );
      }
      if (from < 11) await _addOrdering();
      await _addMetricScale();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.versionNow > schemaVersion) {
        throw StateError('Diese Datenbank benötigt eine neuere App-Version.');
      }
    },
  );
}
