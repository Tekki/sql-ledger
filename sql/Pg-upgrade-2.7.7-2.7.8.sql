--
alter table ar add description text;
alter table ap add description text;
alter table oe add description text;
--
alter table recurring add description text;
--
alter table invoice rename notes to itemnotes;
alter table orderitems rename notes to itemnotes;
--
update defaults set fldvalue = '2.7.8' where fldname = 'version';
