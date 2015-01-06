-- 2014-11-11 Pedro Lopes (Microsoft) pedro.lopes@microsoft.com (http://aka.ms/ezequiel)
--
-- All Databases duplicate index info, including search for references in sql.modules.
--
-- http://blogs.msdn.com/b/blogdoezequiel/archive/2014/11/12/sql-swiss-army-knife-15-handling-duplicate-indexes.aspx#.VGmfiPmsVc4

SET NOCOUNT ON;

DECLARE @sqlmajorver int, @dbname sysname, @dbid int, @sqlcmd NVARCHAR(4000), @ErrorMessage VARCHAR(500)

SELECT @sqlmajorver = CONVERT(int, (@@microsoftversion / 0x1000000) & 0xff);

IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tmpdbs'))
DROP TABLE #tmpdbs;
IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tmpdbs'))
CREATE TABLE #tmpdbs (id int IDENTITY(1,1), [dbid] int, [dbname] VARCHAR(1000), [compatibility_level] int, is_read_only bit, [state] tinyint, is_distributor bit, [role] tinyint, [secondary_role_allow_connections] tinyint, isdone bit);

IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblIxs'))
DROP TABLE #tblIxs;
IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblIxs'))
CREATE TABLE #tblIxs ([databaseID] int, [DatabaseName] sysname, [objectID] int, [schemaName] VARCHAR(100), [objectName] VARCHAR(200), 
	[indexID] int, [indexName] VARCHAR(200), [indexType] tinyint, is_primary_key bit, [is_unique_constraint] bit, is_unique bit, is_disabled bit, fill_factor tinyint, is_padded bit, has_filter bit, filter_definition NVARCHAR(max),
	KeyCols VARCHAR(4000), KeyColsOrdered VARCHAR(4000), IncludedCols VARCHAR(4000) NULL, IncludedColsOrdered VARCHAR(4000) NULL, AllColsOrdered VARCHAR(4000) NULL, [KeyCols_data_length_bytes] int,
	ReferencedIn VARCHAR(4000), CONSTRAINT PK_Ixs PRIMARY KEY CLUSTERED(databaseID, [objectID], [indexID]));

IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblCode'))
DROP TABLE #tblCode;
IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblCode'))
CREATE TABLE #tblCode ([DatabaseName] sysname, [schemaName] VARCHAR(100), [objectName] VARCHAR(200), [indexName] VARCHAR(200), type_desc NVARCHAR(60));

IF @sqlmajorver < 11
BEGIN
	INSERT INTO #tmpdbs ([dbid], [dbname], [compatibility_level], is_read_only, [state], is_distributor, [role], [secondary_role_allow_connections], [isdone])
	SELECT database_id, name, [compatibility_level], is_read_only, [state], is_distributor, 1, 1, 0 FROM master.sys.databases (NOLOCK)
END;

IF @sqlmajorver > 10
BEGIN
	INSERT INTO #tmpdbs ([dbid], [dbname], [compatibility_level], is_read_only, [state], is_distributor, [role], [secondary_role_allow_connections], [isdone])
	SELECT sd.database_id, sd.name, sd.[compatibility_level], sd.is_read_only, sd.[state], sd.is_distributor, MIN(COALESCE(ars.[role],1)) AS [role], ar.secondary_role_allow_connections, 0 
	FROM master.sys.databases sd (NOLOCK) 
		LEFT JOIN sys.dm_hadr_database_replica_states d ON sd.database_id = d.database_id
		LEFT JOIN sys.availability_replicas ar ON d.group_id = ar.group_id AND d.replica_id = ar.replica_id
		LEFT JOIN sys.dm_hadr_availability_replica_states ars ON d.group_id = ars.group_id AND d.replica_id = ars.replica_id
	GROUP BY sd.database_id, sd.name, sd.is_read_only, sd.[state], sd.is_distributor, ar.secondary_role_allow_connections, sd.[compatibility_level];
END;

UPDATE #tmpdbs
SET isdone = 0;

UPDATE #tmpdbs
SET isdone = 1
WHERE [state] <> 0 OR [dbid] < 5;

UPDATE #tmpdbs
SET isdone = 1
WHERE [role] = 2 AND secondary_role_allow_connections = 0;

RAISERROR (N'Starting index data collection', 10, 1) WITH NOWAIT

WHILE (SELECT COUNT(id) FROM #tmpdbs WHERE isdone = 0) > 0
BEGIN
	SELECT TOP 1 @dbname = [dbname], @dbid = [dbid] FROM #tmpdbs WHERE isdone = 0
	SET @sqlcmd = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
USE ' + QUOTENAME(@dbname) + ';
SELECT ' + CONVERT(VARCHAR(8), @dbid) + ' AS Database_ID, ''' + @dbname + ''' AS Database_Name,
mst.[object_id] AS objectID, t.name AS schemaName, mst.[name] AS objectName, mi.index_id AS indexID, 
mi.[name] AS Index_Name, mi.[type] AS [indexType], mi.is_primary_key, mi.[is_unique_constraint], mi.is_unique, mi.is_disabled,
mi.fill_factor, mi.is_padded, ' + CASE WHEN @sqlmajorver > 9 THEN 'mi.has_filter, mi.filter_definition,' ELSE 'NULL, NULL,' END + ' 
SUBSTRING(( SELECT '','' + ac.name FROM sys.tables AS st
	INNER JOIN sys.indexes AS i ON st.[object_id] = i.[object_id]
	INNER JOIN sys.index_columns AS ic ON i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id] 
	INNER JOIN sys.all_columns AS ac ON st.[object_id] = ac.[object_id] AND ic.[column_id] = ac.[column_id]
	WHERE mi.[object_id] = i.[object_id] AND mi.index_id = i.index_id AND ic.is_included_column = 0
	ORDER BY ic.key_ordinal
FOR XML PATH('''')), 2, 8000) AS KeyCols,
SUBSTRING(( SELECT '','' + ac.name FROM sys.tables AS st
	INNER JOIN sys.indexes AS i ON st.[object_id] = i.[object_id]
	INNER JOIN sys.index_columns AS ic ON i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id] 
	INNER JOIN sys.all_columns AS ac ON st.[object_id] = ac.[object_id] AND ic.[column_id] = ac.[column_id]
	WHERE mi.[object_id] = i.[object_id] AND mi.index_id = i.index_id AND ic.is_included_column = 0
	ORDER BY ac.name
FOR XML PATH('''')), 2, 8000) AS KeyColsOrdered,
SUBSTRING((SELECT '','' + ac.name FROM sys.tables AS st
	INNER JOIN sys.indexes AS i ON st.[object_id] = i.[object_id]
	INNER JOIN sys.index_columns AS ic ON i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id]
	INNER JOIN sys.all_columns AS ac ON st.[object_id] = ac.[object_id] AND ic.[column_id] = ac.[column_id]
	WHERE mi.[object_id] = i.[object_id] AND mi.index_id = i.index_id AND ic.is_included_column = 1
	ORDER BY ic.key_ordinal
FOR XML PATH('''')), 2, 8000) AS IncludedCols,
SUBSTRING((SELECT '','' + ac.name FROM sys.tables AS st
	INNER JOIN sys.indexes AS i ON st.[object_id] = i.[object_id]
	INNER JOIN sys.index_columns AS ic ON i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id]
	INNER JOIN sys.all_columns AS ac ON st.[object_id] = ac.[object_id] AND ic.[column_id] = ac.[column_id]
	WHERE mi.[object_id] = i.[object_id] AND mi.index_id = i.index_id AND ic.is_included_column = 1
	ORDER BY ac.name
FOR XML PATH('''')), 2, 8000) AS IncludedColsOrdered,
SUBSTRING((SELECT '','' + ac.name FROM sys.tables AS st
	INNER JOIN sys.indexes AS i ON st.[object_id] = i.[object_id]
	INNER JOIN sys.index_columns AS ic ON i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id]
	INNER JOIN sys.all_columns AS ac ON st.[object_id] = ac.[object_id] AND ic.[column_id] = ac.[column_id]
	WHERE mi.[object_id] = i.[object_id] AND mi.index_id = i.index_id
	ORDER BY ac.name
FOR XML PATH('''')), 2, 8000) AS AllColsOrdered,
(SELECT SUM(CASE sty.name WHEN ''nvarchar'' THEN sc.max_length/2 ELSE sc.max_length END) FROM sys.indexes AS i
	INNER JOIN sys.tables AS t ON t.[object_id] = i.[object_id]
	INNER JOIN sys.schemas ss ON ss.[schema_id] = t.[schema_id]
	INNER JOIN sys.index_columns AS sic ON sic.object_id = mst.object_id AND sic.index_id = mi.index_id
	INNER JOIN sys.columns AS sc ON sc.object_id = t.object_id AND sc.column_id = sic.column_id
	INNER JOIN sys.types AS sty ON sc.user_type_id = sty.user_type_id
	WHERE mi.[object_id] = i.[object_id] AND mi.index_id = i.index_id AND sic.key_ordinal > 0) AS [KeyCols_data_length_bytes],
NULL
FROM sys.indexes AS mi
INNER JOIN sys.tables AS mst ON mst.[object_id] = mi.[object_id]
INNER JOIN sys.schemas AS t ON t.[schema_id] = mst.[schema_id]
WHERE mi.type IN (1,2,5,6) AND mst.is_ms_shipped = 0
ORDER BY objectName
OPTION (MAXDOP 2);'

	BEGIN TRY
		INSERT INTO #tblIxs
		EXECUTE sp_executesql @sqlcmd
	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
		SELECT @ErrorMessage = 'Duplicate or Redundant indexes subsection - Error raised in TRY block in database ' + @dbname +'. ' + ERROR_MESSAGE()
		RAISERROR (@ErrorMessage, 16, 1);
	END CATCH
		
	UPDATE #tmpdbs
	SET isdone = 1
	WHERE dbid = @dbid;
END

RAISERROR (N'Ended index data collection', 10, 1) WITH NOWAIT

IF (SELECT COUNT(*) FROM #tblIxs I INNER JOIN #tblIxs I2 ON I.[databaseID] = I2.[databaseID] AND I.[objectID] = I2.[objectID] AND I.[indexID] <> I2.[indexID] 
	AND I.[KeyCols] = I2.[KeyCols] AND (I.IncludedCols = I2.IncludedCols OR (I.IncludedCols IS NULL AND I2.IncludedCols IS NULL))
	AND ((I.filter_definition = I2.filter_definition) OR (I.filter_definition IS NULL AND I2.filter_definition IS NULL))) > 0
BEGIN
	SELECT 'Index_and_Stats_checks' AS [Category], 'Duplicate_Indexes' AS [Check], '[WARNING: Some databases have duplicate indexes. It is recommended to revise the need to maintain all these objects as soon as possible]' AS [Deviation]
	SELECT 'Index_and_Stats_checks' AS [Category], 'Duplicate_Indexes' AS [Information], I.[DatabaseName] AS [Database_Name], I.schemaName AS [Schema_Name], I.[objectName] AS [Table_Name], 
		I.[indexID], I.[indexName] AS [Index_Name], I.is_primary_key, I.is_unique_constraint, I.is_unique, I.fill_factor, I.is_padded, I.has_filter, I.filter_definition,
		I.KeyCols, I.IncludedCols, CASE WHEN I.IncludedCols IS NULL THEN I.[KeyCols] ELSE I.[KeyCols] + ',' + I.IncludedCols END AS [AllColsOrdered]
	FROM #tblIxs I INNER JOIN #tblIxs I2
		ON I.[databaseID] = I2.[databaseID] AND I.[objectID] = I2.[objectID] AND I.[indexID] <> I2.[indexID] 
		AND I.[KeyCols] = I2.[KeyCols] AND (I.IncludedCols = I2.IncludedCols OR (I.IncludedCols IS NULL AND I2.IncludedCols IS NULL))
		AND ((I.filter_definition = I2.filter_definition) OR (I.filter_definition IS NULL AND I2.filter_definition IS NULL))
	WHERE I.indexType IN (1,2,5,6)		-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
		AND I2.indexType IN (1,2,5,6)	-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
	GROUP BY I.[databaseID], I.[DatabaseName], I.[schemaName], I.[objectName], I.[indexID], I.[indexName], I.KeyCols, I.IncludedCols, I.[KeyColsOrdered], I.IncludedColsOrdered, I.is_primary_key, I.is_unique_constraint, I.is_unique, I.fill_factor, I.is_padded, I.has_filter, I.filter_definition
	ORDER BY I.DatabaseName, I.[objectName], I.[indexID];

	/*
	Note that it is possible that a clustered index (unique or not) is among the duplicate indexes to be dropped, 
	namely if a non-clustered primary key exists on the table.
	In this case, make the appropriate changes in the clustered index (making it unique and/or primary key in this case),
	and drop the non-clustered instead.
	*/
	SELECT 'Index_and_Stats_checks' AS [Category], 'Duplicate_IX_toDrop' AS [Check], I.[DatabaseName], I.schemaName AS [Schema_Name], I.[objectName] AS [Table_Name],
		I.[indexID], I.[indexName] AS [Index_Name], I.is_primary_key, I.is_unique_constraint, I.is_unique, I.fill_factor, I.is_padded, I.has_filter, I.filter_definition,
		I.KeyCols, I.IncludedCols, CASE WHEN I.IncludedCols IS NULL THEN I.[KeyCols] ELSE I.[KeyCols] + ',' + I.IncludedCols END AS [AllColsOrdered]
	FROM #tblIxs I INNER JOIN #tblIxs I2
		ON I.[databaseID] = I2.[databaseID] AND I.[objectID] = I2.[objectID] AND I.[indexID] <> I2.[indexID] 
		AND I.[KeyCols] = I2.[KeyCols] AND (I.IncludedCols = I2.IncludedCols OR (I.IncludedCols IS NULL AND I2.IncludedCols IS NULL))
		AND ((I.filter_definition = I2.filter_definition) OR (I.filter_definition IS NULL AND I2.filter_definition IS NULL))
	WHERE I.indexType IN (1,2,5,6)			-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
		AND I2.indexType IN (1,2,5,6)		-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
		AND I.[indexID] NOT IN (
				SELECT COALESCE((SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
				WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
					AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
					AND (tI3.is_unique = 1 AND tI3.is_primary_key = 1)
				GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered),
				(SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
				WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
					AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
					AND (tI3.is_unique = 1 OR tI3.is_primary_key = 1)
				GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered),
				(SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
				WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
					AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
				GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered)
				))
	GROUP BY I.[databaseID], I.[DatabaseName], I.[schemaName], I.[objectName], I.[indexID], I.[indexName], I.KeyCols, I.IncludedCols, I.[KeyColsOrdered], I.IncludedColsOrdered, I.is_primary_key, I.is_unique_constraint, I.is_unique, I.fill_factor, I.is_padded, I.has_filter, I.filter_definition
	ORDER BY I.DatabaseName, I.[objectName], I.[indexID];

	DECLARE @strSQL2 NVARCHAR(4000), @DatabaseName sysname, @indexName sysname
	PRINT CHAR(10) + '/* Generated on ' + CONVERT (VARCHAR, GETDATE()) + ' in ' + @@SERVERNAME + ' */'
	PRINT CHAR(10) + '/*
NOTE: It is possible that a clustered index (unique or not) is among the duplicate indexes to be dropped, namely if a non-clustered primary key exists on the table.
In this case, make the appropriate changes in the clustered index (making it unique and/or primary key in this case), and drop the non-clustered instead.
*/'
	PRINT CHAR(10) + '--############# Existing Duplicate indexes drop statements #############' + CHAR(10)
	DECLARE Dup_Stats CURSOR FAST_FORWARD FOR SELECT 'USE ' + I.[DatabaseName] + CHAR(10) + 'GO' + CHAR(10) + 'IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'''+ I.[indexName] + ''')' + CHAR(10) +
	'DROP INDEX ' + QUOTENAME(I.[indexName]) + ' ON ' + QUOTENAME(I.[schemaName]) + '.' + QUOTENAME(I.[objectName]) + ';' + CHAR(10) + 'GO' + CHAR(10) 
	FROM #tblIxs I INNER JOIN #tblIxs I2
		ON I.[databaseID] = I2.[databaseID] AND I.[objectID] = I2.[objectID] AND I.[indexID] <> I2.[indexID] 
		AND I.[KeyCols] = I2.[KeyCols] AND (I.IncludedCols = I2.IncludedCols OR (I.IncludedCols IS NULL AND I2.IncludedCols IS NULL))
		AND ((I.filter_definition = I2.filter_definition) OR (I.filter_definition IS NULL AND I2.filter_definition IS NULL))
	WHERE I.indexType IN (1,2,5,6)			-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
		AND I2.indexType IN (1,2,5,6)		-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
		AND I.[indexID] NOT IN (
				SELECT COALESCE((SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
				WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
					AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
					AND (tI3.is_unique = 1 AND tI3.is_primary_key = 1)
				GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered),
				(SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
				WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
					AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
					AND (tI3.is_unique = 1 OR tI3.is_primary_key = 1)
				GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered),
				(SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
				WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
					AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
				GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered)
				))
	GROUP BY I.[databaseID], I.[DatabaseName], I.[schemaName], I.[objectName], I.[indexID], I.[indexName], I.KeyCols, I.IncludedCols, I.[KeyColsOrdered], I.IncludedColsOrdered, I.is_primary_key, I.is_unique_constraint, I.is_unique, I.fill_factor, I.is_padded, I.has_filter, I.filter_definition
	ORDER BY I.DatabaseName, I.[objectName], I.[indexID];

	OPEN Dup_Stats
	FETCH NEXT FROM Dup_Stats INTO @strSQL2
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT @strSQL2
		FETCH NEXT FROM Dup_Stats INTO @strSQL2
	END
	CLOSE Dup_Stats
	DEALLOCATE Dup_Stats
	PRINT '--############# Ended Duplicate indexes drop statements #############' + CHAR(10)

	RAISERROR (N'Starting index search in sql modules', 10, 1) WITH NOWAIT

	DECLARE Dup_Stats CURSOR FAST_FORWARD FOR SELECT I.[DatabaseName],I.[indexName] 
	FROM #tblIxs I INNER JOIN #tblIxs I2
		ON I.[databaseID] = I2.[databaseID] AND I.[objectID] = I2.[objectID] AND I.[indexID] <> I2.[indexID] 
		AND I.[KeyCols] = I2.[KeyCols] AND (I.IncludedCols = I2.IncludedCols OR (I.IncludedCols IS NULL AND I2.IncludedCols IS NULL))
		AND ((I.filter_definition = I2.filter_definition) OR (I.filter_definition IS NULL AND I2.filter_definition IS NULL))
	WHERE I.indexType IN (1,2,5,6)		-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
		AND I2.indexType IN (1,2,5,6)	-- clustered, non-clustered, clustered and non-clustered columnstore indexes only
		AND I.[indexID] NOT IN (
			SELECT COALESCE((SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
			WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
				AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
				AND (tI3.is_unique = 1 AND tI3.is_primary_key = 1)
			GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered),
			(SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
			WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
				AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
				AND (tI3.is_unique = 1 OR tI3.is_primary_key = 1)
			GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered),
			(SELECT MIN(tI3.[indexID]) FROM #tblIxs tI3
			WHERE tI3.[databaseID] = I.[databaseID] AND tI3.[objectID] = I.[objectID] 
				AND tI3.[KeyCols] = I.[KeyCols] AND (tI3.IncludedCols = I.IncludedCols OR (tI3.IncludedCols IS NULL AND I.IncludedCols IS NULL))
			GROUP BY tI3.[objectID], tI3.KeyCols, tI3.IncludedCols, tI3.[KeyColsOrdered], tI3.IncludedColsOrdered)
			))
	GROUP BY I.[databaseID], I.[DatabaseName], I.[schemaName], I.[objectName], I.[indexID], I.[indexName], I.KeyCols, I.IncludedCols, I.[KeyColsOrdered], I.IncludedColsOrdered
	ORDER BY I.DatabaseName, I.[objectName], I.[indexID]

	OPEN Dup_Stats
	FETCH NEXT FROM Dup_Stats INTO @DatabaseName,@indexName
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @sqlcmd = 'USE [' + @DatabaseName + '];
SELECT ''' + @DatabaseName + ''' AS [database], ss.name AS [schemaName], so.name AS [objectName], ''' + @indexName + ''' AS indexName, so.type_desc
FROM sys.sql_modules sm
INNER JOIN sys.objects so ON sm.[object_id] = so.[object_id]
INNER JOIN sys.schemas ss ON ss.[schema_id] = so.[schema_id]
WHERE sm.[definition] LIKE ''%' + @indexName + '%'''

		INSERT INTO #tblCode
		EXECUTE sp_executesql @sqlcmd

		FETCH NEXT FROM Dup_Stats INTO @DatabaseName,@indexName
	END
	CLOSE Dup_Stats
	DEALLOCATE Dup_Stats

	RAISERROR (N'Ended index search in sql modules', 10, 1) WITH NOWAIT

	IF (SELECT COUNT(*) FROM #tblCode) > 0
	BEGIN
		SELECT 'Index_and_Stats_checks' AS [Category], 'Duplicate_Indexes_HardCoded' AS [Check], '[WARNING: Some sql modules have references to these duplicate indexes. Fix these references to be able to drop duplicate indexes]' AS [Deviation]
		SELECT [DatabaseName],[schemaName],[objectName] AS [referedIn_objectName], indexName AS [referenced_indexName], type_desc AS [refered_objectType]
		FROM #tblCode
		ORDER BY [DatabaseName], [objectName]
	END
	ELSE
	BEGIN
		SELECT 'Index_and_Stats_checks' AS [Category], 'Duplicate_Indexes_HardCoded' AS [Check], '[OK]' AS [Deviation]
	END
END
ELSE
BEGIN
	SELECT 'Index_and_Stats_checks' AS [Category], 'Duplicate_Indexes' AS [Check], '[OK]' AS [Deviation]
END;

IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tmpdbs'))
DROP TABLE #tmpdbs;
IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblIxs'))
DROP TABLE #tblIxs;
IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblCode'))
DROP TABLE #tblCode;