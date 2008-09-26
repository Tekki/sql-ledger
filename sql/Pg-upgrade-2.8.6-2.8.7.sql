--
alter table semaphore add expires varchar(10);
--
create table curr (rn int, curr char(3) primary key, precision int2);
create sequence tempid start 2;
insert into curr (curr,precision) select distinct curr, 2 from ar union select distinct curr, 2 from ap union select distinct curr, 2 from gl union select distinct curr, 2 from oe;
update curr set rn = nextval('tempid');
drop sequence tempid;
update curr set rn = 1 where curr = (select substr(fldvalue,1,3) from defaults where fldname = 'currencies');
--
alter table ar add bank_id int;
alter table ap add bank_id int;
--
insert into defaults (fldname,fldvalue) values ('precision', 2);
delete from defaults where fldname = 'currencies';
--
update defaults set fldvalue = '2.8.7' where fldname = 'version';
