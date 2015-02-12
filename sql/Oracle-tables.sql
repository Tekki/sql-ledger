-- Oracle-tables.sql
-- Paulo Rodrigues: added functions and triggers, Oct. 31, 2001
-- 
-- Modified for use with SL 2.0 and Oracle 9i2, Dec 13, 2002
-- Updated to 2.3.0, Dec 18, 2003
--
-- Modified for use with SL 3.0, Oracle 11g, Mar 7, 2014
--
--
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
--
CREATE SEQUENCE id START WITH 10000 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT ID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE invoiceid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT INVOICEID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE orderitemsid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT ORDERITEMSID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE jcitemsid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT JCITEMSID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE addressid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT ADDRESSID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE assemblyid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT ASSEMBLYID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE inventoryid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT INVENTORYID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE contactid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT CONTACTID.NEXTVAL FROM DUAL;
--
CREATE TABLE makemodel (
  parts_id INTEGER,
  make VARCHAR2(256),
  model VARCHAR2(256)
);
--
CREATE TABLE gl (
  id INTEGER,
  reference VARCHAR2(128),
  description VARCHAR2(1024),
  transdate DATE DEFAULT SYSDATE,
  employee_id INTEGER,
  notes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0,
  approved CHAR(1) DEFAULT '1',
  curr CHAR(3),
  exchangerate FLOAT
);
--
CREATE TABLE chart (
  id INTEGER,
  accno VARCHAR2(32) NOT NULL,
  description VARCHAR2(128),
  charttype CHAR(1) DEFAULT 'A',
  category CHAR(1),
  link VARCHAR2(128),
  gifi_accno VARCHAR2(32),
  contra CHAR(1) DEFAULT '0'
);
--
CREATE TABLE gifi (
  accno VARCHAR2(32),
  description VARCHAR2(128)
);
--
CREATE TABLE defaults (
  fldname VARCHAR2(128),
  fldvalue VARCHAR2(4000)
);
INSERT INTO defaults (fldname, fldvalue) VALUES ('version', '3.0.0');
--
CREATE TABLE acc_trans (
  trans_id INTEGER,
  chart_id INTEGER,
  amount FLOAT,
  transdate DATE DEFAULT SYSDATE,
  source VARCHAR2(32),
  approved CHAR(1) DEFAULT '1',
  fx_transaction CHAR(1) DEFAULT '0',
  project_id INTEGER,
  memo VARCHAR2(256),
  id INTEGER,
  cleared DATE,
  vr_id INTEGER
);
--
CREATE TABLE invoice (
  id INTEGER,
  trans_id INTEGER,
  parts_id INTEGER,
  description VARCHAR2(1024),
  qty FLOAT,
  allocated FLOAT,
  sellprice FLOAT,
  fxsellprice FLOAT,
  discount FLOAT,
  assemblyitem CHAR(1) DEFAULT '0',
  unit VARCHAR2(5),
  project_id INTEGER,
  deliverydate DATE,
  serialnumber VARCHAR2(4000),
  itemnotes VARCHAR2(4000),
  lineitemdetail CHAR(1),
  ordernumber VARCHAR(64),
  ponumber VARCHAR(64)
);
--
CREATE TABLE customer (
  id INTEGER,
  name VARCHAR2(64),
  contact VARCHAR2(64),
  phone VARCHAR2(20),
  fax VARCHAR2(20),
  email VARCHAR2(64),
  notes VARCHAR2(4000),
  terms INTEGER DEFAULT 0,
  taxincluded CHAR(1) DEFAULT '0',
  customernumber VARCHAR2(32),
  cc VARCHAR2(64),
  bcc VARCHAR2(64),
  business_id INTEGER,
  taxnumber VARCHAR2(32),
  sic_code VARCHAR2(6),
  discount FLOAT,
  creditlimit FLOAT DEFAULT 0,
  employee_id INTEGER,
  language_code VARCHAR2(6),
  pricegroup_id INTEGER,
  curr CHAR(3),
  startdate DATE,
  enddate DATE,
  arap_accno_id INTEGER,
  payment_accno_id INTEGER,
  discount_accno_id INTEGER,
  cashdiscount FLOAT,
  discountterms INTEGER,
  threshold FLOAT,
  paymentmethod_id INTEGER,
  remittancevoucher CHAR(1)
);
--
CREATE TABLE parts (
  id INTEGER,
  partnumber VARCHAR2(256), 
  description VARCHAR2(4000),
  unit VARCHAR2(5),
  listprice FLOAT,
  sellprice FLOAT,
  lastcost FLOAT,
  priceupdate DATE DEFAULT SYSDATE,
  weight FLOAT,
  onhand FLOAT DEFAULT 0,
  notes VARCHAR2(4000),
  makemodel CHAR(1) DEFAULT '0',
  assembly CHAR(1) DEFAULT '0',
  alternate CHAR(1) DEFAULT '0',
  rop FLOAT,
  inventory_accno_id INTEGER,
  income_accno_id INTEGER,
  expense_accno_id INTEGER,
  bin VARCHAR2(64),
  obsolete CHAR(1) DEFAULT '0',
  bom CHAR(1) DEFAULT '0',
  image VARCHAR2(256),
  drawing VARCHAR2(256),
  microfiche VARCHAR2(256),
  partsgroup_id INTEGER,
  project_id INTEGER,
  avgcost FLOAT,
  tariff_hscode VARCHAR2(64),
  countryorigin VARCHAR2(64),
  barcode VARCHAR2(256),
  toolnumber VARCHAR2(256)
);
--
CREATE TABLE assembly (
  id INTEGER,
  parts_id INTEGER,
  qty FLOAT,
  bom CHAR(1),
  adj CHAR(1),
  aid INTEGER
);
--
CREATE TABLE ar (
  id INTEGER,
  invnumber VARCHAR2(64),
  transdate DATE DEFAULT SYSDATE,
  customer_id INTEGER,
  taxincluded CHAR(1),
  amount FLOAT,
  netamount FLOAT,
  paid FLOAT,
  datepaid DATE,
  duedate DATE,
  invoice CHAR(1) DEFAULT '0',
  shippingpoint VARCHAR2(256),
  terms INTEGER DEFAULT 0,
  notes VARCHAR2(4000),
  curr CHAR(3),
  ordnumber VARCHAR2(64),
  employee_id INTEGER,
  till VARCHAR2(20),
  quonumber VARCHAR2(64),
  intnotes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0,
  shipvia VARCHAR2(256),
  language_code VARCHAR2(6),
  ponumber VARCHAR2(64),
  approved CHAR(1) DEFAULT '1',
  cashdiscount FLOAT,
  discountterms INTEGER,
  waybill VARCHAR2(256),
  warehouse_id INTEGER,
  description VARCHAR2(256),
  onhold CHAR(1) DEFAULT '0',
  exchangerate FLOAT,
  dcn VARCHAR2(32),
  bank_id INTEGER,
  paymentmethod_id INTEGER
);
--
CREATE TABLE ap (
  id INTEGER,
  invnumber VARCHAR2(64),
  transdate DATE DEFAULT SYSDATE,
  vendor_id INTEGER,
  taxincluded CHAR(1) DEFAULT '0',
  amount FLOAT,
  netamount FLOAT,
  paid FLOAT,
  datepaid DATE,
  duedate DATE,
  invoice CHAR(1) DEFAULT '0',
  ordnumber VARCHAR2(64),
  curr CHAR(3),
  notes VARCHAR2(4000),
  employee_id INTEGER,
  till VARCHAR2(20),
  quonumber VARCHAR2(64),
  intnotes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0,
  shipvia VARCHAR2(256),
  language_code VARCHAR2(6),
  ponumber VARCHAR2(64),
  shippingpoint VARCHAR2(256),
  terms INTEGER DEFAULT 0,
  approved CHAR(1) DEFAULT '1',
  cashdiscount FLOAT,
  discountterms INTEGER,
  waybill VARCHAR2(256),
  warehouse_id INTEGER,
  description VARCHAR2(256),
  onhold CHAR(1) DEFAULT '0',
  exchangerate FLOAT,
  dcn VARCHAR2(32),
  bank_id INTEGER,
  paymentmethod_id INTEGER
);
--
CREATE TABLE partstax (
  parts_id INTEGER,
  chart_id INTEGER
);
--
CREATE TABLE tax (
  chart_id INTEGER,
  rate FLOAT,
  taxnumber VARCHAR2(30),
  validto DATE
);
--
CREATE TABLE customertax (
  customer_id INTEGER,
  chart_id INTEGER
);
--
CREATE TABLE vendortax (
  vendor_id INTEGER,
  chart_id INTEGER
);
--
CREATE TABLE oe (
  id INTEGER,
  ordnumber VARCHAR2(64),
  transdate DATE DEFAULT SYSDATE,
  vendor_id INTEGER,
  customer_id INTEGER,
  amount FLOAT,
  netamount FLOAT,
  reqdate DATE,
  taxincluded CHAR(1),
  shippingpoint VARCHAR2(256),
  notes VARCHAR2(4000),
  curr CHAR(3),
  employee_id INTEGER,
  closed CHAR(1) DEFAULT '0',
  quotation CHAR(1) DEFAULT '0',
  quonumber VARCHAR2(64),
  intnotes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0,
  shipvia VARCHAR2(256),
  language_code VARCHAR2(6),
  ponumber VARCHAR2(64),
  terms INTEGER DEFAULT 0,
  waybill VARCHAR2(256),
  warehouse_id INTEGER,
  description VARCHAR2(256),
  aa_id INTEGER,
  exchangerate FLOAT
);
--
CREATE TABLE orderitems (
  id INTEGER,
  trans_id INTEGER,
  parts_id INTEGER,
  description VARCHAR2(4000),
  qty FLOAT,
  sellprice FLOAT,
  discount FLOAT,
  unit VARCHAR2(5),
  project_id INTEGER,
  reqdate DATE,
  ship FLOAT,
  serialnumber VARCHAR2(4000),
  itemnotes VARCHAR2(4000),
  lineitemdetail CHAR(1),
  ordernumber VARCHAR2(64),
  ponumber VARCHAR2(64)
);
--
CREATE TABLE exchangerate (
  curr CHAR(3),
  transdate DATE,
  exchangerate FLOAT
);
--
CREATE TABLE employee (
  id INTEGER,
  login VARCHAR2(64),
  name VARCHAR2(64),
  workphone VARCHAR2(20),
  workfax VARCHAR2(20),
  workmobile VARCHAR2(20),
  homephone VARCHAR2(20),
  homemobile VARCHAR2(20),
  startdate DATE DEFAULT SYSDATE,
  enddate DATE,
  notes VARCHAR2(4000),
  sales CHAR(1) DEFAULT '0',
  email VARCHAR2(64),
  ssn VARCHAR2(20),
  employeenumber VARCHAR2(32),
  dob DATE,
  payperiod INTEGER,
  apid INTEGER,
  paymentid INTEGER,
  paymentmethod_id INTEGER,
  acsrole_id INTEGER,
  acs VARCHAR2(4000)
);
--
CREATE TABLE shipto (
  trans_id INTEGER,
  shiptoname VARCHAR2(64),
  shiptoaddr1 VARCHAR2(32),
  shiptoaddr2 VARCHAR2(32),
  shiptocity VARCHAR2(32),
  shiptostate VARCHAR2(32),
  shiptozipcode VARCHAR2(10),
  shiptocountry VARCHAR2(32),
  shiptocontact VARCHAR2(64),
  shiptophone VARCHAR2(20),
  shiptofax VARCHAR2(20),
  shiptoemail VARCHAR2(64)
);
--
CREATE TABLE vendor (
  id INTEGER,
  name VARCHAR2(64),
  contact VARCHAR2(64),
  phone VARCHAR2(20),
  fax VARCHAR2(20),
  email VARCHAR2(64),
  notes VARCHAR2(4000),
  terms INTEGER DEFAULT 0,
  taxincluded CHAR(1) DEFAULT '0',
  vendornumber VARCHAR2(32),
  cc VARCHAR2(64),
  bcc VARCHAR2(64),
  gifi_accno VARCHAR2(30),
  business_id INTEGER,
  taxnumber VARCHAR2(32),
  sic_code VARCHAR2(6),
  discount FLOAT,
  creditlimit FLOAT DEFAULT 0,
  employee_id INTEGER,
  language_code VARCHAR2(6),
  pricegroup_id INTEGER,
  curr CHAR(3),
  startdate DATE,
  enddate DATE,
  arap_accno_id INTEGER,
  payment_accno_id INTEGER,
  discount_accno_id INTEGER,
  cashdiscount FLOAT,
  discountterms INTEGER,
  threshold FLOAT,
  paymentmethod_id INTEGER,
  remittancevoucher CHAR(1)
);
--
CREATE TABLE project (
  id INTEGER,
  projectnumber VARCHAR2(64),
  description VARCHAR2(4000),
  startdate DATE,
  enddate DATE,
  parts_id INTEGER,
  production FLOAT DEFAULT 0,
  completed FLOAT DEFAULT 0,
  customer_id INTEGER
);
--
CREATE TABLE partsgroup (
  id INTEGER,
  partsgroup VARCHAR2(256),
  pos CHAR(1) DEFAULT '1',
  code VARCHAR2(256),
  image VARCHAR2(256)
);
--
CREATE TABLE status (
  trans_id INTEGER,
  formname VARCHAR2(64),
  printed CHAR(1) DEFAULT 0,
  emailed CHAR(1) DEFAULT 0,
  spoolfile VARCHAR2(32)
);
--
CREATE TABLE department (
  id INTEGER,
  description VARCHAR2(256),
  role CHAR(1) DEFAULT 'P'
);
--
-- department transaction table
CREATE TABLE dpt_trans (
  trans_id INTEGER,
  department_id INTEGER
);
--
-- business table
CREATE TABLE business (
  id INTEGER,
  description VARCHAR2(256),
  discount FLOAT
);
-- SIC
CREATE TABLE sic (
  code VARCHAR2(6),
  sictype CHAR(1),
  description VARCHAR2(256)
);
--
CREATE TABLE warehouse (
  id INTEGER,
  description VARCHAR2(256)
);
--
CREATE TABLE inventory (
  id INTEGER,
  warehouse_id INTEGER,
  parts_id INTEGER,
  trans_id INTEGER,
  orderitems_id INTEGER,
  qty FLOAT,
  shippingdate DATE,
  employee_id INTEGER
);
--
CREATE TABLE yearend (
  trans_id INTEGER,
  transdate DATE
);
--
CREATE TABLE partsvendor (
  vendor_id INTEGER,
  parts_id INTEGER,
  partnumber VARCHAR2(256),
  leadtime INTEGER,
  lastcost FLOAT,
  curr CHAR(3)
);
--
CREATE TABLE pricegroup (
  id INTEGER,
  pricegroup VARCHAR2(256)
);
--
CREATE TABLE partscustomer (
  parts_id INTEGER,
  customer_id INTEGER,
  pricegroup_id INTEGER,
  pricebreak FLOAT,
  sellprice FLOAT,
  validfrom DATE,
  validto DATE,
  curr CHAR(3)
);
--
CREATE TABLE language (
  code VARCHAR2(6),
  description VARCHAR2(64)
);
--
CREATE TABLE audittrail (
  trans_id INTEGER,
  tablename VARCHAR2(32),
  reference VARCHAR2(64),
  formname VARCHAR2(32),
  action VARCHAR2(32),
  transdate TIMESTAMP WITH LOCAL TIME ZONE DEFAULT SYSDATE,
  employee_id INTEGER
);
--
CREATE TABLE translation (
  trans_id INTEGER,
  language_code VARCHAR2(6),
  description VARCHAR2(4000)
);
--
CREATE TABLE recurring (
  id INTEGER,
  reference VARCHAR2(64),
  startdate DATE,
  nextdate DATE,
  enddate DATE,
  repeat INTEGER,
  unit VARCHAR2(6),
  howmany INTEGER,
  payment CHAR(1) DEFAULT '0',
  description VARCHAR2(256)
);
--
CREATE TABLE recurringemail (
  id INTEGER,
  formname VARCHAR2(64),
  format VARCHAR2(10),
  message VARCHAR2(4000)
);
--
CREATE TABLE recurringprint (
  id INTEGER,
  formname VARCHAR2(64),
  format VARCHAR2(10),
  printer VARCHAR2(64)
);
--
CREATE TABLE jcitems (
  id INTEGER,
  project_id INTEGER,
  parts_id INTEGER,
  description VARCHAR2(4000),
  qty FLOAT,
  allocated FLOAT,
  sellprice FLOAT,
  fxsellprice FLOAT,
  serialnumber VARCHAR2(4000),
  checkedin TIMESTAMP WITH LOCAL TIME ZONE,
  checkedout TIMESTAMP WITH LOCAL TIME ZONE,
  employee_id INTEGER,
  notes VARCHAR2(4000)
);
--
CREATE TABLE cargo (
  id INTEGER NOT NULL,
  trans_id INTEGER NOT NULL,
  package VARCHAR2(256),
  netweight FLOAT,
  grossweight FLOAT,
  volume FLOAT
);
--
CREATE TABLE br (
  id INTEGER PRIMARY KEY,
  batchnumber VARCHAR2(64),
  description VARCHAR2(256),
  batch VARCHAR2(256),
  transdate DATE DEFAULT SYSDATE,
  apprdate DATE,
  amount FLOAT,
  managerid INTEGER,
  employee_id INTEGER
);
--
CREATE TABLE vr (
  br_id INTEGER REFERENCES br (id) ON DELETE CASCADE,
  trans_id INTEGER NOT NULL,
  id INTEGER NOT NULL,
  vouchernumber VARCHAR2(64)
);
--
CREATE TABLE semaphore (
  id INTEGER,
  login VARCHAR2(64),
  module VARCHAR2(64),
  expires VARCHAR2(10)
);
--
CREATE TABLE address (
  id INTEGER PRIMARY KEY,
  trans_id INTEGER,
  address1 VARCHAR2(32),
  address2 VARCHAR2(32),
  city VARCHAR2(32),
  state VARCHAR2(32),
  zipcode VARCHAR2(10),
  country VARCHAR2(32)
);
--
CREATE TABLE contact (
  id INTEGER PRIMARY KEY,
  trans_id INTEGER NOT NULL,
  salutation VARCHAR2(32),
  firstname VARCHAR2(32),
  lastname VARCHAR2(32),
  contacttitle VARCHAR2(32),
  occupation VARCHAR2(32),
  phone VARCHAR2(20),
  fax VARCHAR2(20),
  mobile VARCHAR2(20),
  email VARCHAR(64),
  gender CHAR(1) DEFAULT 'M',
  parent_id INTEGER,
  typeofcontact VARCHAR2(20)
);
--
CREATE TABLE paymentmethod (
  id INTEGER PRIMARY KEY,
  description VARCHAR2(128),
  fee FLOAT,
  rn INTEGER,
  roundchange FLOAT
);
--
CREATE TABLE bank (
  id INTEGER,
  name VARCHAR2(64),
  iban VARCHAR2(34),
  bic VARCHAR2(11),
  address_id INTEGER,
  dcn VARCHAR2(64),
  rvc VARCHAR2(512),
  membernumber VARCHAR2(64),
  clearingnumber VARCHAR2(64)
);
--
CREATE TABLE payment (
  id INTEGER NOT NULL,
  trans_id INTEGER NOT NULL,
  exchangerate FLOAT DEFAULT 1,
  paymentmethod_id INTEGER
);
--
CREATE TABLE curr (
  rn INTEGER,
  curr CHAR(3) PRIMARY KEY,
  prec INTEGER 
);
--
CREATE TABLE report (
  reportid INTEGER PRIMARY KEY,
  reportcode VARCHAR2(64),
  reportdescription VARCHAR2(256),
  login VARCHAR2(64)
);
--
CREATE TABLE reportvars (
  reportid INTEGER NOT NULL,
  reportvariable VARCHAR2(128),
  reportvalue VARCHAR2(4000)
);
--
CREATE TABLE employeededuction (
  id INTEGER,
  employee_id INTEGER,
  deduction_id INTEGER,
  exempt FLOAT,
  maximum FLOAT
);
--
CREATE TABLE pay_trans (
  trans_id INTEGER,
  id INTEGER,
  glid INTEGER,
  qty FLOAT,
  amount FLOAT
);
--
CREATE TABLE deduction (
  id INTEGER PRIMARY KEY,
  description VARCHAR2(128),
  employee_accno_id INTEGER,
  employeepays FLOAT,
  employer_accno_id INTEGER,
  employerpays FLOAT,
  fromage INTEGER,
  toage INTEGER,
  agedob CHAR(1),
  basedon INTEGER
);
--
CREATE TABLE deduct (
  trans_id INTEGER,
  deduction_id INTEGER,
  withholding CHAR(1),
  percent FLOAT
);
--
CREATE TABLE deductionrate (
  rn INTEGER,
  trans_id INTEGER,
  rate FLOAT,
  amount FLOAT,
  above FLOAT,
  below FLOAT
);
--
CREATE TABLE wage (
  id INTEGER PRIMARY KEY,
  description VARCHAR2(128),
  amount FLOAT,
  defer INTEGER,
  exempt CHAR(1) DEFAULT '0',
  chart_id INTEGER
);
--
CREATE TABLE payrate (
  trans_id INTEGER,
  id INTEGER,
  rate FLOAT,
  above FLOAT
);
--
CREATE TABLE employeewage (
  id INTEGER,
  employee_id INTEGER,
  wage_id INTEGER
);
--
CREATE TABLE reference (
  id INTEGER,
  trans_id INTEGER,
  description VARCHAR2(256)
);
--
CREATE TABLE acsrole (
  id INTEGER PRIMARY KEY,
  description VARCHAR2(64),
  acs VARCHAR2(4000),
  rn INTEGER
);
-- functions
--
CREATE OR REPLACE FUNCTION current_date RETURN date AS
BEGIN
  return(sysdate);--
END;;
--
-- triggers
--
CREATE OR REPLACE TRIGGER glid BEFORE INSERT ON gl FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER chartid BEFORE INSERT ON chart FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER invoiceid BEFORE INSERT ON invoice FOR EACH ROW
BEGIN
  SELECT invoiceid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER customerid BEFORE INSERT ON customer FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER partsid BEFORE INSERT ON parts FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER assemblyid BEFORE INSERT ON assembly FOR EACH ROW
BEGIN
  SELECT assemblyid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER arid BEFORE INSERT ON ar FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER apid BEFORE INSERT ON ap FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER oeid BEFORE INSERT ON oe FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER orderitemsid BEFORE INSERT ON orderitems FOR EACH ROW
BEGIN
  SELECT orderitemsid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER employeeid BEFORE INSERT ON employee FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER vendorid BEFORE INSERT ON vendor FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER projectid BEFORE INSERT ON project FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER partsgroupid BEFORE INSERT ON partsgroup FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER departmentid BEFORE INSERT ON department FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER businessid BEFORE INSERT ON business FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER warehouseid BEFORE INSERT ON warehouse FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER inventoryid BEFORE INSERT ON inventory FOR EACH ROW
BEGIN
  SELECT inventoryid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER pricegroupid BEFORE INSERT ON pricegroup FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER jcitemsid BEFORE INSERT ON jcitems FOR EACH ROW
BEGIN
  SELECT jcitemsid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER brid BEFORE INSERT ON br FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER vrid BEFORE INSERT ON vr FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER addressid BEFORE INSERT ON address FOR EACH ROW
BEGIN
  SELECT addressid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER contactid BEFORE INSERT ON contact FOR EACH ROW
BEGIN
  SELECT contactid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER paymentmethodid BEFORE INSERT ON paymentmethod FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER bankaddressid BEFORE INSERT ON bank FOR EACH ROW
BEGIN
  SELECT addressid.nextval
  INTO :new.address_id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER reportid BEFORE INSERT ON report FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.reportid
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER deductionid BEFORE INSERT ON deduction FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER wageid BEFORE INSERT ON wage FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER acsroleid BEFORE INSERT ON acsrole FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;

