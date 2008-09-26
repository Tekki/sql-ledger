--
alter table bank add column dcn text;
alter table bank add column rvc text;
alter table bank add column membernumber text;
--
alter table ar add column dcn text;
alter table ap add column dcn text;
--
update defaults set fldvalue = '2.8.6' where fldname = 'version';
