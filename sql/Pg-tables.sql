--
CREATE SEQUENCE id start 10000;
SELECT nextval('id');
--
CREATE SEQUENCE invoiceid;
SELECT nextval('invoiceid');
--
CREATE SEQUENCE orderitemsid;
SELECT nextval('orderitemsid');
--
CREATE SEQUENCE jcitemsid;
SELECT nextval('jcitemsid');
--
CREATE SEQUENCE addressid;
SELECT nextval('addressid');
--
CREATE SEQUENCE assemblyid;
SELECT nextval('assemblyid');
--
CREATE SEQUENCE inventoryid;
SELECT nextval('inventoryid');
--
CREATE SEQUENCE contactid;
SELECT nextval('contactid');
--
CREATE SEQUENCE referenceid;
SELECT nextval('referenceid');
--
CREATE SEQUENCE archiveid;
SELECT nextval('archiveid');
--
CREATE TABLE makemodel (
  parts_id int,
  make text,
  model text
);
--
CREATE TABLE gl (
  id int DEFAULT nextval('id'),
  reference text,
  description text,
  transdate date DEFAULT current_date,
  employee_id int,
  notes text,
  department_id int DEFAULT 0,
  approved bool DEFAULT 't',
  curr char(3),
  exchangerate float
);
--
CREATE TABLE chart (
  id int DEFAULT nextval('id'),
  accno text NOT NULL,
  description text,
  charttype char(1) DEFAULT 'A',
  category char(1),
  link text,
  gifi_accno text,
  contra bool DEFAULT 'f',
  closed bool DEFAULT 'f'
);
--
CREATE TABLE gifi (
  accno text,
  description text
);
--
CREATE TABLE defaults (
  fldname text,
  fldvalue text
);
--
INSERT INTO defaults (fldname, fldvalue) VALUES ('version', '3.2.0');
--
CREATE TABLE acc_trans (
  trans_id int,
  chart_id int,
  amount float,
  transdate date DEFAULT current_date,
  source text,
  approved bool DEFAULT 't',
  fx_transaction bool DEFAULT 'f',
  project_id int,
  memo text,
  id int,
  cleared date,
  vr_id int
);
--
CREATE TABLE invoice (
  id int DEFAULT nextval('invoiceid') primary key,
  trans_id int,
  parts_id int,
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
  lineitemdetail bool,
  ordernumber text,
  ponumber text,
  cost float,
  vendor text,
  vendor_id int,
  kititem bool DEFAULT 'f'
);
--
CREATE TABLE customer (
  id int DEFAULT nextval('id') primary key,
  name varchar(64),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  terms int2 DEFAULT 0,
  taxincluded bool DEFAULT 'f',
  customernumber varchar(32),
  cc text,
  bcc text,
  business_id int,
  taxnumber varchar(32),
  sic_code varchar(6),
  discount float4,
  creditlimit float DEFAULT 0,
  employee_id int,
  language_code varchar(6),
  pricegroup_id int,
  curr char(3),
  startdate date,
  enddate date,
  arap_accno_id int,
  payment_accno_id int,
  discount_accno_id int,
  cashdiscount float4,
  discountterms int2,
  threshold float,
  paymentmethod_id int,
  remittancevoucher bool,
  prepayment_accno_id int
);
--
CREATE TABLE parts (
  id int DEFAULT nextval('id'),
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
CREATE TABLE assembly (
  id int DEFAULT nextval('assemblyid'),
  parts_id int,
  qty float,
  bom bool,
  adj bool,
  aid int
);
--
CREATE TABLE ar (
  id int DEFAULT nextval('id'),
  invnumber text,
  transdate date DEFAULT current_date,
  customer_id int,
  taxincluded bool,
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  shippingpoint text,
  terms int2 DEFAULT 0,
  notes text,
  curr char(3),
  ordnumber text,
  employee_id int,
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int DEFAULT 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  approved bool DEFAULT 't',
  cashdiscount float4,
  discountterms int2,
  waybill text,
  warehouse_id int,
  description text,
  onhold bool DEFAULT 'f',
  exchangerate float,
  dcn text,
  bank_id int,
  paymentmethod_id int
);
--
CREATE TABLE ap (
  id int DEFAULT nextval('id'),
  invnumber text,
  transdate date DEFAULT current_date,
  vendor_id int,
  taxincluded bool DEFAULT 'f',
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  ordnumber text,
  curr char(3),
  notes text,
  employee_id int,
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int DEFAULT 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  shippingpoint text,
  terms int2 DEFAULT 0,
  approved bool DEFAULT 't',
  cashdiscount float4,
  discountterms int2,
  waybill text,
  warehouse_id int,
  description text,
  onhold bool DEFAULT 'f',
  exchangerate float,
  dcn text,
  bank_id int,
  paymentmethod_id int
);
--
CREATE TABLE partstax (
  parts_id int,
  chart_id int
);
--
CREATE TABLE tax (
  chart_id int,
  rate float,
  taxnumber text,
  validto date
);
--
CREATE TABLE customertax (
  customer_id int,
  chart_id int
);
--
CREATE TABLE vendortax (
  vendor_id int,
  chart_id int
);
--
CREATE TABLE oe (
  id int DEFAULT nextval('id'),
  ordnumber text,
  transdate date DEFAULT current_date,
  vendor_id int,
  customer_id int,
  amount float,
  netamount float,
  reqdate date,
  taxincluded bool,
  shippingpoint text,
  notes text,
  curr char(3),
  employee_id int,
  closed bool DEFAULT 'f',
  quotation bool DEFAULT 'f',
  quonumber text,
  intnotes text,
  department_id int DEFAULT 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  terms int2 DEFAULT 0,
  waybill text,
  warehouse_id int,
  description text,
  aa_id int,
  exchangerate float
);
--
CREATE TABLE orderitems (
  id int DEFAULT nextval('orderitemsid'),
  trans_id int,
  parts_id int,
  description text,
  qty float,
  sellprice float,
  discount float4,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship float,
  serialnumber text,
  itemnotes text,
  lineitemdetail bool,
  ordernumber text,
  ponumber text,
  cost float,
  vendor text,
  vendor_id int
);
--
CREATE TABLE exchangerate (
  curr char(3),
  transdate date,
  exchangerate float
);
--
CREATE TABLE employee (
  id int primary key DEFAULT nextval('id'),
  login text,
  name varchar(64),
  workphone varchar(20),
  workfax varchar(20),
  workmobile varchar(20),
  homephone varchar(20),
  homemobile varchar(20),
  startdate date DEFAULT current_date,
  enddate date,
  notes text,
  sales bool DEFAULT 'f',
  email text,
  ssn varchar(20),
  employeenumber varchar(32),
  dob date,
  payperiod int2,
  apid int,
  paymentid int,
  paymentmethod_id int,
  acsrole_id int,
  acs text
);
--
CREATE TABLE shipto (
  trans_id int,
  shiptoname varchar(64),
  shiptoaddress1 varchar(32),
  shiptoaddress2 varchar(32),
  shiptocity varchar(32),
  shiptostate varchar(32),
  shiptozipcode varchar(10),
  shiptocountry varchar(32),
  shiptocontact varchar(64),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);
--
CREATE TABLE vendor (
  id int DEFAULT nextval('id') primary key,
  name varchar(64),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  terms int2 DEFAULT 0,
  taxincluded bool DEFAULT 'f',
  vendornumber varchar(32),
  cc text,
  bcc text,
  gifi_accno varchar(30),
  business_id int,
  taxnumber varchar(32),
  sic_code varchar(6),
  discount float4,
  creditlimit float DEFAULT 0,
  employee_id int,
  language_code varchar(6),
  pricegroup_id int,
  curr char(3),
  startdate date,
  enddate date,
  arap_accno_id int,
  payment_accno_id int,
  discount_accno_id int,
  cashdiscount float4,
  discountterms int2,
  threshold float,
  paymentmethod_id int,
  remittancevoucher bool,
  prepayment_accno_id int
);
--
CREATE TABLE project (
  id int DEFAULT nextval('id'),
  projectnumber text,
  description text,
  startdate date,
  enddate date,
  parts_id int,
  production float DEFAULT 0,
  completed float DEFAULT 0,
  customer_id int
);
--
CREATE TABLE partsgroup (
  id int DEFAULT nextval('id'),
  partsgroup text,
  pos bool DEFAULT 't',
  code text,
  image text
);
--
CREATE TABLE status (
  trans_id int,
  formname text,
  printed bool DEFAULT 'f',
  emailed bool DEFAULT 'f',
  spoolfile text
);
--
CREATE TABLE department (
  id int DEFAULT nextval('id'),
  description text,
  role char(1) DEFAULT 'P',
  rn int
);
--
-- department transaction table
CREATE TABLE dpt_trans (
  trans_id int,
  department_id int
);
--
-- business table
CREATE TABLE business (
  id int DEFAULT nextval('id'),
  description text,
  discount float4,
  rn int
);
--
-- SIC
CREATE TABLE sic (
  code varchar(6),
  sictype char(1),
  description text
);
--
CREATE TABLE warehouse (
  id int DEFAULT nextval('id'),
  description text,
  rn int
);
--
CREATE TABLE inventory (
  id int DEFAULT nextval('inventoryid'),
  warehouse_id int,
  parts_id int,
  trans_id int,
  orderitems_id int,
  qty float,
  shippingdate date,
  employee_id int
);
--
CREATE TABLE yearend (
  trans_id int,
  transdate date
);
--
CREATE TABLE partsvendor (
  vendor_id int,
  parts_id int,
  partnumber text,
  leadtime int2,
  lastcost float,
  curr char(3)
);
--
CREATE TABLE pricegroup (
  id int DEFAULT nextval('id'),
  pricegroup text
);
--
CREATE TABLE partscustomer (
  parts_id int,
  customer_id int,
  pricegroup_id int,
  pricebreak float,
  sellprice float,
  validfrom date,
  validto date,
  curr char(3)
);
--
CREATE TABLE language (
  code varchar(6),
  description text
);
--
CREATE TABLE audittrail (
  trans_id int,
  tablename text,
  reference text,
  formname text,
  action text,
  transdate timestamp DEFAULT current_timestamp,
  employee_id int
);
--
CREATE TABLE translation (
  trans_id int,
  language_code varchar(6),
  description text
);
--
CREATE TABLE recurring (
  id int,
  reference text,
  startdate date,
  nextdate date,
  enddate date,
  repeat int2,
  unit varchar(6),
  howmany int,
  payment bool DEFAULT 'f',
  description text
);
--
CREATE TABLE recurringemail (
  id int,
  formname text,
  format text,
  message text
);
--
CREATE TABLE recurringprint (
  id int,
  formname text,
  format text,
  printer text
);
--
CREATE TABLE jcitems (
  id int DEFAULT nextval('jcitemsid'),
  project_id int,
  parts_id int,
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
--
CREATE TABLE cargo (
  id int not null,
  trans_id int not null,
  package text,
  netweight float,
  grossweight float,
  volume float
);
--
CREATE TABLE br (
  id int DEFAULT nextval('id') primary key,
  batchnumber text,
  description text,
  batch text,
  transdate date DEFAULT current_date,
  apprdate date,
  amount float,
  managerid int,
  employee_id int
);
--
CREATE TABLE vr (
  br_id int references br (id) on delete cascade,
  trans_id int not null,
  id int not null DEFAULT nextval('id'),
  vouchernumber text
);
--
CREATE TABLE semaphore (
  id int,
  login text,
  module text,
  expires varchar(10)
);
--
CREATE TABLE address (
  id int DEFAULT nextval('addressid') primary key,
  trans_id int,
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32)
);
--
CREATE TABLE contact (
  id int default nextval('contactid') primary key,
  trans_id int not null,
  salutation varchar(32),
  firstname varchar(32),
  lastname varchar(32),
  contacttitle varchar(32),
  occupation varchar(32),
  phone varchar(20),
  fax varchar(20),
  mobile varchar(20),
  email text,
  gender char(1) default 'M',
  parent_id int,
  typeofcontact varchar(20)
);
--
CREATE TABLE paymentmethod (
  id int primary key default nextval('id'),
  description text,
  fee float,
  rn int,
  roundchange float4
);
--
CREATE TABLE bank (
  id int,
  name varchar(64),
  iban varchar(34),
  bic varchar(11),
  address_id int default nextval('addressid'),
  dcn text,
  rvc text,
  membernumber text,
  clearingnumber text
);
--
CREATE TABLE payment (
  id int not null,
  trans_id int not null,
  exchangerate float default 1,
  paymentmethod_id int
);
--
CREATE TABLE curr (
  rn int2,
  curr char(3) primary key,
  prec int2
);
--
CREATE TABLE report (
  reportid int primary key default nextval('id'),
  reportcode text,
  reportdescription text,
  login text
);
--
CREATE TABLE reportvars (
  reportid int not null,
  reportvariable text,
  reportvalue text
);
--
CREATE TABLE employeededuction (
  id int,
  employee_id int,
  deduction_id int,
  exempt float,
  maximum float
);
--
CREATE TABLE pay_trans (
  trans_id int,
  id int,
  glid int,
  qty float,
  amount float
);
--
CREATE TABLE deduction (
  id int default nextval('id') primary key,
  description text,
  employee_accno_id int,
  employeepays float4,
  employer_accno_id int,
  employerpays float4,
  fromage int2,
  toage int2,
  agedob bool,
  basedon int
);
--
CREATE TABLE deduct (
  trans_id int,
  deduction_id int,
  withholding bool,
  percent float4
);
--
CREATE TABLE deductionrate (
  rn int2,
  trans_id int,
  rate float,
  amount float,
  above float,
  below float
);
--
CREATE TABLE wage (
  id int default nextval('id') primary key,
  description text,
  amount float,
  defer int,
  exempt bool default 'f',
  chart_id int
);
--
CREATE TABLE payrate (
  trans_id int,
  id int,
  rate float,
  above float
);
--
CREATE TABLE employeewage (
  id int,
  employee_id int,
  wage_id int
);
--
CREATE TABLE reference (
  id int default nextval('referenceid') primary key,
  code text,
  trans_id int,
  description text,
  archive_id int,
  login text,
  formname text,
  folder text
);
--
CREATE TABLE acsrole (
  id int default nextval('id') primary key,
  description text,
  acs text,
  rn int2
);
--
CREATE TABLE archive (
  id int default nextval('archiveid') primary key,
  filename text
);
--
CREATE TABLE archivedata (
  archive_id int references archive (id) on delete cascade,
  bt text
);
--
CREATE TABLE mimetype (
  extension varchar(32) primary key,
  contenttype varchar(64)
);
--
