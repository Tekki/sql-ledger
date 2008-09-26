--
-- drop trigger del_recurring ON oe;
-- moved to Pg-upgrade-2.8.0-2.8.2.sql
--
drop function lastcost(int);
drop function avgcost(int);
--
drop trigger del_yearend on gl;
drop function del_yearend();
--
drop trigger del_department on gl;
drop trigger del_department on ar;
drop trigger del_department on ap;
drop trigger del_department on oe;
--
drop trigger check_department on ar;
drop trigger check_department on ap;
drop trigger check_department on gl;
drop trigger check_department on oe;
drop function check_department();
--
drop trigger del_recurring ON gl;
drop trigger del_recurring ON ar;
drop trigger del_recurring ON ap;
drop function del_recurring();
--
drop trigger del_customer on customer;
drop function del_customer();
--
drop trigger del_vendor on vendor;
drop function del_vendor();
--
create table paymentmethod (id int primary key default nextval('id'), description text, fee float);
alter table vendor add paymentmethod_id int;
alter table customer add paymentmethod_id int;
alter table vendor add remittancevoucher bool;
alter table customer add remittancevoucher bool;
--
create table bank (id int, name varchar(64), iban varchar(34), bic varchar(11), address_id int default nextval('addressid'));
--
update defaults set fldvalue = '2.8.3' where fldname = 'version';

