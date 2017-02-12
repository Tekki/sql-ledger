-- GERMAN Service Company COA
-- based on US_Service_Company modified by info@linuxandlanguages.com
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','AKTIVA','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1060','Bankkonto','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','Barkasse','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','Debitoren','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','Rückstellung für zweifelhafte Konten','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','INVENTAR AKTIVA','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','Inventar','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','KAPITAL AKTIVA','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','Büromöbel und Ausrüstung','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1825','Angesamm. Abschreib. Büromöbel und Ausr.','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','Fuhrpark','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1845','Accum. Amort. -Vehicle','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','VERBINDLICHKEITEN','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','Kreditoren','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','LANGFRISTIGE VERBINDLICHKEITEN','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','Bankkredite','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','Kredite von Anteilshabern','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','AKTIENKAPITAL','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','Normale Aktien','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3500','RÜCKGESTELLTE ERÖSE','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3590','Rückgestellte Erlöse aus vorherigen Jahren','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','BERATUNGSEINNAHME','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4010','Zeitlohn','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','Beratung','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','WEITERE Einnahmen','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4410','Verkauf - Allgemein','A','','I','AR_amount:IC_income:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','Zinsen','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Gewinn aus Auslandswährungsgeschäften','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','AUSGABEN','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020','Einkäufe','A','','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','LOHNAUSGABEN','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','Löhne und Gehälter','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','ALLGEMEINE UND ADMINISTRATIVE AUSGABEN','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','Buchführung und Recht','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','Werbungsaktionen','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5620','Nicht bezahlte Schulden','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','Aufwendungen für Abschreibung','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','Versicherung','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','Zinsen und Nebenkosten des Geldverkehrs','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','Büromaterial','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','Miete','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','Reparaturen & Wartung','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','Telefon','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','Reisen und Unterhaltung','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','Versorgungsdienste','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5795','Registrierungen','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5800','Lizenzen','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5810','Verluste Auslandswährung','A','','E','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2110','Angesammelte Einkommenssteuer - Bundesland','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2120','Angesammelte Einkommenssteuer - Staat','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2130','Angesammelte Steuer Franchis','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2140','Angesammelte Land und Eigentumssteuer','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2150','Vertriebssteur','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2210','Angesammelte Gehälter','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5510','Einkommenssteueraufwendungen - Bundesland','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5520','Einkommenssteueraufwendungen - Staat','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5530','Steuern - Land und Gebäuede','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5540','Steuern - Eigentum','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5550','Steuern - Franchise','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5560','Steuern - Ausland vorbehalten','A','','E','');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2150'),0.05);
--
INSERT INTO defaults (fldname, fldvalue) VALUES ('inventory_accno_id', (SELECT id FROM chart WHERE accno = '1520'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('income_accno_id', (SELECT id FROM chart WHERE accno = '4010'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('expense_accno_id', (SELECT id FROM chart WHERE accno = '5020'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('fxgain_accno_id', (SELECT id FROM chart WHERE accno = '4450'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('fxloss_accno_id', (SELECT id FROM chart WHERE accno = '5810'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('weightunit', 'kg');
INSERT INTO defaults (fldname, fldvalue) VALUES ('precision', '2');
--
INSERT INTO curr (rn, curr, prec) VALUES (1,'EUR',2);
INSERT INTO curr (rn, curr, prec) VALUES (2,'USD',2);

