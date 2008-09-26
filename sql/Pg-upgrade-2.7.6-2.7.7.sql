--
alter table parts add barcode text;
--
update defaults set fldvalue = '2.7.7' where fldname = 'version';

