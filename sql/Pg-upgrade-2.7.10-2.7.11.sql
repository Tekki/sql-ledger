--
create sequence contactid;
create table temp (trans_id int, firstname varchar(64), lastname varchar(64), phone varchar(20), fax varchar(20), email text);
--
insert into temp (trans_id, firstname, lastname, phone, fax, email) select id, rtrim(substr(contact,1,strpos(contact,' '))), substr(contact,strpos(contact,' ')+1), phone, fax, email from customer;
--
insert into temp (trans_id, firstname, lastname, phone, fax, email) select id, rtrim(substr(contact,1,strpos(contact,' '))), substr(contact,strpos(contact,' ')+1), phone, fax, email from vendor;
--
create table contact (id int default nextval('contactid') primary key, trans_id int not null, firstname varchar(32), lastname varchar(32), salutation varchar(32), contacttitle varchar(32), occupation varchar(32), phone varchar(20), fax varchar(20), mobile varchar(20), gender char(1) default 'M', email text, parent_id int, typeofcontact varchar(20));
--
insert into contact (trans_id, firstname, lastname, phone, fax, email, typeofcontact) select trans_id, rtrim(substr(firstname,1,32)), rtrim(substr(lastname,1,32)), phone, fax, email, 'company' from temp;
--
drop table temp;
--
update defaults set fldvalue = '2.7.11' where fldname = 'version';
