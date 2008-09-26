--
alter table parts add toolnumber text;
--
update defaults set fldvalue = '2.7.10' where fldname = 'version';
