CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        emoji TEXT NOT NULL DEFAULT '◎',
        motivation TEXT NOT NULL DEFAULT '',
        due_date TEXT,
        achieved INTEGER NOT NULL DEFAULT 0 CHECK(achieved IN (0, 1)),
        archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN (0, 1))
      );
CREATE TABLE milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        progress INTEGER NOT NULL DEFAULT 0 CHECK(progress BETWEEN 0 AND 100),
        status TEXT NOT NULL DEFAULT 'notStarted'
          CHECK(status IN ('notStarted', 'onTrack', 'offTrack', 'onHold', 'achieved')),
        due_date TEXT,
        CHECK((status = 'achieved') = (progress = 100)),
        CHECK(status != 'notStarted' OR progress = 0)
      );
CREATE TRIGGER limit_goal_insert
        BEFORE INSERT ON goals WHEN NEW.archived = 0
        AND (SELECT count(*) FROM goals WHERE archived = 0) >= 5
        BEGIN SELECT RAISE(ABORT, 'active_goal_limit'); END;
CREATE TRIGGER limit_goal_restore
        BEFORE UPDATE OF archived ON goals WHEN OLD.archived = 1 AND NEW.archived = 0
        AND (SELECT count(*) FROM goals WHERE archived = 0) >= 5
        BEGIN SELECT RAISE(ABORT, 'active_goal_limit'); END;
CREATE INDEX milestones_goal ON milestones(goal_id, id);
PRAGMA user_version = 1;
