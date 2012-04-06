--
alter table partsgroup add image text;
--
update defaults set fldvalue = '2.9.6' where fldname = 'version';
