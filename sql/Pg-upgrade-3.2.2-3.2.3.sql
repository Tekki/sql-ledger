--
alter table archivedata add rn int;
alter table semaphore alter expires type varchar(12);

--
update defaults set fldvalue = '3.2.3' where fldname = 'version';
