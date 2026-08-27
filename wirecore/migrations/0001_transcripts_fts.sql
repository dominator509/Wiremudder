-- WireMudder storage migration 0001 (EP-014).
-- Append-only transcript metadata + FTS5 index (WM-SPEC-011-R04).
-- Idempotent: applied exactly once via wire_schema_version.
CREATE TABLE IF NOT EXISTS transcripts (
    seq INTEGER PRIMARY KEY AUTOINCREMENT,
    profile TEXT NOT NULL,
    direction TEXT NOT NULL CHECK(direction IN ('in','out','note')),
    text TEXT NOT NULL,
    time INTEGER NOT NULL
);
CREATE VIRTUAL TABLE IF NOT EXISTS transcripts_fts USING fts5(
    profile, direction, text, content='transcripts', content_rowid='seq'
);
CREATE TRIGGER IF NOT EXISTS transcripts_ai AFTER INSERT ON transcripts BEGIN
    INSERT INTO transcripts_fts(rowid, profile, direction, text)
    VALUES (new.seq, new.profile, new.direction, new.text);
END;
CREATE TRIGGER IF NOT EXISTS transcripts_ad AFTER DELETE ON transcripts BEGIN
    INSERT INTO transcripts_fts(transcripts_fts, rowid, profile, direction, text)
    VALUES ('delete', old.seq, old.profile, old.direction, old.text);
END;
CREATE TRIGGER IF NOT EXISTS transcripts_au AFTER UPDATE ON transcripts BEGIN
    INSERT INTO transcripts_fts(transcripts_fts, rowid, profile, direction, text)
    VALUES ('delete', old.seq, old.profile, old.direction, old.text);
    INSERT INTO transcripts_fts(rowid, profile, direction, text)
    VALUES (new.seq, new.profile, new.direction, new.text);
END;
