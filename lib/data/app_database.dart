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
  int get schemaVersion => 6;

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
        achieved INTEGER NOT NULL DEFAULT 0 CHECK(achieved IN (0, 1)),
        archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN (0, 1)),
        cover_image BLOB,
        color TEXT NOT NULL DEFAULT 'forest',
        custom_theme_id INTEGER REFERENCES goal_themes(id)
      )''');
      await customStatement('''CREATE TABLE milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        progress INTEGER NOT NULL DEFAULT 0 CHECK(progress BETWEEN 0 AND 100),
        status TEXT NOT NULL DEFAULT 'notStarted'
          CHECK(status IN ('notStarted', 'onTrack', 'offTrack', 'onHold', 'achieved')),
        due_date TEXT,
        CHECK((status = 'achieved') = (progress = 100)),
        CHECK(status != 'notStarted' OR progress = 0)
      )''');
      await customStatement(
        'CREATE INDEX milestones_goal ON milestones(goal_id, id)',
      );
      await customStatement('''CREATE TRIGGER limit_goal_insert
        BEFORE INSERT ON goals WHEN NEW.archived = 0
        AND (SELECT count(*) FROM goals WHERE archived = 0) >= 5
        BEGIN SELECT RAISE(ABORT, 'active_goal_limit'); END''');
      await customStatement('''CREATE TRIGGER limit_goal_restore
        BEFORE UPDATE OF archived ON goals WHEN OLD.archived = 1 AND NEW.archived = 0
        AND (SELECT count(*) FROM goals WHERE archived = 0) >= 5
        BEGIN SELECT RAISE(ABORT, 'active_goal_limit'); END''');
      await _createTodos();
      await _createSettings();
    },
    onUpgrade: (_, from, to) async {
      if (from < 1 || from > 5 || to != 6) {
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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.versionNow > schemaVersion) {
        throw StateError('Diese Datenbank benötigt eine neuere App-Version.');
      }
    },
  );
}
