import 'package:sqlite3/sqlite3.dart';

/// Remove newer goal fields and schema-8/9 todo additions when deriving legacy fixtures from a fresh store.
void removeTodoLinks(Database db) {
  db.execute('PRAGMA foreign_keys=OFF');
  db.execute('ALTER TABLE goals DROP COLUMN show_card_cover');
  db.execute('ALTER TABLE goals DROP COLUMN sort_order');
  db.execute('CREATE TEMP TABLE old_milestones AS SELECT * FROM milestones');
  db.execute('DROP TABLE milestones');
  db.execute('''CREATE TABLE milestones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id INTEGER NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK(length(trim(title)) > 0),
    progress INTEGER NOT NULL DEFAULT 0 CHECK(progress BETWEEN 0 AND 100),
    status TEXT NOT NULL DEFAULT 'notStarted' CHECK(status IN ('notStarted','onTrack','offTrack','onHold','achieved')),
    due_date TEXT,
    CHECK((status='achieved')=(progress=100)),
    CHECK(status!='notStarted' OR progress=0)
  )''');
  db.execute(
    'INSERT INTO milestones SELECT id,goal_id,title,progress/100,status,due_date FROM old_milestones',
  );
  db.execute('DROP TABLE old_milestones');
  db.execute('CREATE INDEX milestones_goal ON milestones(goal_id,id)');
  db.execute('DROP TABLE todo_progress_credits');
  for (final table in ['todo_templates', 'todo_entries']) {
    db.execute('ALTER TABLE $table DROP COLUMN progress_mode');
    db.execute('ALTER TABLE $table DROP COLUMN milestone_id');
    db.execute('ALTER TABLE $table DROP COLUMN progress_increment');
  }
}

/// Derive a schema-11 fixture; measurement fields did not exist then.
void removeMetricScale(Database db) {
  for (final column in [
    'motivation',
    'start_value',
    'target_value',
    'current_value',
    'unit',
  ]) {
    db.execute('ALTER TABLE milestones DROP COLUMN $column');
  }
  db.execute('ALTER TABLE todo_progress_credits DROP COLUMN value_amount');
}
