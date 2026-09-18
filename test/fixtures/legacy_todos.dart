import 'package:sqlite3/sqlite3.dart';

/// Remove schema-8 additions when deriving legacy fixtures from a fresh store.
void removeTodoLinks(Database db) {
  db.execute('DROP TABLE todo_progress_credits');
  for (final table in ['todo_templates', 'todo_entries']) {
    db.execute('ALTER TABLE $table DROP COLUMN milestone_id');
    db.execute('ALTER TABLE $table DROP COLUMN progress_increment');
  }
}
