declare @db int = DB_id()

SELECT  qs.*,'-',qp.*,'-',st.*
FROM    sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
where qp.dbid = @db-- and st.text like '%select * from Crm_contacts%'

/*
exec sp_who;

SELECT * FROM sys.dm_exec_requests
WHERE session_id = 57;
*/
select * from sys.dm_exec_procedure_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
where qp.dbid=@db

declare
@tableHTML  NVARCHAR(MAX),
@subject1 varchar(200),
@date datetime,
@total_worker_time    BIGINT,
@total_physical_reads BIGINT,
@total_logical_writes BIGINT,
@total_logical_reads  BIGINT,
@total_clr_time       BIGINT,
@percentage_of_total_clr_time BIGINT,
@total_elapsed_time   BIGINT,        
@printscr varchar(8000),
@filestr varchar(255),
@dbid int,
@procedure_id int,
@statement_text varchar(1000),
@percentage_of_total_worker_time decimal(6,4),
@percentage_of_total_physical_read decimal(6,4),
@percentage_of_total_logical_writes decimal(6,4), 
@percentage_of_total_logical_reads decimal(6,4),
@percentage_of_total_elapsed_time decimal(6,4),
@total_recompiles int,
@impmeas FLOAT,
@DBNAME VARCHAR(30),
@OBJECTID INT,
@execution_count int;     


      SELECT      @total_worker_time    = SUM(total_worker_time)    ,
                        @total_physical_reads = SUM(total_physical_reads) ,
                        @total_logical_writes = SUM(total_logical_writes) ,
                        @total_logical_reads  = SUM(total_logical_reads)  ,
                        @total_clr_time       = SUM(total_clr_time)       ,
                        @total_elapsed_time   = SUM(total_elapsed_time)
      FROM        sys.dm_exec_query_stats 


      IF ISNULL(@total_worker_time    , 0) = 0 SET @total_worker_time    = 1
      IF ISNULL(@total_physical_reads , 0) = 0 SET @total_physical_reads = 1
      IF ISNULL(@total_logical_writes , 0) = 0 SET @total_logical_writes = 1
      IF ISNULL(@total_logical_reads  , 0) = 0 SET @total_logical_reads  = 1
      IF ISNULL(@total_clr_time       , 0) = 0 SET @total_clr_time       = 1
      IF ISNULL(@total_elapsed_time   , 0) = 0 SET @total_elapsed_time   = 1
      SELECT TOP 20 
      qs.creation_time,
      st.dbid , 
      st.objectid as procedure_id ,  
      SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,((CASE statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS statement_text,
      total_worker_time,
      cast( 100.00 * total_worker_time / @total_worker_time  as decimal (6,4) )  AS percentage_of_total_worker_time,
      total_physical_reads,
      cast( 100.00 * total_physical_reads / @total_physical_reads  as decimal (6,4) )  AS percentage_of_total_physical_reads,
      total_logical_writes,
      cast( 100.00 * total_logical_writes / @total_logical_writes  as decimal (6,4) )  AS percentage_of_total_logical_writes,
      total_logical_reads,
      cast( 100.00 * total_logical_reads / @total_logical_reads as decimal (6,4) )  AS percentage_of_total_logical_reads,
      total_clr_time,
      cast( 100.00 * total_clr_time / @total_clr_time as decimal (6,4) )  AS percentage_of_total_clr_time,
      total_elapsed_time,
      cast( 100.00 * total_elapsed_time / @total_elapsed_time  as decimal (6,4) )  AS percentage_of_total_elapsed_time,
      plan_generation_num as total_recompiles,
      execution_count 
      FROM sys.dm_exec_query_stats as qs
      CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
      where st.dbid = (select database_id from sys.databases where name ='CouponService_Test')
        and st.objectid = (select object_id from sys.procedures where name = 'test') 
      ORDER BY total_worker_time DESC

      
SELECT q.text, s.execution_count,*
FROM sys.dm_exec_query_stats as s
      cross apply sys.dm_exec_sql_text(plan_handle) AS q
ORDER BY s.execution_count DESC      