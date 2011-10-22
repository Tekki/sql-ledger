-- Extensions for weight and volume patch
INSERT INTO "defaults" (fldname , fldvalue) VALUES ( 'volumeunit', (SELECT fldvalue FROM "defaults" WHERE fldname='weightunit'));
UPDATE "defaults" SET fldvalue='cu ft' WHERE fldname='volumeunit' AND fldvalue='lbs';
UPDATE "defaults" SET fldvalue='m3' WHERE fldname='volumeunit' AND fldvalue<>'cu ft';

ALTER TABLE parts ADD gweight double precision;
ALTER TABLE parts ADD pvolume double precision;
UPDATE parts SET gweight = weight;
