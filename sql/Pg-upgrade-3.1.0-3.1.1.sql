--
alter table invoice add cost float;
alter table invoice add vendor text;
alter table invoice add vendor_id int;
--
alter table orderitems add cost float;
alter table orderitems add vendor text;
alter table orderitems add vendor_id int;
--
update defaults set fldvalue = '3.1.1' where fldname = 'version';
