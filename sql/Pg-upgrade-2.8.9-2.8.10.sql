--
create table report (reportid int primary key default nextval('id'), reportcode text, reportdescription text, login text);
create table reportvars (reportid int not null, reportvariable text, reportvalue text);
--
update defaults set fldvalue = '2.8.10' where fldname = 'version';
