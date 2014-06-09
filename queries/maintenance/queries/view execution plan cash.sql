SELECT  cp.usecounts, cast(((cp.size_in_bytes*1.0)/1024)/1024 as money) as 'size_in_MB', cp.cacheobjtype, cp.objtype, cp.plan_handle, qs.sql_handle,
        qs.creation_time, qs.last_execution_time, qs.execution_count, 
        total_elapsed_time, last_elapsed_time, min_elapsed_time, max_elapsed_time,
        total_physical_reads, last_physical_reads, min_physical_reads, max_physical_reads,
        total_logical_writes, last_logical_writes, min_logical_writes, max_logical_writes,
        total_logical_reads, last_logical_reads, min_logical_reads, max_logical_reads,
        --total_rows, last_rows, min_rows, max_rows,
        t.text
FROM sys.dm_exec_cached_plans cp
left join sys.dm_exec_query_stats qs on qs.plan_handle = cp.plan_handle
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) t
WHERE  t.dbid = DB_ID('admiral') 
and text like '%SELECT DISTINCT TOP 3000  "u".* FROM "Users" AS "u"%'
order by qs.last_execution_time desc




SELECT  row_number() over (order by qs.last_execution_time desc) as Id,  t.text
FROM sys.dm_exec_cached_plans cp
left join sys.dm_exec_query_stats qs on qs.plan_handle = cp.plan_handle
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) t
WHERE  t.dbid = DB_ID('admiral') 
and text like '%SELECT DISTINCT TOP 3000  "u".* FROM "Users" AS "u"%'




;
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT cp.objtype,
cp.usecounts,
cp.size_in_bytes,
cp.plan_handle,
st.text,
parameterized_plan_handle=query_plan.value('(//StmtSimple)[1]/@ParameterizedPlanHandle', 'NVARCHAR(128)'), 
parameterized_text=query_plan.value('(//StmtSimple)[1]/@ParameterizedText', 'NVARCHAR(MAX)'),
qp.query_plan
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan (cp.plan_handle) qp
WHERE st.text LIKE '%calculateCurrencyRates%' AND st.text NOT LIKE '%sys.dm_exec_cached_plans%'
order by objtype, parameterized_plan_handle
