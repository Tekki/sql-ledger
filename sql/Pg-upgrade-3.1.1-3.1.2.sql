--
alter table customer add prepayment_accno_id int;
alter table vendor add prepayment_accno_id int;
--
alter table invoice add kititem bool;
alter table invoice alter kititem set default '0';
update invoice set kititem = '0';
--
update defaults set fldvalue = '3.1.2' where fldname = 'version';

