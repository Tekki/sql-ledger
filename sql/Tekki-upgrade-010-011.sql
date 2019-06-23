--
CREATE SEQUENCE recentid;
SELECT nextval('recentid');
--
CREATE TABLE recent (
  id int DEFAULT nextval('recentid'),
  employee_id int,
  object_id int NOT NULL,
  code char(2) NOT NULL
);
--
CREATE TABLE recentdescr (
  object_id int NOT NULL,
  number varchar(32) NOT NULL DEFAULT '',
  description text NOT NULL DEFAULT ''
);
--
CREATE UNIQUE index recent_id_key ON recent(id);
CREATE INDEX recent_employee_id_key ON recent(employee_id);
CREATE INDEX recent_object_id_key ON recent(object_id);
CREATE INDEX recent_code_key ON recent(code);
CREATE UNIQUE INDEX recentdescr_object_id_key ON recentdescr(object_id);
--
DELETE FROM defaults WHERE fldname = 'version2';
INSERT INTO defaults (fldname, fldvalue) VALUES ('version2', '11');
