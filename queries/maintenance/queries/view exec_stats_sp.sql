SELECT  top 50
        sp.Name,
        sum(total_physical_reads/execution_count) as sum_avg_total_physical_reads,
        sum(total_logical_writes/execution_count) as sum_avg_total_logical_writes,
        sum(total_logical_reads/execution_count) as sum_avg_total_logical_reads,
        sum(((total_elapsed_time/execution_count)*1.0)/1000000) as sum_avg_total_elapsed_time,
        sum(total_physical_reads) as sum_total_physical_reads,
        sum(total_logical_writes) as sum_total_logical_writes,
        sum(total_logical_reads) as sum_total_logical_reads,
        sum((total_elapsed_time*1.0)/1000000) as sum_total_elapsed_time,
        sum(execution_count)/COUNT(*) as execution_count
FROM    sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
join sys.procedures sp on sp.object_id = st.objectid
where st.dbid = DB_ID()
group by sp.name
order by sum_total_elapsed_time desc




declare @db int,
        @sp nvarchar(max)
;
select  @db = DB_ID(),
        @sp = ''
;
        
SELECT  sp.Name,
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
join sys.procedures sp on sp.object_id = st.objectid
where   st.dbid = @db
