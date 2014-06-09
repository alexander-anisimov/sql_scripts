-- Clear the data and plan cache
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SET STATISTICS IO ON
SET STATISTICS TIME ON
DBCC DROPCLEANBUFFERS -- ���� ����������� ����������� ������� ��� ������������� ������ ������
DBCC FREEPROCCACHE -- ���� ����������� ������������ �������� ��� ������������� ���� ������ ����������.

-- ����� ���� �� (���� ��������� ���������) � ������� ��:
SELECT     ROUTINE_NAME, ROUTINE_DEFINITION, SQL_DATA_ACCESS
FROM       INFORMATION_SCHEMA.ROUTINES
WHERE     (ROUTINE_TYPE = 'PROCEDURE')


--����� ���� ������ (��� ������ ���� ������������� � �������� ��������� ���������� ���������� VIEW) � ������� ��:
SELECT     TABLE_SCHEMA, TABLE_NAME
FROM       INFORMATION_SCHEMA.TABLES
WHERE     (TABLE_TYPE = 'BASE TABLE')


-- ������� ��������� ���������� ����� � ������� ��������� ������ �� �������
SELECT OBJECT_NAME(id), [rows] FROM sysindexes WHERE indid=1 and id=OBJECT_ID('Accounts')
--���
SELECT so.name as TableName, ddps.row_count as [RowCount]
FROM sys.objects so
JOIN sys.indexes si ON si.OBJECT_ID = so.OBJECT_ID
JOIN sys.dm_db_partition_stats AS ddps ON si.OBJECT_ID = ddps.OBJECT_ID  AND si.index_id = ddps.index_id
WHERE si.index_id < 2  AND so.is_ms_shipped = 0
ORDER BY ddps.row_count DESC


-- ���������� �� ���������� ��������
SELECT TOP 1 id, name FROM sysobjects ORDER BY NEWID()

-- �������� ����� �������� ��� ��������� ��������
DECLARE @Handle binary(20)
SELECT @Handle = sql_handle FROM sys.sysprocesses WHERE spid = 52
SELECT * FROM ::fn_get_sql(@Handle)

-- ��������� ������ ������� ����������
-- 1
backup log db with truncate_only
GO
DBCC SHRINKDATABASE('db')
DBCC SHRINKFILE (db_log, 50)
-- 2
ALTER DATABASE <��� ����> SET RECOVERY SIMPLE
GO
DBCC SHRINKFILE(<��� ����� ����>,1)
GO
ALTER DATABASE <��� ����> SET RECOVERY FULL
-- 3
DECLARE @sql varchar(1000)
SET @sql = 'ALTER DATABASE '+QUOTENAME(DB_NAME())+' SET RECOVERY SIMPLE
DBCC SHRINKDATABASE('''+DB_NAME()+''')
ALTER DATABASE '+QUOTENAME(DB_NAME())+' SET RECOVERY FULL WITH NO_WAIT'
EXEC (@sql) 


-- ������� ��� �������� � ����
select * from sys.dm_exec_requests ORDER BY command

--�������� ������������� �������
DBCC CHECKIDENT ('Person.AddressType', RESEED, 10);