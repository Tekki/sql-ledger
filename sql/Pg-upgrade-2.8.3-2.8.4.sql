--
drop trigger del_exchangerate on ar;
drop trigger del_exchangerate on ap;
drop trigger del_exchangerate on oe;
drop function del_exchangerate();
--
drop trigger check_inventory on oe;
drop function check_inventory();
--
create sequence paymentid;
create table payment (id int not null, trans_id int not null, exchangerate float default 1, paymentmethod_id int);
update acc_trans set id = nextval('paymentid') from ar, chart where ar.id = acc_trans.trans_id and acc_trans.chart_id = chart.id and chart.link like '%paid%' and acc_trans.fx_transaction = '0' and acc_trans.id is null;
update acc_trans set id = nextval('paymentid') from ap, chart where ap.id = acc_trans.trans_id and acc_trans.chart_id = chart.id and chart.link like '%paid%' and acc_trans.fx_transaction = '0' and acc_trans.id is null;
drop sequence paymentid;
--
insert into payment (id, trans_id, exchangerate) select ac.id, a.id, ex.buy from acc_trans ac join ar a on (a.id = ac.trans_id) join exchangerate ex on (ex.curr = a.curr and a.transdate = ex.transdate) join chart c on (c.id = ac.chart_id) where ac.id > 0 and c.link like '%paid%' order by ac.id;
insert into payment (id, trans_id, exchangerate) select ac.id, a.id, ex.sell from acc_trans ac join ap a on (a.id = ac.trans_id) join exchangerate ex on (ex.curr = a.curr and a.transdate = ex.transdate) join chart c on (c.id = ac.chart_id) where ac.id > 0 and c.link like '%paid%' order by ac.id;
--
alter table ar add exchangerate float;
update ar set exchangerate = 1;
update ar set exchangerate = exchangerate.buy from exchangerate where ar.transdate = exchangerate.transdate and ar.curr = exchangerate.curr;
--
alter table ap add exchangerate float;
update ap set exchangerate = 1;
update ap set exchangerate = exchangerate.sell from exchangerate where ap.transdate = exchangerate.transdate and ap.curr = exchangerate.curr;
--
alter table oe add exchangerate float;
update oe set exchangerate = 1;
update oe set exchangerate = exchangerate.buy from exchangerate where oe.transdate = exchangerate.transdate and oe.curr = exchangerate.curr and oe.customer_id > 0;
update oe set exchangerate = exchangerate.sell from exchangerate where oe.transdate = exchangerate.transdate and oe.curr = exchangerate.curr and oe.vendor_id > 0;
--
alter table gl add curr char(3);
alter table gl add exchangerate float;
update gl set curr = (select substr(fldvalue,1,3) from defaults where fldname = 'currencies'), exchangerate = 1;
--
update defaults set fldvalue = '2.8.4' where fldname = 'version';

