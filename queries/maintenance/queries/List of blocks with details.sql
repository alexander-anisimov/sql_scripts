-- Просмотр детальной информации по всем блокировкам
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT  p.spid, kpid, blocked, d.name, hostname, cmd, program_name, lastwaittype, waittype, waittime, waitresource, p.dbid, uid, cpu, physical_io, 
      memusage, login_time, last_batch, ecid, open_tran, p.status, p.sid, hostprocess, nt_domain, nt_username, net_address, net_library, loginame, 
      context_info, sql_handle, stmt_start, stmt_end
FROM         master..sysprocesses p left outer join sysdatabases d on d.dbid = p.dbid
--WHERE p.status = 'runnable' ORDER BY cpu desc
--WHERE hostname = 's04-sp01'
order by hostname desc,p.spid

declare @sysprocesses CURSOR
SET @sysprocesses = CURSOR LOCAL STATIC FOR
SELECT SPID FROM master..sysprocesses
--WHERE status = 'runnable' ORDER BY cpu desc
--WHERE hostname = 's04-sp01'


DECLARE @handle binary(20)
DECLARE @SPID smallint
declare @SQL table
(
   SPID smallint,
   Sql_Query text 
)
open @sysprocesses 
   WHILE (1 = 1)
   BEGIN
      FETCH @sysprocesses INTO @SPID
      IF @@FETCH_STATUS <> 0 BREAK
         print @SPID
         SELECT @handle = sql_handle FROM master..sysprocesses WHERE spid = @SPID
         insert @SQL
         (
            SPID,
            Sql_Query
         )
         SELECT @SPID,[text] FROM ::fn_get_sql(@handle)
   END
   
select sq.SPID, blocked, sp.hostname, d.name, sp.last_batch, datediff(mi/*ss*/,sp.last_batch,getdate()) mi /*sec*/, sp.cmd, sp.status, program_name, sq.Sql_Query
from @SQL sq inner join
    sysprocesses sp ON sq.SPID = sp.SPID left outer join sysdatabases d on d.dbid = sp.dbid
--where     sp.hostname = 'srv-moss'
/*
select sp.hostname, count(sp.hostname) cnt
from @SQL sq inner join
    sysprocesses sp ON sq.SPID = sp.SPID
group by sp.hostname
order by cnt desc
--DBCC INPUTBUFFER(@SPID)
--kill 138; kill 177
kill 79
kill 123
kill 124
kill 125
kill 77
kill 57
*/