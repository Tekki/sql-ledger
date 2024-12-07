ALTER TABLE address ADD COLUMN IF NOT EXISTS streetname varchar(32);
ALTER TABLE address ADD COLUMN IF NOT EXISTS buildingnumber varchar(32);
ALTER TABLE shipto ADD COLUMN IF NOT EXISTS shiptostreetname varchar(32);
ALTER TABLE shipto ADD COLUMN IF NOT EXISTS shiptobuildingnumber varchar(32);
--
UPDATE defaults SET fldvalue = '49' WHERE fldname = 'version2';
