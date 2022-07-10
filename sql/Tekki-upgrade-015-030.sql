ALTER TABLE mimetype ALTER COLUMN contenttype TYPE text;
--
INSERT INTO mimetype (extension, contenttype)
  SELECT 'docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  WHERE NOT EXISTS(SELECT 1 FROM mimetype WHERE extension='docx');
INSERT INTO mimetype (extension, contenttype)
  SELECT 'pptx', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
  WHERE NOT EXISTS(SELECT 1 FROM mimetype WHERE extension='pptx');
INSERT INTO mimetype (extension, contenttype)
  SELECT 'xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  WHERE NOT EXISTS(SELECT 1 FROM mimetype WHERE extension='xlsx');
--
UPDATE defaults SET fldvalue = '30' WHERE fldname = 'version2';
