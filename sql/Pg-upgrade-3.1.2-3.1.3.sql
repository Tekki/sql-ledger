--
alter table warehouse add rn int;
alter table department add rn int;
alter table business add rn int;
alter table chart add closed boolean;
alter table chart alter closed set default '0';
update chart set closed = '0';
--
create sequence tempid;
update warehouse set rn = nextval('tempid');
select setval('tempid',1,'0');
update department set rn = nextval('tempid');
select setval('tempid',1,'0');
update business set rn = nextval('tempid');
drop sequence tempid;
--
update defaults set fldvalue = '3.1.3' where fldname = 'version';

