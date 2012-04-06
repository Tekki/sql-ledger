--
create table temp (curr char(3), transdate date, exchangerate float);
insert into temp select curr, transdate, buy from exchangerate;
delete from temp where exchangerate = 0;
drop table exchangerate;
alter table temp rename to exchangerate;
create index exchangerate_ct_key on exchangerate (curr, transdate);
--
update defaults set fldvalue = '2.9.2' where fldname = 'version';
