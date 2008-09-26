--
-- change float4 to float
--
alter table invoice rename to temp;
CREATE TABLE invoice (
  id int DEFAULT nextval ('invoiceid') primary key,
  trans_id int not null,
  parts_id int not null,
  description text,
  qty float,
  allocated float,
  sellprice float,
  fxsellprice float,
  discount float4,
  assemblyitem bool DEFAULT 'f',
  unit varchar(5),
  project_id int,
  deliverydate date,
  serialnumber text,
  itemnotes text,
  lineitemdetail bool
);
insert into invoice (id, trans_id, parts_id, description, qty, allocated, sellprice, fxsellprice, discount, assemblyitem, unit, deliverydate, project_id, serialnumber, itemnotes, lineitemdetail) select id, trans_id, parts_id, description, qty, allocated, sellprice, fxsellprice, discount, assemblyitem, unit, deliverydate, project_id, serialnumber, itemnotes, lineitemdetail from temp;
drop table temp;
create index invoice_trans_id_key on invoice (trans_id);
--
alter table parts rename to temp;
--
CREATE TABLE parts (
  id int DEFAULT nextval ('id') primary key,
  partnumber text,
  description text,
  unit varchar(5),
  listprice float,
  sellprice float,
  lastcost float,
  priceupdate date DEFAULT current_date,
  weight float,
  onhand float DEFAULT 0,
  notes text,
  makemodel bool DEFAULT 'f',
  assembly bool DEFAULT 'f',
  alternate bool DEFAULT 'f',
  rop float,
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  bin text,
  obsolete bool DEFAULT 'f',
  bom bool DEFAULT 'f',
  image text,
  drawing text,
  microfiche text,
  partsgroup_id int,
  project_id int,
  avgcost float,
  tariff_hscode text,
  countryorigin text,
  barcode text,
  toolnumber text
);
--
insert into parts (id, partnumber, description, unit, listprice, sellprice, lastcost, priceupdate, weight, onhand, notes, makemodel, assembly, alternate, rop, inventory_accno_id, income_accno_id, expense_accno_id, bin, obsolete, bom, image, drawing, microfiche, partsgroup_id, project_id, avgcost, tariff_hscode, countryorigin, barcode, toolnumber) select id, partnumber, description, unit, listprice, sellprice, lastcost, priceupdate, weight, onhand, notes, makemodel, assembly, alternate, rop, inventory_accno_id, income_accno_id, expense_accno_id, bin, obsolete, bom, image, drawing, microfiche, partsgroup_id, project_id, avgcost, tariff_hscode, countryorigin, barcode, toolnumber from temp;
drop table temp;
create index parts_description_key on parts (lower(description));
create index parts_partnumber_key on parts (lower(partnumber));
--
--
alter table orderitems rename to temp;
CREATE TABLE orderitems (
  id int DEFAULT nextval('orderitemsid'),
  trans_id int not null,
  parts_id int not null,
  description text,
  qty float,
  sellprice float,
  discount float,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship float,
  serialnumber text,
  itemnotes text,
  lineitemdetail bool
);
insert into orderitems (id, trans_id, parts_id, description, qty, sellprice, discount, unit, project_id, reqdate, ship, serialnumber, itemnotes, lineitemdetail) select id, trans_id, parts_id, description, qty, sellprice, discount, unit, project_id, reqdate, ship, serialnumber, itemnotes, lineitemdetail from temp;
drop table temp;
create index orderitems_trans_id_key on orderitems (trans_id);
--
alter table inventory rename to temp;
CREATE TABLE inventory (
  id int DEFAULT nextval('inventoryid'),
  warehouse_id int,
  parts_id int not null,
  trans_id int,
  orderitems_id int,
  qty float,
  shippingdate date,
  employee_id int
);
insert into inventory (warehouse_id, parts_id, trans_id, orderitems_id, qty, shippingdate, employee_id, id) select warehouse_id, parts_id, trans_id, orderitems_id, qty, shippingdate, employee_id, id from temp;
drop table temp;
create index inventory_parts_id_key on inventory (parts_id);
--
alter table partscustomer rename to temp;
CREATE TABLE partscustomer (
  parts_id int not null,
  customer_id int not null,
  pricegroup_id int,
  pricebreak float,
  sellprice float,
  validfrom date,
  validto date,
  curr char(3)
);
insert into partscustomer (parts_id, customer_id, pricegroup_id, pricebreak, sellprice, validfrom, validto, curr) select parts_id, customer_id, pricegroup_id, pricebreak, sellprice, validfrom, validto, curr from temp;
drop table temp;
create index partscustomer_customer_id_key on partscustomer (customer_id);
create index partscustomer_parts_id_key on partscustomer (parts_id);

--
alter table jcitems rename to temp;
CREATE TABLE jcitems (
  id int DEFAULT nextval('jcitemsid') primary key,
  project_id int,
  parts_id int not null,
  description text,
  qty float,
  allocated float,
  sellprice float,
  fxsellprice float,
  serialnumber text,
  checkedin timestamp with time zone,
  checkedout timestamp with time zone,
  employee_id int,
  notes text
);
insert into jcitems (id, project_id, parts_id, description, qty, allocated, sellprice, fxsellprice, serialnumber, checkedin, checkedout, employee_id, notes) select id, project_id, parts_id, description, qty, allocated, sellprice, fxsellprice, serialnumber, checkedin, checkedout, employee_id, notes from temp;
drop table temp;
--
alter table cargo rename to temp;
CREATE TABLE cargo (
  id int not null,
  trans_id int not null,
  package text,
  netweight float,
  grossweight float,
  volume float
);
insert into cargo (id, trans_id, package, netweight, grossweight, volume) select id, trans_id, package, netweight, grossweight, volume from temp;
drop table temp;
create index cargo_id_key on cargo (id, trans_id);
--
update defaults set fldvalue = '2.7.12' where fldname = 'version';
