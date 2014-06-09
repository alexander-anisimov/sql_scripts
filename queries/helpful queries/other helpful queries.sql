-- Clear the data and plan cache
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SET STATISTICS IO ON
SET STATISTICS TIME ON
DBCC DROPCLEANBUFFERS -- дает возможность тестировать запросы при незаполненном буфере данных
DBCC FREEPROCCACHE -- дает возможность тестирования запросов при незаполненном кэше планов исполнения.

-- Выбор имен ХП (плюс некоторые параметры) в текущей БД:
SELECT     ROUTINE_NAME, ROUTINE_DEFINITION, SQL_DATA_ACCESS
FROM       INFORMATION_SCHEMA.ROUTINES
WHERE     (ROUTINE_TYPE = 'PROCEDURE')


--Выбор имен таблиц (для выбора имен представлений в качестве параметра сортировки подставьте VIEW) в текущей ДБ:
SELECT     TABLE_SCHEMA, TABLE_NAME
FROM       INFORMATION_SCHEMA.TABLES
WHERE     (TABLE_TYPE = 'BASE TABLE')


-- быстрое получение количества строк в таблице используя данные из индекса
SELECT OBJECT_NAME(id), [rows] FROM sysindexes WHERE indid=1 and id=OBJECT_ID('Accounts')
--или
SELECT so.name as TableName, ddps.row_count as [RowCount]
FROM sys.objects so
JOIN sys.indexes si ON si.OBJECT_ID = so.OBJECT_ID
JOIN sys.dm_db_partition_stats AS ddps ON si.OBJECT_ID = ddps.OBJECT_ID  AND si.index_id = ddps.index_id
WHERE si.index_id < 2  AND so.is_ms_shipped = 0
ORDER BY ddps.row_count DESC


-- сортировка по случайному значению
SELECT TOP 1 id, name FROM sysobjects ORDER BY NEWID()

-- получить текст комманды для заданного процесса
DECLARE @Handle binary(20)
SELECT @Handle = sql_handle FROM sys.sysprocesses WHERE spid = 52
SELECT * FROM ::fn_get_sql(@Handle)

-- уменьшить размер журнала транзакций
-- 1
backup log db with truncate_only
GO
DBCC SHRINKDATABASE('db')
DBCC SHRINKFILE (db_log, 50)
-- 2
ALTER DATABASE <имя базы> SET RECOVERY SIMPLE
GO
DBCC SHRINKFILE(<имя файла лога>,1)
GO
ALTER DATABASE <имя базы> SET RECOVERY FULL
-- 3
DECLARE @sql varchar(1000)
SET @sql = 'ALTER DATABASE '+QUOTENAME(DB_NAME())+' SET RECOVERY SIMPLE
DBCC SHRINKDATABASE('''+DB_NAME()+''')
ALTER DATABASE '+QUOTENAME(DB_NAME())+' SET RECOVERY FULL WITH NO_WAIT'
EXEC (@sql) 


-- глянуть все процессы к базе
select * from sys.dm_exec_requests ORDER BY command

--сбросить идентификатор таблицы
DBCC CHECKIDENT ('Person.AddressType', RESEED, 10);