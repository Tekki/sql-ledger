--
alter table employee add payperiod int2;
alter table employee add apid int;
alter table employee add paymentid int;
alter table employee add paymentmethod_id int;
--
create table employeededuction (employee_id int, deduction_id int, exempt float, maximum float);
--
create table pay_trans (trans_id int, id int, deduction_id int, glid int);
--
create table deduction (id int default nextval('id') primary key, description text, employee_accno_id int, employeepays float4, employer_accno_id int, employerpays float4, fromage int2, toage int2, agedob bool, basedon int);
--
create table deduct (trans_id int, deduction_id int, withholding bool, percent float4);
--
create table deductionrate (rn int2, trans_id int, rate float, amount float, above float, below float);
--
update defaults set fldvalue = '2.9.5' where fldname = 'version';
