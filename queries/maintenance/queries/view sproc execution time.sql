-- 15 min, without indexes
declare @db nvarchar(max) = 'admiral',
        @sp nvarchar(max) = 'recalcRef_Statistics'
SELECT  --row_number() over (order by qs.creation_time ) as id,
        SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,((CASE statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS statement_text,
        total_physical_reads/execution_count as avg_total_physical_reads,
        total_logical_writes/execution_count as avg_total_logical_writes,
        total_logical_reads/execution_count as avg_total_logical_reads,
        ((total_elapsed_time/execution_count)*1.0)/1000000 as avg_total_elapsed_time,
        total_physical_reads,
        total_logical_writes,
        total_logical_reads,
        (total_elapsed_time*1.0)/1000000 as total_elapsed_time,
        execution_count,
        qs.creation_time
FROM    sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
where   st.dbid = (select database_id from sys.databases where name =@db)
  and   st.objectid = (select object_id from sys.procedures where name = @sp) 
union all
select  *
from (
SELECT  --999 as id,
        'SUMM: ' AS statement_text,
        sum(total_physical_reads/execution_count) as sum_avg_total_physical_reads,
        sum(total_logical_writes/execution_count) as sum_avg_total_logical_writes,
        sum(total_logical_reads/execution_count) as sum_avg_total_logical_reads,
        (sum(total_elapsed_time/execution_count)*1.0)/1000000 as sum_avg_total_elapsed_time,
        sum(total_physical_reads) as sum_total_physical_reads,
        sum(total_logical_writes) as sum_total_logical_writes,
        sum(total_logical_reads) as sum_total_logical_reads,
        (sum(total_elapsed_time)*1.0)/1000000 as sum_total_elapsed_time,
        sum(execution_count)  as sum_execution_count,
        max(qs.creation_time) as creation_time
FROM    sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
where   st.dbid = (select database_id from sys.databases where name =@db)
  and   st.objectid = (select object_id from sys.procedures where name = @sp) 
) t


