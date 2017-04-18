--
update defaults set fldname = 'fxgainloss_accno_id' where fldname = 'fxgain_accno_id';
delete from defaults where fldname = 'fxloss_accno_id';
--
alter table oe add backorder bool;
alter table oe alter backorder set default '0';
update oe set backorder = '0';
--
update defaults set fldvalue = '3.2.1' where fldname = 'version';
