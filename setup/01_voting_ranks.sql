BEGIN;

ALTER TABLE votes ADD COLUMN rank INTEGER NOT NULL DEFAULT 0;

COMMIT;
