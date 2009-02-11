--
alter table orderitems add ordernumber text;
alter table orderitems add ponumber text;
alter table invoice add ordernumber text;
alter table invoice add ponumber text;
--
update defaults set fldvalue = '2.8.9' where fldname = 'version';
