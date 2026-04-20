--
ALTER TABLE oe ADD COLUMN IF NOT EXISTS onhold bool DEFAULT 'f';
--
UPDATE defaults SET fldvalue = '4.1.0' WHERE fldname = 'version';
