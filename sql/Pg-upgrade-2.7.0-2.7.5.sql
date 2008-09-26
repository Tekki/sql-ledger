--
create table cargo (id int not null, trans_id int not null, package text, netweight float4, grossweight float4, volume float4);
--
create index cargo_id_key on cargo (id, trans_id);
--
create table br (id int default nextval('id') primary key, batchnumber text, description text, batch text, transdate date default current_date, apprdate date, amount float, managerid int, employee_id int);
--
create table vr (br_id int references br (id) on delete cascade, trans_id int not null, id int not null default nextval('id'), vouchernumber text);
--
alter table defaults add vouchernumber text;
alter table defaults add batchnumber text;
--
alter table acc_trans add reconciled date;
update acc_trans set reconciled = transdate where cleared;
alter table acc_trans rename cleared to approved;
alter table acc_trans alter approved set default 't';
update acc_trans set approved = '1';
alter table acc_trans rename reconciled to cleared;
--
alter table ar add approved bool;
alter table ar alter approved set default 't';
update ar set approved = '1';
alter table ar add cashdiscount float4;
alter table ar add discountterms int2;
alter table ar add waybill text;
--
alter table ap add approved bool;
alter table ap alter approved set default 't';
update ap set approved = 't';
alter table ap add cashdiscount float4;
alter table ap add discountterms int2;
alter table ap add waybill text;
--
alter table gl add approved bool;
alter table gl alter approved set default 't';
update gl set approved = 't';
--
alter table oe add waybill text;
--
create table semaphore(id int, login text, module text);
--
create sequence addressid;
create table address (id int default nextval('addressid') primary key, trans_id int, address1 varchar(32), address2 varchar(32), city varchar(32), state varchar(32), zipcode varchar(10), country varchar(32));
insert into address (trans_id,address1,address2,city,state,zipcode,country) select distinct id,address1,address2,city,state,zipcode,country from vendor;
--
drop trigger del_vendor on vendor;
alter table vendor rename to old_vendor;
drop function del_vendor();
--
CREATE TABLE vendor (id int default nextval('id') primary key, name varchar(64), contact varchar(64), phone varchar(20), fax varchar(20), email text, notes text, terms int2 default 0, taxincluded bool default 'f', vendornumber varchar(32), cc text, bcc text, gifi_accno varchar(30), business_id int, taxnumber varchar(32), sic_code varchar(6), discount float4, creditlimit float default 0, iban varchar(34), bic varchar(11), employee_id int, language_code varchar(6), pricegroup_id int, curr char(3), startdate date, enddate date, arap_accno_id int, payment_accno_id int, discount_accno_id int, cashdiscount float4, discountterms int2, threshold float);
--
insert into vendor (id,name,contact,phone,fax,email,notes,terms,taxincluded,vendornumber,cc,bcc,gifi_accno,business_id,taxnumber,sic_code,discount,creditlimit,iban,bic,employee_id,language_code,pricegroup_id,curr,startdate,enddate) select distinct id,name,contact,phone,fax,email,notes,terms,taxincluded,vendornumber,cc,bcc,gifi_accno,business_id,taxnumber,sic_code,discount,creditlimit,iban,bic,employee_id,language_code,pricegroup_id,curr,startdate,enddate from old_vendor;
--
--
CREATE FUNCTION del_vendor() RETURNS OPAQUE AS '
begin
  delete from shipto where trans_id = old.id;
  delete from vendortax where vendor_id = old.id;
  delete from partsvendor where vendor_id = old.id;
  delete from address where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_vendor AFTER DELETE ON vendor FOR EACH ROW EXECUTE PROCEDURE del_vendor();
-- end trigger
--
drop table old_vendor;
--
create index vendor_name_key on vendor (lower(name));
create index vendor_vendornumber_key on vendor (vendornumber);
create index vendor_contact_key on vendor (lower(contact));
--
insert into address (trans_id,address1,address2,city,state,zipcode,country) select distinct id,address1,address2,city,state,zipcode,country from customer;
--
drop trigger del_customer on customer;
alter table customer rename to old_customer;
drop function del_customer();
--
CREATE TABLE customer (id int default nextval('id') primary key, name varchar(64), contact varchar(64), phone varchar(20), fax varchar(20), email text, notes text, terms int2 default 0, taxincluded bool default 'f', customernumber varchar(32), cc text, bcc text, business_id int, taxnumber varchar(32), sic_code varchar(6), discount float4, creditlimit float default 0, iban varchar(34), bic varchar(11), employee_id int, language_code varchar(6), pricegroup_id int, curr char(3), startdate date, enddate date, arap_accno_id int, payment_accno_id int, discount_accno_id int, cashdiscount float4, discountterms int2, threshold float);
--
insert into customer (id,name,contact,phone,fax,email,notes,terms,taxincluded,customernumber,cc,bcc,business_id,taxnumber,sic_code,discount,creditlimit,iban,bic,employee_id,language_code,pricegroup_id,curr,startdate,enddate) select distinct id,name,contact,phone,fax,email,notes,terms,taxincluded,customernumber,cc,bcc,business_id,taxnumber,sic_code,discount,creditlimit,iban,bic,employee_id,language_code,pricegroup_id,curr,startdate,enddate from old_customer;
--
--
CREATE FUNCTION del_customer() RETURNS OPAQUE AS '
begin
  delete from shipto where trans_id = old.id;
  delete from customertax where customer_id = old.id;
  delete from partscustomer where customer_id = old.id;
  delete from address where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_customer AFTER DELETE ON customer FOR EACH ROW EXECUTE PROCEDURE del_customer();
-- end trigger
--
drop table old_customer;
--
create index customer_name_key on customer (lower(name));
create index customer_customernumber_key on customer (customernumber);
create index customer_contact_key on customer (lower(contact));
--
alter table acc_trans rename invoice_id to id;
alter table acc_trans add vr_id int;
--
update defaults set version = '2.7.5';
