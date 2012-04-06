-- General COA
--
SET client_encoding = 'ISO-8859-1';
--
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('420','B�roeinrichtung','A','A','','420');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('430','Ladeneinrichtung','A','A','','430');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('440','Werkzeuge','A','A','','440');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('450','Einbauten','A','A','','450');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('460','Ger�st- und Schalungsmaterial','A','A','','460');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('480','Geringwertige Wirtschaftsg�ter bis DM 800,-','A','A','','480');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('490','Sonstige Betriebs- und Gesch�ftsausstattung','A','A','','490');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('650','Verb. gg. Kreditinstituten - Restlaufz. gr��er 5 Jahre','A','L','','650');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1000','Kasse','A','A','AR_paid:AP_paid','1000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1200','Bank-Giro','A','A','AR_paid:AP_paid','1200');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1400','Forderungen aus Lief. und Leist. Kundengruppe 0','A','A','AR','1400');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1540','Steuer�berzahlungen','A','A','AR','1540');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1542','Steuererstattungsanspr�che gg. anderen EU-L�ndern','A','A','AR','1542');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1545','Umsatzsteuerforderungen','A','A','AR','1545');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1548','Vorsteuer im Folgejahr abziehbar','A','A','AR','1548');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1570','Abziehbare Vorsteuer','A','A','AR_tax:AP_tax','1570');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1571','Abziehbare Vorsteuer, 7%','A','A','AR_tax:AP_tax:IC_taxpart:IC_taxservice','1571');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1575','Abziehbare Vorsteuer, 16%','A','A','AR_tax:AP_tax:IC_taxpart:IC_taxservice','1575');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1576','Abziehbare Vorsteuer, 15%','A','A','AR_tax:AP_tax:IC_taxpart:IC_taxservice','1576');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1577','Vorsteuer nach allg. Durchschnittss�tzen UStVA KZ 63','A','A','AR_tax:AP_tax','1577');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1775','Umsatzsteuer, 16%','A','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice','1775');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1776','Umsatzsteuer, 15%','A','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice','1776');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1780','Umsatzsteuer - Vorauszahlungen','A','L','','1780');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1781','Umsatzsteuer - Vorauszahlungen 1/11','A','L','','1781');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1782','Nachsteuer, UStVA KZ 65','A','L','','1782');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1789','Umsatzsteuer laufendes Jahr','A','L','','1789');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1790','Umsatzsteuer Vorjahr','A','L','','1790');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1791','Umsatzsteuer fr�here Jahre','A','L','','1791');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1820','Sonderausg. beschr. abzugsf. (Privat Vollhaft./Einzelu.)','A','','','1820');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1830','Sonderausg. unbeschr. abzugsf. (Privat Vollhaft./Einzelu.)','A','','','1830');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1840','Privatspenden (Privat Vollhafter / Einzelunternehmer)','A','','','1840');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1850','Au�ergew�hnliche Belastungen (Privat Vollhaft. / Einzelunt.)','A','','','1850');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1890','Privateinlagen (Privat Vollhafter / Einzelunternehmer)','A','','','1890');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2010','Betriebsfremde Aufw. (soweit nicht au�erordentlich)','A','','','2010');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2020','Periodenfremde Aufw. (soweit nicht au�erordentlich)','A','','','2020');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2100','Zinsen und �hnliche Aufwendungen','A','','','2100');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2103','Steuerlich abzugsf�hige, andere Nebenleistungen zu Steuern','A','','','2103');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2104','Steuerlich nicht abzugsf�hige, andere Nebenleistungen zu Steuern','A','','','2104');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2107','Zinsaufwendungen �233a AO betriebliche Steuern','A','','','2107');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2108','Zinsaufw. �233a, �234, �237 AO Personenst. �8 GewStG','A','','','2108');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2109','Zinsaufwendungen an verbundene Unternehmen','A','','','2109');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2110','Zinsaufwendungen f�r kurzfristige Verbindlichkeiten','A','','','2110');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3410','Wareneingang, 16% Vorsteuer','A','','','3410');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3736','Erhaltene Skonti, 16% Vorsteuer','A','','','3736');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3740','Erhaltene Boni','A','','','3740');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3750','Erhaltene Boni,   7% Vorsteuer','A','','','3750');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3760','Erhaltene Boni, 15%+16% Vorsteuer','A','','','3760');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3762','Erhaltene Boni, 16% Vorsteuer','A','','','3762');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3764','Erhaltene Boni, 15% Vorsteuer','A','','','3764');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3800','Anschaffungsnebenkosten','A','','','3800');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3830','Leergut','A','','','3830');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3850','Z�lle und Einfuhrabgaben','A','','','3850');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3960','Bestandsv. Roh-, Hilfs- u. Betriebsstoffe / bezogene Waren','A','','','3960');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3970','Bestand Roh-, Hilfs- und Betriebsstoffe','A','','','3970');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3980','Bestand Waren','A','','','3980');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3990','Verrechnete Stoffkosten','A','','','3990');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4000','Material- und Stoffverbrauch','A','E','AP_amount','4000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4100','L�hne und Geh�lter','A','E','AP_amount','4100');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4110','L�hne','A','E','AP_amount','4110');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4120','Geh�lter','A','E','AP_amount','4120');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4124','Gesch�ftsf�hrergeh�lter der GmbH-Gesellschafter','A','E','AP_amount','4124');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4125','Ehegattengehalt','A','E','AP_amount','4125');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4126','Tantiemen','A','E','AP_amount','4126');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4127','Gesch�ftsf�hrergeh�lter','A','E','AP_amount','4127');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4128','Verg�tungen an angestellte Mitunternehmer �15 EStG','A','E','AP_amount','4128');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4130','Gesetzliche soziale Aufwendungen','A','E','AP_amount','4130');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4137','Gesetzliche soziale Aufw. f�r Mitunternehmer �15 EStG','A','E','AP_amount','4137');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4138','Beitr�ge zur Berufsgenossenschaft','A','E','AP_amount','4138');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1360','Geldtransit Bank 1','A','A','','1360');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4140','Freiw. soziale Aufwendungen (lohnsteuerfrei)','A','E','AP_amount','4140');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4145','Freiw. soziale Aufwendungen (lohnsteuerpflichtig)','A','E','AP_amount','4145');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4149','Pauschale Lohnsteuer auf s. Bez�ge (z.B. Fahrtkostenzuschu�)','A','E','AP_amount','4149');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4150','Krankengeldzusch�sse','A','E','AP_amount','4150');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4160','Versorgungskassen','A','E','AP_amount','4160');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4165','Aufwendungen f�r die Altersversorgung','A','E','AP_amount','4165');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4167','Pauschale Lohnsteuer auf s. Bez�ge (z.B. Direktversicherung)','A','E','AP_amount','4167');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4168','Aufw. f. die Altersversorgung f. Mitunternehmer �15 EStG','A','E','AP_amount','4168');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4169','Aufwendungen f�r Unterst�tzung','A','E','AP_amount','4169');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4170','Verm�genswirksame Leistungen','A','E','AP_amount','4170');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4175','Fahrtkostenerstattung - Wohnung / Arbeitsst�tte','A','E','AP_amount','4175');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4180','Bedienungsgelder','A','E','AP_amount','4180');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4190','Aushilfsl�hne','A','E','AP_amount','4190');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4199','Lohnsteuer f�r Aushilfen','A','E','AP_amount','4199');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4200','Raumkosten','A','E','AP_amount','4200');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4210','Miete','A','E','AP_amount','4210');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4218','Gewerbesteuerlich zu ber�cks. Miete �8 GewStG','A','E','AP_amount','4218');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4219','Verg�tung an Mitu. f. mietw. �berl. v. Wirtschaftsg. �15EStG','A','E','AP_amount','4219');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4220','Pacht','A','E','AP_amount','4220');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4228','Gewerbesteuerlich zu ber�cks. Pacht �8 GewStG','A','E','AP_amount','4228');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4229','Verg�tung an Mitu. f. pachtw. �berl. v. Wirtschaftsg.�15EStG','A','E','AP_amount','4229');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4230','Heizung','A','E','AP_amount','4230');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4240','Gas, Strom, Wasser (Verwaltung, Vertrieb)','A','E','AP_amount','4240');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4250','Reinigung','A','E','AP_amount','4250');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4260','Instandhaltung betrieblicher R�ume','A','E','AP_amount','4260');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4270','Abgaben f�r betrieblich genutzten Grundbesitz','A','E','AP_amount','4270');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4280','Sonstige Raumkosten','A','E','AP_amount','4280');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4320','Gewerbesteuer (Vorauszahlung)','A','E','AP_amount','4320');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4330','Gewerbeertragsteuer','A','E','AP_amount','4330');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4335','Gewerbekapitalsteuer','A','E','AP_amount','4335');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4340','Sonstige Betriebsteuern','A','E','AP_amount','4340');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4350','Verbrauchsteuer','A','E','AP_amount','4350');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4360','Versicherungen','A','E','AP_amount','4360');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4380','Beitr�ge','A','E','AP_amount','4380');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4390','Sonstige Abgaben','A','E','AP_amount','4390');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4396','Steuerlich abzugsf�hige Versp�tungszuschl�ge und Zwangsgelder','A','E','AP_amount','4396');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4397','Steuerlich nicht abzugsf�hige Versp�tungszuschl�ge und Zwangsgelder','A','E','AP_amount','4397');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4400','Besondere Kosten (zur freien Verf�gung)','A','E','AP_amount','4400');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4500','Fahrzeugkosten','A','E','AP_amount','4500');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4510','Kfz-Steuern','A','E','AP_amount','4510');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4520','Kfz-Versicherungen','A','E','AP_amount','4520');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4530','Laufende Kfz-Betriebskosten','A','E','AP_amount','4530');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4540','Kfz-Reparaturen','A','E','AP_amount','4540');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4550','Garagenmieten','A','E','AP_amount','4550');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4570','Fremdfahrzeuge','A','E','AP_amount','4570');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4580','Sonstige Kfz-Kosten','A','E','AP_amount','4580');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4600','Werbe- und Reisekosten','A','E','AP_amount','4600');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4610','Werbekosten','A','E','AP_amount','4610');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4630','Geschenke bis DM 75,00','A','E','AP_amount','4630');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4635','Geschenke �ber DM 75,00','A','E','AP_amount','4635');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4638','Geschenke ausschlie�lich betrieblich genutzt','A','E','AP_amount','4638');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4640','Repr�sentationskosten','A','E','AP_amount','4640');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4650','Bewirtungskosten','A','E','AP_amount','4650');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4653','Aufwerksamkeiten','A','E','AP_amount','4653');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4654','Nicht abzugsf�hige Bewirtungskosten','A','E','AP_amount','4654');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4655','Nicht abzugsf�hige Betriebsausgaben','A','E','AP_amount','4655');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4660','Reisekosten Arbeitnehmer','A','E','AP_amount','4660');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4666','Reisekost. Arbeitn., 12,3%/13,1% VSt  Verpfl.Mehr- / �bern.Aufw.','A','E','AP_amount','4666');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4667','Reisekost. Arbeitn., 9,8%/10,5% VSt Gesamtpauschal.','A','E','AP_amount','4667');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4670','Reisekosten Unternehmer','A','E','AP_amount','4670');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4675','Reisekosten Unternehmer, 9,8/10,5% VSt sonst.Gesamtpauschal.','A','E','AP_amount','4675');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4676','Reisekost. Untern., 12,3%/13,1% VSt Verpfl.Mehr- / �bern.Aufw.','A','E','AP_amount','4676');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4677','Reisekosten Unternehmer, 9,8%/10,5% VSt Verpfl.Mehraufw. Gesamtpauschal.','A','E','AP_amount','4677');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4678','Km-Geld Erstattung, Unternehmer, 5,7%/6,1% VSt','A','E','AP_amount','4678');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4685','Km-Geld-Erstattung, Arbeitnehmer  8,2%/8,7% VSt','A','E','AP_amount','4685');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4700','Kosten der Warenabgabe','A','E','AP_amount:IC_expense:IC_cogs','4700');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4710','Verpackungsmaterial','A','E','AP_amount','4710');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4730','Ausgangsfrachten','A','E','AP_amount','4730');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4750','Transportversicherungen','A','E','AP_amount','4750');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4760','Verkaufsprovisionen','A','E','AP_amount','4760');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4780','Fremdarbeiten','A','E','AP_amount','4780');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4790','Aufwand f�r Gew�hrleistungen','A','E','AP_amount','4790');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4800','Reparat. u. Inst. v. Maschinen u. technischen Anlagen','A','E','AP_amount','4800');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4805','Reparat. u. Inst. v. and. Anl. d. Betr.- u. Gesch�ftsausst.','A','E','AP_amount','4805');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4809','Sonstige Reparaturen und Instandhaltungen','A','E','AP_amount','4809');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4810','Mietleasing','A','E','AP_amount','4810');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4815','Kaufleasing','A','E','AP_amount','4815');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4820','Abschr. a. Aufw. f.d. Ingangs. u. Erw. des Gesch�ftsbetr.','A','E','AP_amount','4820');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4822','Abschr. a. immaterielle Verm�gensgegenst�nde','A','E','AP_amount','4822');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4824','Abschreibung auf den Gesch�fts- oder Firmenwert','A','E','AP_amount','4824');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4826','Au�erplanm. Abschr. a. immaterielle Verm�gensgegenst�nde','A','E','AP_amount','4826');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4830','Abschreibungen auf Sachanlagen','A','E','AP_amount','4830');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4840','Au�erplanm. Abschreibungen auf Sachanlagen','A','E','AP_amount','4840');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4850','Abschr. a. Sachanl. aufgrund steuerl. Sondervorschriften','A','E','AP_amount','4850');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4855','Sofortabschreibung geringwertiger Wirtschaftsg�ter','A','E','AP_amount','4855');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4860','Abschreibung auf aktivierte, geringwertige Wirtschaftsg�ter','A','E','AP_amount','4860');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4865','Au�erplanm��ige Abschr. a. aktivierte GWG','A','E','AP_amount','4865');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4870','Abschreibungen auf Finanzanlagen','A','E','AP_amount','4870');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4872','Abschr. aufgrund v. Verlustant. an Mitunt. �8 GewStG','A','E','AP_amount','4872');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4874','Abschr. a. Finanzanl. aufgrund steuerl. Sondervorschriften','A','E','AP_amount','4874');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4875','Abschreibungen auf Wertpapiere des Umlaufverm�gens','A','E','AP_amount','4875');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4880','Abschr. a. Umlaufv. ohne Wertpapiere (soweit un�bl. H�he)','A','E','AP_amount','4880');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4882','Abschr. a. Umlaufv. steuerrechtl. bedingt (un�bl. H�he)','A','E','AP_amount','4882');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4887','Abschr. a. Umlaufv., steuerrechtlich bedingt (�bl. H�he)','A','E','AP_amount','4887');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4890','Vorwegn. k�nftiger Wertschw. im Umlaufv. (un�bl. H�he)','A','E','AP_amount','4890');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4900','Sonstige betriebliche Aufwendungen','A','E','AP_amount','4900');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4905','Sonstige Aufwendungen betrieblich und regelm��ig','A','E','AP_amount','4905');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4910','Porto','A','E','AP_amount','4910');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4920','Telefon','A','E','AP_amount','4920');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4925','Telefax, Fernschreiber','A','E','AP_amount','4925');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4930','B�robedarf','A','E','AP_amount','4930');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4940','Zeitschriften, B�cher','A','E','AP_amount','4940');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4945','Fortbildungskosten','A','E','AP_amount','4945');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4946','Freiwillige Sozialleistungen','A','E','AP_amount','4946');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4948','Verg�tungen an freiberufliche Mitunternehmer �15 EStG','A','E','AP_amount','4948');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4950','Rechts- und Beratungskosten','A','E','AP_amount','4950');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4955','Buchf�hrungskosten','A','E','AP_amount','4955');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4957','Abschlu�- und Pr�fungskosten','A','E','AP_amount','4957');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4960','Mieten f�r Einrichtungen','A','E','AP_amount','4960');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4968','Gewerbest. zu ber�cks. Miete f. Einrichtungen �8 GewStG','A','','','4968');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4969','Aufwendungen f�r Abraum- und Abfallbeseitigung','A','E','AP_amount','4969');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4970','Nebenkosten des Geldverkehrs','A','E','AP_amount','4970');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4980','Betriebsbedarf','A','E','AP_amount','4980');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4985','Werkzeuge und Kleinger�te','A','E','AP_amount','4985');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4996','Herstellungskosten','A','E','AP_amount','4996');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4997','Verwaltungskosten','A','E','AP_amount','4997');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4998','Vertriebskosten','A','E','AP_amount','4998');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4999','Gegenkonto 49960-49980','A','','','4999');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('7140','Fertige Waren (Bestand)','A','A','IC','7140');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8100','Steuerfreie Ums�tze o. VSt-Abzug �4 Nr.8 ff. UStG','A','I','AR_amount:IC_sale','8100');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8500','Provisionserl�se','A','I','AR_amount:IC_sale','8500');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8504','Provisionserl�se steuerfrei (�4 Nr.8ff UStG)','A','I','AR_amount:IC_sale','8504');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8505','Provisionserl�se steuerfrei (�4 Nr.5 UStG)','A','I','AR_amount:IC_sale','8505');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8506','Provisionserl�se,  7% USt','A','I','AR_amount:IC_sale','8506');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8507','Provisionserl�se, 15% Ust','A','I','AR_amount:IC_sale','8507');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8508','Provisionserl�se, 15%/16% USt','A','I','AR_amount:IC_sale','8508');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8509','Provisionserl�se, 16% Ust','A','I','AR_amount:IC_sale','8509');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8591','Sachbez�ge,   7% USt (Waren)','A','I','AR_amount:IC_sale','8591');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8595','Sachbez�ge, 15%/16% USt (Waren)','A','I','AR_amount:IC_sale','8595');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8596','Sachbez�ge, 16% USt (Waren)','A','I','AR_amount:IC_sale','8596');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8597','Sachbez�ge, 15% USt (Waren)','A','I','AR_amount:IC_sale','8597');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8630','Sonstige Erl�se betrieblich und regelm��ig, 7% USt','A','I','AR_amount:IC_sale','8630');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8645','Sonstige Erl�se betrieblich und regelm��ig, 16% Ust','A','I','AR_amount:IC_sale','8645');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8730','Gew�hrte Skonti','A','','','8730');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8731','Gew�hrte Skonti,  7% USt','A','','','8731');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8735','Gew�hrte Skonti, 16% Ust','A','','','8735');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8740','Gew�hrte Boni','A','','','8740');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8750','Gew�hrte Boni,  7% USt','A','','','8750');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8762','Gew�hrte Boni, 16% Ust','A','','','8762');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8770','Gew�hrte Rabatte','A','','','8770');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8780','Gew�hrte Rabatte,  7% USt','A','','','8780');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8792','Gew�hrte Rabatte, 16% Ust','A','','','8792');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8800','Erl�se aus Anlagenverk�ufen','A','','','8800');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8801','Erl�se aus Anlagenverk�ufen 15%/16% USt (bei Buchverlust)','A','','','8801');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8810','Erl�se aus Anlagenverk�ufen 16% USt (bei Buchverlust)','A','','','8810');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8815','Erl�se aus Anlagenverk�ufen 15% USt (bei Buchverlust)','A','','','8815');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8820','Erl�se aus Anlagenverk�ufen 15%/16% USt (bei Buchgewinn)','A','','','8820');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8829','Erl�se aus Anlagenverk�ufen (bei Buchgewinn)','A','','','8829');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8830','Erl�se aus Anlagenverk�ufen 16% USt (bei Buchgewinn)','A','','','8830');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8835','Erl�se aus Anlagenverk�ufen 15% USt (bei Buchgewinn)','A','','','8835');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8900','Eigenverbrauch','A','','','8900');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8905','Entnahme Gegenst�nde ohne USt','A','','','8905');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8908','Entnahme von Gegenst�nde, 16% USt �1 Abs.1 Nr.2a UStG','A','','','8908');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8909','Entnahme von Gegenst�nde, 15% USt �1 Abs.1 Nr.2a UStG','A','','','8909');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8910','Entnahme von Gegenst�nde, 15%/16% USt �1 Abs.1 Nr.2a UStG','A','','','8910');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8915','Entnahme von Gegenst�nde, 7% USt �1 Abs.1 Nr.2a UStG','A','','','8915');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8920','Entnahme v. sonst. Leist., 15%/16% USt �1 A.1 Nr.2b UStG','A','','','8920');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8930','Entnahme v. sonst. Leist., 7% USt �1 A.1 Nr.2b UStG','A','','','8930');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8937','Entnahme v. sonst. Leist., 16% USt �1 A.1 Nr.2b UStG','A','','','8937');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8938','Entnahme v. sonst. Leist., 15% USt �1 A.1 Nr.2b UStG','A','','','8938');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8939','Entnahme v. sonst. Leist., ohne USt �1 A.1 Nr.2b UStG','A','','','8939');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8941','Eigenverbr., 7% Ust �4 A.1 Nr.5 1-7, A.7 EStG','A','','','8941');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8942','Eigenverbr., 16% Ust  �4 A.1 Nr.5 1-7, A.7 EStG','A','','','8942');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8944','Eigenverbr., ohne Ust �4 A.1 Nr.5 1-7, A.7 EStG','A','','','8944');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8950','Nicht steuerbare Ums�tze','A','','','8950');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8955','Umsatzsteuerverg�tungen','A','','','8955');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8960','Bestandsver�nd. - unfertige Erzeugnisse','A','','','8960');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8970','Bestandsver�nd. - unfertige Leistungen','A','','','8970');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8975','Bestandsver�nd. - in Ausf�hrung befindliche Bauauftr�ge','A','','','8975');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8977','Bestandsver�nd. - in Arbeit befindliche Auftr�ge','A','','','8977');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8980','Bestandsver�nd. - fertige Erzeugnisse','A','','','8980');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8990','Bestandsver�nd. - andere aktivierte Eigenleistungen','A','','','8990');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9000','Saldenvortr�ge Sachkonten','A','','','9000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9008','Saldenvortr�ge Debitoren','A','','','9008');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9009','Saldenvortr�ge Kreditoren','A','','','9009');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9100','Saldovortragskonto der Statistikkonten','A','','','9100');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1800','Privatentn. allg. (Privat Vollhafter / Einzelunternehmer)','A','Q','','1800');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2000','Au�erordentliche Aufwendungen','A','A','','2000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1600','Verb. aus Lief. und Leist. Lieferantengruppe 0','A','L','AP','1600');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3400','Wareneingang, 16% Vorsteuer','A','E','AP_amount','3400');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8400','Umsatzerl�se 16%','A','I','AR_amount:IC_sale','8400');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8840','Ertr�ge aus Kursdifferenzen','A','I','AR_amount:IC_sale:IC_income','8840');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '1571'),0.07);
insert into tax (chart_id,rate) values ((select id from chart where accno = '1575'),0.16);
insert into tax (chart_id,rate) values ((select id from chart where accno = '1576'),0.15);
insert into tax (chart_id,rate) values ((select id from chart where accno = '1775'),0.16);
insert into tax (chart_id,rate) values ((select id from chart where accno = '1776'),0.15);
insert into tax (chart_id,rate) values ((select id from chart where accno = '3400'),0.16);
insert into tax (chart_id,rate) values ((select id from chart where accno = '8400'),0.16);
--
INSERT INTO defaults (fldname, fldvalue) VALUES ('inventory_accno_id', (SELECT id FROM chart WHERE accno = '7140'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('income_accno_id', (SELECT id FROM chart WHERE accno = '8400'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('expense_accno_id', (SELECT id FROM chart WHERE accno = '4700'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('fxgain_accno_id', (SELECT id FROM chart WHERE accno = '8840'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('fxloss_accno_id', (SELECT id FROM chart WHERE accno = '8840'));
INSERT INTO defaults (fldname, fldvalue) VALUES ('weightunit', 'kg');
INSERT INTO defaults (fldname, fldvalue) VALUES ('precision', '2');
--
INSERT INTO curr (rn, curr, prec) VALUES (1,'EUR',2);
INSERT INTO curr (rn, curr, prec) VALUES (2,'USD',2);

