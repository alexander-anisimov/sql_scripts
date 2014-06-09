SELECT top 50
COALESCE(DB_NAME(t.[dbid]),'Unknown') AS [DB Name],
ecp.objtype AS [Object Type],
t.[text] AS [Adhoc Batch or Object Call],
SUBSTRING(t.[text], (qs.[statement_start_offset]/2) + 1,
            ((CASE qs.[statement_end_offset]
                        WHEN -1 THEN DATALENGTH(t.[text]) ELSE qs.[statement_end_offset] END
                                    - qs.[statement_start_offset])/2) + 1) AS [Executed Statement],
qs.[execution_count] AS [Counts],
--qs.[total_worker_time] AS [Total Worker Time], 
cast((qs.[total_worker_time] / qs.[execution_count] + 0.00)/1000000 as float) AS [Avg Worker Time (s)],
--qs.[total_physical_reads] AS [Total Physical Reads],
(qs.[total_physical_reads] / qs.[execution_count]) AS [Avg Physical Reads],
--qs.[total_logical_writes] AS [Total Logical Writes],
(qs.[total_logical_writes] / qs.[execution_count]) AS [Avg Logical Writes],
--qs.[total_logical_reads] AS [Total Logical Reads],
(qs.[total_logical_reads] / qs.[execution_count]) AS [Avg Logical Reads],
--qs.[total_clr_time] AS [Total CLR Time], 
(qs.[total_clr_time] / qs.[execution_count]) AS [Avg CLR Time],
--qs.[total_elapsed_time] AS [Total Elapsed Time], 
cast((qs.[total_elapsed_time] / qs.[execution_count] + 0.00)/1000000 as float) AS [Avg Elapsed Time (s)],
qs.[last_execution_time] AS [Last Exec Time], 
qs.[creation_time] AS [Creation Time]
FROM sys.dm_exec_query_stats AS qs
    JOIN sys.dm_exec_cached_plans ecp ON qs.plan_handle = ecp.plan_handle
            CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
--    ORDER BY [Total Worker Time] DESC
--    ORDER BY [Total Physical Reads] DESC
--    ORDER BY [Total Logical Writes] DESC
--    ORDER BY [Total Logical Reads] DESC
--    ORDER BY [Total CLR Time] DESC
--    ORDER BY [Total Elapsed Time] DESC
--ORDER BY counts DESC,[Avg Elapsed Time] desc
ORDER BY [Avg Elapsed Time (s)]  desc
--            ORDER BY [Counts] DESC

use master
declare @db varchar(2000)
select @db = 'admiral'
;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
select  top 50
        --ROW_NUMBER() over (order by ((total_elapsed_time - total_worker_time) / qs.execution_count+0.0)/1000000 DESC) as RowCnt,    -- order by block time time
        ROW_NUMBER() over (order by ((total_elapsed_time+0.0) / (qs.execution_count * 1000000)) DESC) as RowCnt,                    -- order by execution time
        --ROW_NUMBER() over (order by (total_logical_reads + total_logical_writes) DESC) as RowCnt,                    -- order by IO 
        qs.Creation_Time,
        qs.Last_Execution_Time,
        qs.Execution_Count,
        --cast((qs.total_worker_time+0.0)/1000000 as money) as TotalCPUTime,
        --cast((Total_Elapsed_Time+0.0)/1000000 as money) as TotalElapsedTime,
        cast((qs.total_worker_time+0.0)/(qs.execution_count*1000000) as money) as AvgCPUTime,
        cast((total_elapsed_time+0.0) / (qs.execution_count * 1000000) as money) as AvgElapsedTime,
        ((total_elapsed_time - total_worker_time) / qs.execution_count+0.0)/1000000 as AvgTimeBlocked,
        --total_logical_reads as LogicalReads,
        (total_logical_reads) / qs.execution_count as AvgLogicalReads,
        --total_logical_writes as logicalWrites,
        (total_logical_writes) / qs.execution_count as AvgLogicalWrites,
        --total_physical_reads as PhysicalReads,
        (total_physical_reads) / qs.execution_count as AvgPhysicalReads,
        (total_logical_reads + total_logical_writes) as IO,
        case when plan_handle IS NULL then ' '
        else ( substring(st.text,(qs.statement_start_offset+2)/2,(case when qs.statement_end_offset = -1 then len(convert(nvarchar(MAX),st.text))*2 else qs.statement_end_offset end - qs.statement_start_offset)/2 )) end as QueryText,
        db_name(st.dbid) as DBName,
        query_plan.value('(//ColumnReference)[1]/@Database', 'NVARCHAR(MAX)') DBName_from_plan,
        so.name as SPName,
        --Plan_Handle,
        --Parameterized_Plan_Handle=query_plan.value('(//StmtSimple)[1]/@ParameterizedPlanHandle', 'NVARCHAR(128)'), 
        --Parameterized_Text=query_plan.value('(//StmtSimple)[1]/@ParameterizedText', 'NVARCHAR(MAX)'),
        qp.Query_Plan
from    sys.dm_exec_query_stats  qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) st
cross apply sys.dm_exec_query_plan (qs.plan_handle) qp
left join dbo.sysobjects so ON so.id = st.objectid
where   total_logical_reads > 0 
    and st.text not like '%sys.%'
    and query_plan.value('(//ColumnReference)[1]/@Database', 'NVARCHAR(MAX)') like '%' + @db + '%'