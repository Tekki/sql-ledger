--
alter table ar add paymentmethod_id int;
alter table ap add paymentmethod_id int;
--
alter table paymentmethod add rn int;
create sequence tempid;
update paymentmethod set rn = nextval('tempid');
drop sequence tempid;
--
update defaults set fldvalue = '2.8.8' where fldname = 'version';
