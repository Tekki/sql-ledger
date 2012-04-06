--
alter table bank add clearingnumber text;
--
--
create table temp (id int, iban varchar(34), bic varchar(11));
insert into temp (id, iban, bic) select id, iban, bic from customer where customer.id not in (select id from bank);
delete from temp where iban = '' and bic = '';
delete from temp where iban is null and bic is null;
insert into bank (id, iban, bic) select id, iban, bic from temp;
delete from temp;
insert into temp (id, iban, bic) select id, iban, bic from vendor where vendor.id not in (select id from bank);
delete from temp where iban = '' and bic = '';
delete from temp where iban is null and bic is null;
insert into bank (id, iban, bic) select id, iban, bic from temp;
delete from temp;
insert into temp (id, iban, bic) select id, iban, bic from employee where employee.id not in (select id from bank);
delete from temp where iban = '' and bic = '';
delete from temp where iban is null and bic is null;
insert into bank (id, iban, bic) select id, iban, bic from temp;
drop table temp;
--
insert into address (trans_id, address1, address2, city, state, zipcode, country) select id,  address1, address2, city, state, zipcode, country from employee;
--
create table temp as select * from employee;
drop table employee;
create table employee (id int default nextval('id') primary key, login text, name varchar(64), workphone varchar(20), workfax varchar(20), workmobile varchar(20), homephone varchar(20), startdate date default current_date, enddate date, notes text, role varchar(20), sales bool default 'f', email text, ssn varchar(20), managerid int, employeenumber varchar(32), dob date);
insert into employee (id, login, name, workphone, workfax, workmobile, homephone, startdate, enddate, notes, role, sales, email, ssn, managerid, employeenumber, dob) select id, login, name, workphone, workfax, workmobile, homephone, startdate, enddate, notes, role, sales, email, ssn, managerid, employeenumber, dob from temp;
drop table temp;
create unique index employee_login_key on employee (login);
create index employee_name_key on employee (lower(name));
--
create table temp as select * from customer;
drop table customer;
CREATE TABLE customer (id int DEFAULT nextval('id') primary key, name varchar(64), contact varchar(64), phone varchar(20), fax varchar(20), email text, notes text, terms int2 DEFAULT 0, taxincluded bool DEFAULT 'f', customernumber varchar(32), cc text, bcc text, business_id int, taxnumber varchar(32), sic_code varchar(6), discount float4, creditlimit float DEFAULT 0, employee_id int, language_code varchar(6), pricegroup_id int, curr char(3), startdate date, enddate date, arap_accno_id int, payment_accno_id int, discount_accno_id int, cashdiscount float4, discountterms int2, threshold float, paymentmethod_id int, remittancevoucher bool);
insert into customer (id, name, contact, phone, fax, email, notes, terms, taxincluded, customernumber, cc, bcc, business_id, taxnumber, sic_code, discount, creditlimit, employee_id, language_code, pricegroup_id, curr, startdate, enddate, arap_accno_id, payment_accno_id, discount_accno_id, cashdiscount, discountterms, threshold, paymentmethod_id, remittancevoucher) select id, name, contact, phone, fax, email, notes, terms, taxincluded, customernumber, cc, bcc, business_id, taxnumber, sic_code, discount, creditlimit, employee_id, language_code, pricegroup_id, curr, startdate, enddate, arap_accno_id, payment_accno_id, discount_accno_id, cashdiscount, discountterms, threshold, paymentmethod_id, remittancevoucher from temp;
drop table temp;
create index customer_name_key on customer (lower(name));
create index customer_customernumber_key on customer (customernumber);
create index customer_contact_key on customer (lower(contact));
--
create table temp as select * from vendor;
drop table vendor;
CREATE TABLE vendor (id int DEFAULT nextval('id') primary key, name varchar(64), contact varchar(64), phone varchar(20), fax varchar(20), email text, notes text, terms int2 DEFAULT 0, taxincluded bool DEFAULT 'f', vendornumber varchar(32), cc text, bcc text, gifi_accno varchar(30), business_id int, taxnumber varchar(32), sic_code varchar(6), discount float4, creditlimit float DEFAULT 0, employee_id int, language_code varchar(6), pricegroup_id int, curr char(3), startdate date, enddate date, arap_accno_id int, payment_accno_id int, discount_accno_id int, cashdiscount float4, discountterms int2, threshold float, paymentmethod_id int, remittancevoucher bool);
insert into vendor (id, name, contact, phone, fax, email, notes, terms, taxincluded, vendornumber, cc, bcc, gifi_accno, business_id, taxnumber, sic_code, discount, creditlimit, employee_id, language_code, pricegroup_id, curr, startdate, enddate, arap_accno_id, payment_accno_id, discount_accno_id, cashdiscount, discountterms, threshold, paymentmethod_id, remittancevoucher) select id, name, contact, phone, fax, email, notes, terms, taxincluded, vendornumber, cc, bcc, gifi_accno, business_id, taxnumber, sic_code, discount, creditlimit, employee_id, language_code, pricegroup_id, curr, startdate, enddate, arap_accno_id, payment_accno_id, discount_accno_id, cashdiscount, discountterms, threshold, paymentmethod_id, remittancevoucher from temp;
drop table temp;
create index vendor_name_key on vendor (lower(name));
create index vendor_vendornumber_key on vendor (vendornumber);
create index vendor_contact_key on vendor (lower(contact));
--
alter table curr rename precision to prec;
--
update defaults set fldvalue = '2.9.1' where fldname = 'version';
