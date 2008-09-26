--
alter table employee add workfax varchar(20);
alter table employee add workmobile varchar(20);
--
update defaults set fldvalue = '2.7.16' where fldname = 'version';
