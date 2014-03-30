-- задержки
SELECT TOP 10
 [Wait type] = wait_type,
 [Wait time (s)] = wait_time_ms / 1000,
 [% waiting] = CONVERT(DECIMAL(12,2), wait_time_ms * 100.0 
               / SUM(wait_time_ms) OVER())
  FROM sys.dm_os_wait_stats
  WHERE wait_type NOT LIKE '%SLEEP%' 
  ORDER BY wait_time_ms DESC;


-- итоговое число отсутствующих индексов для каждой базы данных
SELECT [DatabaseName] = DB_NAME(database_id),
       [Number Indexes Missing] = count(*) 
  FROM sys.dm_db_missing_index_details
  GROUP BY DB_NAME(database_id)
  ORDER BY 2 DESC


-- отсутствующие индексы, вызывающие издержки
SELECT TOP 10 
       [Total Cost] = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0),
       avg_user_impact,
       TableName = statement,
       [EqualityUsage] = equality_columns,
       [InequalityUsage] = inequality_columns,
       [Include Cloumns] = included_columns
  FROM sys.dm_db_missing_index_groups g 
  INNER JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle 
  INNER JOIN sys.dm_db_missing_index_details d ON d.index_handle = g.index_handle
  WHERE database_id = DB_ID()
  ORDER BY [Total Cost] DESC;

  
-- запросы с высокими издержками на ввод-вывод
SELECT TOP 10
       [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count,
       [Total IO] = (total_logical_reads + total_logical_writes),
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, (CASE
                                                                               WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
                                                                               ELSE qs.statement_end_offset
                                                                             END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average IO] DESC


-- запросы с высоким использованием ресурсов ЦП
SELECT TOP 10
       [Average CPU used] = total_worker_time / qs.execution_count,
       [Total CPU used] = total_worker_time,
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING(qt.text,qs.statement_start_offset/2, 
         (CASE
            WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average CPU used] DESC;


-- запросы, страдающие от блокировки
SELECT TOP 10
       [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count,
       [Total Time Blocked] = total_elapsed_time - total_worker_time,
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE
            WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average Time Blocked] DESC;


-- нагрузку на подсистему ввода-вывода
select top 5 
    (total_logical_reads/execution_count) as avg_logical_reads,
    (total_logical_writes/execution_count) as avg_logical_writes,
    (total_physical_reads/execution_count) as avg_phys_reads,
     Execution_count, 
    statement_start_offset as stmt_start_offset, 
    plan_handle,
    qt.text
  from sys.dm_exec_query_stats  qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  order by  (total_logical_reads + total_logical_writes) Desc


-- какой процессор что делает
SELECT DB_NAME(ISNULL(s.dbid,1)) AS [Имя базы данных],
       c.session_id AS [ID сессии],
       t.scheduler_id AS [Номер процессора],
       s.text AS [Текст SQL-запроса]
  FROM sys.dm_exec_connections AS c
  CROSS APPLY master.sys.dm_exec_sql_text(c.most_recent_sql_handle) AS s
  JOIN sys.dm_os_tasks t ON t.session_id = c.session_id AND
                            t.task_state = 'RUNNING'
  ORDER BY c.session_id DESC


-- контроль "несжатости"
SELECT tbl.name,
       i.name,
       p.partition_number AS [PartitionNumber],
       p.data_compression_desc AS [DataCompression],
       p.rows  AS [RowCount]
  FROM sys.tables AS tbl
  LEFT JOIN sys.indexes AS i ON (i.index_id > 0 and i.is_hypothetical = 0) AND (i.object_id=tbl.object_id)
  INNER JOIN sys.partitions AS p ON p.object_id = CAST(tbl.object_id AS int) AND
                                    p.index_id = CAST(i.index_id AS int)
  where p.data_compression_desc <> 'PAGE' and
        p.rows >= 2000000
  order by p.rows desc, 3


-- статистика по операциям в БД
SELECT t.name AS [TableName],
       fi.page_count AS [Pages],
       fi.record_count AS [Rows],
       CAST(fi.avg_record_size_in_bytes AS int) AS [AverageRecordBytes],
       CAST(fi.avg_fragmentation_in_percent AS int) AS [AverageFragmentationPercent],
       SUM(iop.leaf_insert_count) AS [Inserts],
       SUM(iop.leaf_delete_count) AS [Deletes],
       SUM(iop.leaf_update_count) AS [Updates],
       SUM(iop.row_lock_count) AS [RowLocks],
       SUM(iop.page_lock_count) AS [PageLocks]
  FROM sys.dm_db_index_operational_stats(DB_ID(),NULL,NULL,NULL) AS iop
  JOIN sys.indexes AS i ON iop.index_id = i.index_id AND
                           iop.object_id = i.object_id
  JOIN sys.tables AS t ON i.object_id = t.object_id AND
                          i.type_desc IN ('CLUSTERED', 'HEAP')
  JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS fi ON fi.object_id=CAST(t.object_id AS int) AND
                                                                                     fi.index_id=CAST(i.index_id AS int)
  GROUP BY t.name, fi.page_count, fi.record_count, fi.avg_record_size_in_bytes, fi.avg_fragmentation_in_percent
  ORDER BY [RowLocks] desc



-- дата обновления статистики
SELECT STATS_DATE(t1.object_id, stats_id),
      'UPDATE STATISTICS ['+ OBJECT_SCHEMA_NAME(t1.object_id, DB_ID()) + '].[' + object_name(t1.object_id) + ']([' + t1.name + ']) WITH FULLSCAN',
       t4.rows
  FROM sys.stats as t1
  inner join sys.objects as t2 on t1.object_id = t2.object_id
  left join sys.indexes  as t3 on t3.object_id = t1.object_id and
                                  t3.name = t1.name
  left join (select object_id, index_id, sum(rows) as rows
               from sys.partitions 
               group by object_id, index_id
            ) as t4 on t4.object_id = t3.object_id and
                       t4.index_id  = t3.index_id
  where STATS_DATE(t1.object_id, stats_id) < GETDATE()-5 and
        -- не учитываем отключенные индексы
        t3.is_disabled = 0 and
        -- исключаем автостатистику, по идее, в нормально спроектированной системе
        -- она создана по редким ad-hoc запросам, поэтому не является обязательной
        -- для принудительного обновления
        t1.auto_created = 0 and
        -- исключаем служебные объекты 
        t2.is_ms_shipped = 0
  order by t4.rows


-- i/o-нагрузка на файлы баз
SELECT DB_NAME(saf.dbid) AS [База данных],
       saf.name AS [Логическое имя],
       vfs.BytesRead/1048576 AS [Прочитано (Мб)],
       vfs.BytesWritten/1048576 AS [Записано (Мб)],
       saf.filename AS [Путь к файлу]

  FROM master..sysaltfiles AS saf
  JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
                                                  vfs.fileid = saf.fileid-- AND
                                                  --saf.dbid NOT IN (1,3,4)
  where vfs.BytesRead/1048576 <> 0 or
        vfs.BytesWritten/1048576 <> 0
  ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC


-- i/o-нагрузка на диски
SELECT SUBSTRING(saf.physical_name, 1, 1)    AS [Диск],
       SUM(vfs.num_of_bytes_read/1048576)    AS [Прочитано (Мб)],
       SUM(vfs.num_of_bytes_written/1048576) AS [Записано (Мб)]
  FROM sys.master_files AS saf
  JOIN sys.dm_io_virtual_file_stats(NULL,NULL) AS vfs ON vfs.database_id = saf.database_id AND
                                                         vfs.file_id = saf.file_id AND
                                                         saf.database_id NOT IN (1,3,4) AND
                                                         saf.type < 2
  GROUP BY SUBSTRING(saf.physical_name, 1, 1)
  ORDER BY [Диск]


-- быстрая загрузка экселевского файла
select *
  from opendatasource('Microsoft.Jet.OLEDB.4.0','Data Source="c:\test.xls";User ID=Admin;Password=;Extended properties="Excel 8.0;IMEX=1"')...[Лист1$]


-- занимаемое на диске место
SELECT TOP 1000
       (row_number() over(order by (a1.reserved + ISNULL(a4.reserved,0)) desc))%2 as l1,
       a3.name AS [schemaname],
       a2.name AS [tablename],
       a1.rows as row_count,
      (a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved,
       a1.data * 8 AS data,
      (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS index_size,
      (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS unused,
      'ALTER TABLE [' + a2.name  + '] REBUILD' as [sql]
  FROM (SELECT ps.object_id,
               SUM(CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows],
               SUM(ps.reserved_page_count) AS reserved,
               SUM(CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END) AS data,
               SUM(ps.used_page_count) AS used
          FROM sys.dm_db_partition_stats ps
          GROUP BY ps.object_id
       ) AS a1
  LEFT JOIN (SELECT it.parent_id,
                    SUM(ps.reserved_page_count) AS reserved,
                    SUM(ps.used_page_count) AS used
               FROM sys.dm_db_partition_stats ps
               INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
               WHERE it.internal_type IN (202,204)
               GROUP BY it.parent_id
            ) AS a4 ON (a4.parent_id = a1.object_id)
  INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )
  INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
  WHERE a2.type <> N'S' and a2.type <> N'IT'
  ORDER BY 8 DESC


-- под какие объекты выделена память 
select count(*)as cached_pages_count,
       obj.name as objectname,
       ind.name as indexname,
       obj.index_id as indexid
  from sys.dm_os_buffer_descriptors as bd
  inner join (select object_id as objectid,
                     object_name(object_id) as name,
                     index_id,allocation_unit_id
                from sys.allocation_units as au
                inner join sys.partitions as p on au.container_id = p.hobt_id and (au.type = 1 or au.type = 3)
                union all
                select object_id as objectid,
                       object_name(object_id) as name,
                       index_id,allocation_unit_id
                  from sys.allocation_units as au
                  inner join sys.partitions as p on au.container_id = p.partition_id and au.type = 2
             ) as obj on bd.allocation_unit_id = obj.allocation_unit_id
  left outer join sys.indexes ind on obj.objectid = ind.object_id and
                                     obj.index_id = ind.index_id
  where bd.database_id = db_id() and
        bd.page_type in ('data_page', 'index_page')
  group by obj.name, ind.name, obj.index_id
  order by cached_pages_count desc