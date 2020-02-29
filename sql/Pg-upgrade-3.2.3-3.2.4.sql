--
alter table shipto add shiptorecurring bool default 'f';
update shipto set shiptorecurring = 'f';
--
update defaults set fldvalue = '3.2.4' where fldname = 'version';
