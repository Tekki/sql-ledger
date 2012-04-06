--
alter table paymentmethod add roundchange float4;
update paymentmethod set roundchange = 0;
--
update defaults set fldvalue = '2.9.3' where fldname = 'version';
