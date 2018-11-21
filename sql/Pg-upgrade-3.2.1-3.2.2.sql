--
alter table parts add lot text;
alter table parts add expires date;
alter table parts add checkinventory bool;
alter table parts alter checkinventory set default 'f';
--
update defaults set fldvalue = '3.2.2' where fldname = 'version';
