CREATE TABLE goal_themes (
  id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
  primary_color INTEGER NOT NULL, secondary_color INTEGER NOT NULL,
  accent_color INTEGER NOT NULL, surface_color INTEGER NOT NULL
);
ALTER TABLE goals ADD COLUMN cover_image BLOB;
ALTER TABLE goals ADD COLUMN color TEXT NOT NULL DEFAULT 'forest';
ALTER TABLE goals ADD COLUMN custom_theme_id INTEGER REFERENCES goal_themes(id);
ALTER TABLE goals ADD COLUMN started_on TEXT;
CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE todo_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
  frequency TEXT NOT NULL CHECK(frequency IN ('daily','weekly')),
  target INTEGER NOT NULL CHECK(target BETWEEN 1 AND 999),
  active INTEGER NOT NULL CHECK(active IN (0,1)),
  milestone_id INTEGER REFERENCES milestones(id) ON DELETE SET NULL,
  progress_increment INTEGER NOT NULL DEFAULT 0 CHECK(progress_increment BETWEEN 0 AND 100),
  CHECK(frequency!='daily' OR target=1)
);
CREATE TABLE todo_entries (
  template_id INTEGER NOT NULL REFERENCES todo_templates(id), period TEXT NOT NULL,
  title TEXT NOT NULL, frequency TEXT NOT NULL CHECK(frequency IN ('daily','weekly')),
  target INTEGER NOT NULL CHECK(target BETWEEN 1 AND 999),
  completed INTEGER NOT NULL CHECK(completed BETWEEN 0 AND target),
  milestone_id INTEGER REFERENCES milestones(id) ON DELETE SET NULL,
  progress_increment INTEGER NOT NULL DEFAULT 0 CHECK(progress_increment BETWEEN 0 AND 100),
  PRIMARY KEY(template_id,period), CHECK(frequency!='daily' OR target=1)
);
CREATE TABLE todo_progress_credits (
  template_id INTEGER NOT NULL, period TEXT NOT NULL,
  ordinal INTEGER NOT NULL CHECK(ordinal BETWEEN 1 AND 999),
  milestone_id INTEGER REFERENCES milestones(id) ON DELETE SET NULL,
  amount INTEGER NOT NULL CHECK(amount BETWEEN 0 AND 100),
  previous_status TEXT NOT NULL CHECK(previous_status IN ('notStarted','onTrack','offTrack','onHold','achieved')),
  PRIMARY KEY(template_id,period,ordinal),
  FOREIGN KEY(template_id,period) REFERENCES todo_entries(template_id,period) ON DELETE CASCADE
);
PRAGMA user_version=8;
