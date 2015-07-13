SELECT 
      [spid] = session_Id
    , ecid
    , [blockedBy] = blocking_session_id 
    , [database] = DB_NAME(sp.dbid)
    , [user] = nt_username
    , [status] = er.status
    , [wait] = wait_type
    , [current stmt] = 
        SUBSTRING (
            qt.text, 
            er.statement_start_offset/2,
            (CASE 
                WHEN er.statement_end_offset = -1 THEN DATALENGTH(qt.text)  
                ELSE er.statement_end_offset 
            END - er.statement_start_offset)/2)
    ,[current batch] = qt.text
    , reads
    , logical_reads
    , cpu
    , [time elapsed (ms)] = DATEDIFF(mi, start_time,getdate())
    , program = program_name
    , hostname
    --, nt_domain
    , start_time
    , qt.objectid
FROM sys.dm_exec_requests er
INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)as qt
WHERE session_Id > 50              -- Ignore system spids.
AND session_Id NOT IN (@@SPID)     -- Ignore this current statement.
ORDER BY 1, 2
GO