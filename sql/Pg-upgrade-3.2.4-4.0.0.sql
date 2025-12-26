--
CREATE SEQUENCE IF NOT EXISTS recentid;
SELECT nextval('recentid');
--
CREATE TABLE IF NOT EXISTS recent (
  id int DEFAULT nextval('recentid'),
  employee_id int,
  object_id int NOT NULL,
  code char(2) NOT NULL
);
--
CREATE TABLE IF NOT EXISTS recentdescr (
  object_id int NOT NULL,
  number varchar(32) NOT NULL DEFAULT '',
  description text NOT NULL DEFAULT ''
);
--
CREATE UNIQUE INDEX IF NOT EXISTS recent_id_key ON recent(id);
CREATE INDEX IF NOT EXISTS recent_employee_id_key ON recent(employee_id);
CREATE INDEX IF NOT EXISTS recent_object_id_key ON recent(object_id);
CREATE INDEX IF NOT EXISTS recent_code_key ON recent(code);
CREATE UNIQUE INDEX IF NOT EXISTS recentdescr_object_id_key ON recentdescr(object_id);
--
ALTER TABLE bank ADD COLUMN IF NOT EXISTS qriban varchar(34);
--
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
ALTER TABLE archive ADD COLUMN IF NOT EXISTS hash char(64);
CREATE INDEX IF NOT EXISTS archive_hash_key ON archive(hash);
--
ALTER TABLE address ADD COLUMN IF NOT EXISTS streetname varchar(32);
ALTER TABLE address ADD COLUMN IF NOT EXISTS buildingnumber varchar(32);
ALTER TABLE shipto ADD COLUMN IF NOT EXISTS shiptostreetname varchar(32);
ALTER TABLE shipto ADD COLUMN IF NOT EXISTS shiptobuildingnumber varchar(32);
--
UPDATE defaults SET fldvalue = '4.0.0' WHERE fldname = 'version';
