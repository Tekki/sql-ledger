--
create sequence assemblyid;
alter table assembly add aid int;
alter table assembly alter id set default nextval('assemblyid');
update assembly set aid = id;
create table temp (id int default nextval('assemblyid'), aid int);
insert into temp (aid) select oid from assembly;
update assembly set id = temp.id from temp where assembly.oid = temp.aid;
drop table temp;
--
create sequence inventoryid;
alter table inventory add id int;
create table temp (id int default nextval('inventoryid'), iid int);
insert into temp (iid) select oid from inventory;
update inventory set id = temp.id from temp where inventory.oid = temp.iid;
drop table temp; 
alter table inventory alter id set default nextval('inventoryid');
--
insert into address (trans_id) select id from warehouse;
--
alter table parts add tariff_hscode text;
alter table parts add countryorigin text;
--
alter table invoice add lineitemdetail boolean;
alter table orderitems add lineitemdetail boolean;
--
alter table ar add column warehouse_id int;
alter table ap add column warehouse_id int;
alter table oe add column warehouse_id int;
--
create table defau (fldname text, fldvalue text);
insert into defau (fldname, fldvalue) values ('inventory_accno_id', (select inventory_accno_id from defaults));
insert into defau (fldname, fldvalue) values ('income_accno_id', (select income_accno_id from defaults));
insert into defau (fldname, fldvalue) values ('expense_accno_id', (select expense_accno_id from defaults));
insert into defau (fldname, fldvalue) values ('fxgain_accno_id', (select fxgain_accno_id from defaults));
insert into defau (fldname, fldvalue) values ('fxloss_accno_id', (select fxloss_accno_id from defaults));
insert into defau (fldname, fldvalue) values ('sinumber', (select sinumber from defaults));
insert into defau (fldname, fldvalue) values ('sonumber', (select sonumber from defaults));
insert into defau (fldname, fldvalue) values ('yearend', (select yearend from defaults));
insert into defau (fldname, fldvalue) values ('weightunit', (select weightunit from defaults));
insert into defau (fldname, fldvalue) values ('businessnumber', (select businessnumber from defaults));
insert into defau (fldname, fldvalue) values ('version', (select version from defaults));
insert into defau (fldname, fldvalue) values ('currencies', (select curr from defaults));
insert into defau (fldname, fldvalue) values ('closedto', (select closedto from defaults));
insert into defau (fldname, fldvalue) values ('revtrans', '0');
insert into defau (fldname, fldvalue) values ('ponumber', (select ponumber from defaults));
insert into defau (fldname, fldvalue) values ('sqnumber', (select sqnumber from defaults));
insert into defau (fldname, fldvalue) values ('rfqnumber', (select rfqnumber from defaults));
insert into defau (fldname, fldvalue) values ('audittrail', '0');
insert into defau (fldname, fldvalue) values ('vinumber', (select vinumber from defaults));
insert into defau (fldname, fldvalue) values ('employeenumber', (select employeenumber from defaults));
insert into defau (fldname, fldvalue) values ('partnumber', (select partnumber from defaults));
insert into defau (fldname, fldvalue) values ('customernumber', (select customernumber from defaults));
insert into defau (fldname, fldvalue) values ('vendornumber', (select vendornumber from defaults));
insert into defau (fldname, fldvalue) values ('glnumber', (select glnumber from defaults));
insert into defau (fldname, fldvalue) values ('projectnumber', (select projectnumber from defaults));
insert into defau (fldname, fldvalue) values ('vouchernumber', (select vouchernumber from defaults));
insert into defau (fldname, fldvalue) values ('batchnumber', (select batchnumber from defaults));
drop table defaults;
alter table defau rename to defaults;
--
drop trigger del_exchangerate on ar;
drop trigger del_exchangerate on ap;
drop trigger del_exchangerate on oe;
drop function del_exchangerate();
--
CREATE FUNCTION del_exchangerate() RETURNS OPAQUE AS '

declare
  t_transdate date;
  t_curr char(3);
  t_id int;
  d_curr text;

begin

  select into d_curr substr(fldvalue,1,3) from defaults where fldname = ''currencies'';

  if TG_RELNAME = ''ar'' then
    select into t_curr, t_transdate curr, transdate from ar where id = old.id;
  end if;
  if TG_RELNAME = ''ap'' then
    select into t_curr, t_transdate curr, transdate from ap where id = old.id;
  end if;
  if TG_RELNAME = ''oe'' then
    select into t_curr, t_transdate curr, transdate from oe where id = old.id;
  end if;

  if d_curr != t_curr then

    select into t_id a.id from acc_trans ac
    join ar a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate

    except select a.id from ar a where a.id = old.id

    union

    select a.id from acc_trans ac
    join ap a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate

    except select a.id from ap a where a.id = old.id

    union

    select o.id from oe o
    where o.curr = t_curr
    and o.transdate = t_transdate

    except select o.id from oe o where o.id = old.id;

    if not found then
      delete from exchangerate where curr = t_curr and transdate = t_transdate;
    end if;
  end if;
return old;

end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
update defaults set fldvalue = '2.7.6' where fldname = 'version';

