ALTER TABLE archive ADD COLUMN IF NOT EXISTS hash char(64);
CREATE INDEX IF NOT EXISTS archive_hash_key ON archive(hash);
--
UPDATE defaults SET fldvalue = '43' WHERE fldname = 'version2';
