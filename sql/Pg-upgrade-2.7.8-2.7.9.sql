--
alter table ap add onhold bool;
alter table ap alter onhold set default 'f'; 
update ap set onhold = 'f';
--
alter table ar add onhold bool;
alter table ar alter onhold set default 'f'; 
update ar set onhold = 'f';
--
update defaults set fldvalue = '2.7.9' where fldname = 'version';
