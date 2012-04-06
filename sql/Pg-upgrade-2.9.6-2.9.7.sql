--
create table pay_tran (trans_id int, id int, glid int, qty float, amount float);
--
insert into pay_tran (trans_id, id, glid) select trans_id, deduction_id, glid from pay_trans;
drop table pay_trans;
alter table pay_tran rename to pay_trans;
--
alter table employeededuction add id int;
--
create table wage (id int default nextval('id') primary key, description text, amount float, defer int, exempt bool default 'f', chart_id int);
--
create table payrate (trans_id int, id int, rate float, above float);
--
create table employeewage (id int, employee_id int, wage_id int);
--
update defaults set fldvalue = '2.9.7' where fldname = 'version';
