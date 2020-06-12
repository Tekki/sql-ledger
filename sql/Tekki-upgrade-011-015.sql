ALTER TABLE bank ADD COLUMN IF NOT EXISTS qriban varchar(34);
--
UPDATE defaults SET fldvalue = '15' WHERE fldname = 'version2';
