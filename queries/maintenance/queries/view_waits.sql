
--create table #t (id int identity,spid int, text varchar(4000), blocked int, waittime int, lastwaittype varchar(100), waitresource varchar(100), cpu int, physical_io int, open_tran int)

insert into #t
select s.spid,q.text,s.blocked, s.waittime, s.lastwaittype, s.waitresource, s.cpu, s.physical_io, s.open_tran
from sys.sysprocesses s
cross apply sys.dm_exec_sql_text(s.sql_handle) q
where spid <> 94 and lastwaittype <> 'MISCELLANEOUS'


--truncate table #t

select  count(*),text, avg(cpu), avg(physical_io) from #t group by text
