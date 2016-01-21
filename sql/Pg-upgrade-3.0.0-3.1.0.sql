--
create sequence referenceid;
alter table reference add code text;
update reference set code = id;
create table temp as select * from reference;
drop table reference;
--
create table reference (id int default nextval('referenceid') primary key, code text, trans_id int, description text, archive_id int, login text, formname text, folder text);
insert into reference (code, trans_id, description) select code, trans_id, description from temp;
drop table temp;
--
create sequence archiveid;
create table archive (id int default nextval('archiveid') primary key, filename text);
create table archivedata (archive_id int references archive (id) on delete cascade, bt text);
--
create table mimetype (extension varchar(32) primary key, contenttype varchar(64));
--
update defaults set fldvalue = '3.1.0' where fldname = 'version';

