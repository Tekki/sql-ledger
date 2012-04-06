--
create table reference (id int, trans_id int, description text);
--
create table acsrole (id int default nextval('id') primary key, description text, acs text, rn int2);
insert into acsrole (description) select distinct role from employee where role != '';
create sequence tempid start 2;
update acsrole set rn = nextval('tempid');
drop sequence tempid;
update acsrole set rn = 1 where description = 'admin';
--
alter table employee rename managerid to acsrole_id;
update employee set acsrole_id = acsrole.id from acsrole where employee.role = acsrole.description;
--
create table temp as select * from employee;
drop table employee;
create table employee (id int primary key DEFAULT nextval('id'), login text, name varchar(64), workphone varchar(20), workfax varchar(20), workmobile varchar(20), homephone varchar(20), homemobile varchar(20), startdate date DEFAULT current_date, enddate date, notes text, sales bool DEFAULT 'f', email text, ssn varchar(20), employeenumber varchar(32), dob date, payperiod int2, apid int, paymentid int, paymentmethod_id int, acsrole_id int, acs text);
insert into employee (id, login, name, workphone, workfax, workmobile, homephone, startdate, enddate, notes, sales, email, ssn, employeenumber, dob, payperiod, apid, paymentid, paymentmethod_id, acsrole_id) select id, login, name, workphone, workfax, workmobile, homephone, startdate, enddate, notes, sales, email, ssn, employeenumber, dob, payperiod, apid, paymentid, paymentmethod_id, acsrole_id from temp;
drop table temp;
create unique index employee_login_key on employee (login);
create index employee_name_key on employee (lower(name));
--
update defaults set fldvalue = '2.9.8' where fldname = 'version';
