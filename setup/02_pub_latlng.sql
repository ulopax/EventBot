BEGIN;
ALTER TABLE pubs ADD lat REAL;
ALTER TABLE pubs ADD lng REAL;
COMMIT;