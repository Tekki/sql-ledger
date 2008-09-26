--
alter table oe add aa_id int;
--
update defaults set fldvalue = '2.7.13' where fldname = 'version';
