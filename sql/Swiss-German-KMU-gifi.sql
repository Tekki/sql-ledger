-- Gifi for Swiss German chart of accounts UTF-8
-- Kontenklassen und -gruppen für Kontenrahmen KMU
--
-- Tekki, 2012-02-12
--
SET client_encoding = 'UTF-8';
--
INSERT INTO gifi (accno, description) VALUES ('1', 'AKTIVEN');
INSERT INTO gifi (accno, description) VALUES ('10', 'Umlaufvermögen');
INSERT INTO gifi (accno, description) VALUES ('100', 'Flüssige Mittel und Wertschriften');
INSERT INTO gifi (accno, description) VALUES ('110', 'Forderungen');
INSERT INTO gifi (accno, description) VALUES ('120', 'Vorräte');
INSERT INTO gifi (accno, description) VALUES ('130', 'Aktive Rechnungsabgrenzung');
INSERT INTO gifi (accno, description) VALUES ('14', 'Anlagevermögen');
INSERT INTO gifi (accno, description) VALUES ('140', 'Finanzanlagen');
INSERT INTO gifi (accno, description) VALUES ('150', 'Mobile Sachanlagen');
INSERT INTO gifi (accno, description) VALUES ('160', 'Immobile Sachanlagen');
INSERT INTO gifi (accno, description) VALUES ('170', 'Immaterielle Sachanlagen');
INSERT INTO gifi (accno, description) VALUES ('2', 'PASSIVEN');
INSERT INTO gifi (accno, description) VALUES ('20', 'Kurzfristiges Fremdkapital');
INSERT INTO gifi (accno, description) VALUES ('200', 'Kf. Verbindlichkeiten aus Lieferungen und Leistungen');
INSERT INTO gifi (accno, description) VALUES ('210', 'Kf. Finanzverbindlichkeiten');
INSERT INTO gifi (accno, description) VALUES ('230', 'Passive Rechnungsabgrenzung');
INSERT INTO gifi (accno, description) VALUES ('24', 'Langfristiges Fremdkapital');
INSERT INTO gifi (accno, description) VALUES ('240', 'Lf. Finanzverbindlichkeiten');
INSERT INTO gifi (accno, description) VALUES ('250', 'Andere lf. Verbindlichkeiten');
INSERT INTO gifi (accno, description) VALUES ('260', 'Lf. Rückstellungen');
INSERT INTO gifi (accno, description) VALUES ('28', 'Eigenkapital');
INSERT INTO gifi (accno, description) VALUES ('280', 'Kapital');
INSERT INTO gifi (accno, description) VALUES ('290', 'Reserven, Bilanzgewinn');
INSERT INTO gifi (accno, description) VALUES ('3', 'BETRIEBSERTRAG AUS LIEFERUNGEN UND LEISTUNGEN');
INSERT INTO gifi (accno, description) VALUES ('4', 'AUFWAND FÜR MATERIAL, WAREN UND DRITTLEISTUNGEN');
INSERT INTO gifi (accno, description) VALUES ('5', 'PERSONALWAUFWAND');
INSERT INTO gifi (accno, description) VALUES ('6', 'SONSTIGER BETRIEBSAUFWAND');
INSERT INTO gifi (accno, description) VALUES ('68', 'Finanzerfolg');
INSERT INTO gifi (accno, description) VALUES ('69', 'Abschreibungen');
INSERT INTO gifi (accno, description) VALUES ('7', 'BETRIEBLICHE NEBENERFOLGE');
INSERT INTO gifi (accno, description) VALUES ('74', 'Erfolg aus Finanzanlagen');
INSERT INTO gifi (accno, description) VALUES ('75', 'Erfolg betrieblichen Liegenschaften');
INSERT INTO gifi (accno, description) VALUES ('79', 'Gewinne aus Veräusserung von Anlagevermögen');
INSERT INTO gifi (accno, description) VALUES ('8', 'AUSSERORDENTLICHER ERFOLG, STEUERN');
INSERT INTO gifi (accno, description) VALUES ('80', 'Ausserordentlicher Erfolg');
INSERT INTO gifi (accno, description) VALUES ('82', 'Betriebsfremder Erfolg');
INSERT INTO gifi (accno, description) VALUES ('89', 'Steuern');
INSERT INTO gifi (accno, description) VALUES ('9', 'ABSCHLUSS');
