--
alter table partsgroup add pos bool;
alter table partsgroup alter pos set default 't';
update partsgroup set pos = '1';
--
update defaults set fldvalue = '2.8.5' where fldname = 'version';

