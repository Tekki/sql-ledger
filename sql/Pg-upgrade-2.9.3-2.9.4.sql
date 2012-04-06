--
alter table partsgroup add code text;
--
update defaults set fldvalue = '2.9.4' where fldname = 'version';
