/*
1. Please create the stored procedure
2. Execute the procedure in debug mode first: EXEC sp_FlexibleUpdateStatistics @Debug=1  this will not do anything except listing the statistics to update.
3. Please execute the procedure with the parameters that satisfy your needs
*/

CREATE PROCEDURE [dbo].[sp_FlexibleUpdateStatistics] 
	@MaxExecutionTime int = 10, -- Script will stop if execution time exceeds this parameter (in minutes)
	@Debug tinyint = 1, -- Debug mode = 1, execution mode = 0... It only prints the statements in debug mode
	@ConsoleMode tinyint = 1, -- If 1, It will also print additional messages at execution mode. It should be better to set as 0 when running with SQL Agent Job.
	@MinModificationCount int = 10000, -- Script will update statistics only if the statistics modified rowscount is greater than @MinModificationCount
	@OnlyIndexStats tinyint = 0 -- If you want to ignore auto created statistics (WA_Sys*) , set this parameter to 1
AS
BEGIN

	SET NOCOUNT ON;

	-- Internal variables
	DECLARE @Counter int = 0
	DECLARE @DatabaseId int 
	DECLARE @DatabaseName sysname 
	DECLARE @AllStartTime datetime = GETDATE()
	DECLARE @UpdateStatStartTime datetime 
	DECLARE @ObjectName	NVARCHAR(500)
	DECLARE @StatisticsName	NVARCHAR(500)
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @StatisticsSQL NVARCHAR(MAX)

	CREATE TABLE #Statistics(
		Id int IDENTITY PRIMARY KEY,
		DatabaseName varchar(100) NOT NULL,
		SchemaName varchar(255) NOT NULL,
		TableName varchar(255) NOT NULL,
		StatisticsName nvarchar(255) NOT NULL,
		LastUpdated datetime,
		DaysBefore bigint,
		ActualRows bigint,
		ModificationCount bigint,
		ObjectName AS ('[' + DatabaseName + '].[' + SchemaName + '].[' + TableName + ']') PERSISTED,
		StatisticsSQL AS ('UPDATE STATISTICS ' + '[' + DatabaseName + '].[' + SchemaName + '].[' + TableName + ']' + ' [' + StatisticsName + '];' )  PERSISTED
	)

	-- Here we can alter the query to fetch the only databases which we want to alter their indexes
	DECLARE Db_Cursor CURSOR FOR  
	SELECT database_id, name FROM sys.databases WHERE name NOT IN ('master','model', 'tempdb', 'distribution' ) AND is_read_only <> 1


	OPEN Db_Cursor  
	FETCH NEXT FROM Db_Cursor INTO @DatabaseId, @DatabaseName  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		SET @SQL = '
		USE ' + @DatabaseName + ';
	
		INSERT #Statistics(DatabaseName, SchemaName, TableName,  StatisticsName, LastUpdated, DaysBefore, ActualRows, ModificationCount)
		SELECT
			DatabaseName = ''' + @DatabaseName + ''' ,
			SchemaName = sch.name,
			TableName = o.name,
			StatisticsName = [s].[name],
			LastUpdated = [sp].[last_updated],
			DaysBefore = DATEDIFF(day, [sp].[last_updated], GETDATE()),
			ActualRows = [sp].[rows],
			ModificationCount = [sp].[modification_counter] 
		FROM [sys].[stats] AS [s] 
			inner join sys.stats_columns sc
				on s.stats_id=sc.stats_id and s.object_id=sc.object_id
			inner join sys.columns c
				on c.object_id=sc.object_id and c.column_id=sc.column_id
			inner join sys.objects o
				on s.object_id=o.object_id
			inner join sys.schemas sch
				on o.schema_id=sch.schema_id
			OUTER APPLY sys.dm_db_stats_properties ([s].[object_id],[s].[stats_id]) AS [sp]
		WHERE [sp].[modification_counter] > ' + CONVERT(NVARCHAR(20), @MinModificationCount) + CASE WHEN @OnlyIndexStats=1 THEN 'AND [s].[name] NOT LIKE ''_WA_Sys_%'' ' ELSE ' '  END + '
		 OPTION (MAXDOP 1)'

		EXECUTE sp_executesql  @SQL
		FETCH NEXT FROM Db_Cursor INTO @DatabaseId, @DatabaseName  
	END  

	CLOSE Db_Cursor  
	DEALLOCATE Db_Cursor 

	CREATE NONCLUSTERED INDEX IX_Statistics_tmp_ObjectName ON #Statistics
	(
		ObjectName ASC
	)
	INCLUDE
	(
	StatisticsName,
	LastUpdated,
	DaysBefore,
	ActualRows,
	ModificationCount,
	StatisticsSQL
	)

	SELECT ObjectName, StatisticsName
	INTO #Multiple
	FROM #Statistics s
	GROUP BY ObjectName, StatisticsName
	HAVING COUNT(*) > 1

	DELETE
	FROM #Statistics 
	WHERE Id IN
		(
			SELECT Id
			FROM #Statistics s
			INNER JOIN #Multiple m ON m.ObjectName = s.ObjectName AND m.StatisticsName = s.StatisticsName
			WHERE s.Id Not IN 
			(
				SELECT TOP 1 s1.Id
				FROM #Multiple m1 
				INNER JOIN #Statistics s1 ON m1.ObjectName = s1.ObjectName AND m1.StatisticsName = s1.StatisticsName ORDER BY s1.LastUpdated 
			)
		)

	IF @OnlyIndexStats = 1
		BEGIN
			DELETE FROM #Statistics WHERE StatisticsName LIKE '_WA_Sys_%'
		END


	IF @Debug = 1 OR @ConsoleMode=1
		BEGIN
			SELECT *FROM #Statistics S
			ORDER BY  (((ModificationCount / 100)+1) * (DaysBefore + 1)) DESC
		END

	-- Reorganize the indexes by the most fragmented and most accessed
	DECLARE Stats_Cursor CURSOR FOR  
	SELECT 
		ObjectName,
		StatisticsName,
		StatisticsSQL 
	FROM #Statistics S
	ORDER BY (((ModificationCount / 100)+1) * (DaysBefore + 1)) DESC
	OPEN Stats_Cursor
	FETCH NEXT FROM Stats_Cursor INTO @ObjectName, @StatisticsName, @StatisticsSQL


	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		IF DATEDIFF(second, @AllStartTime, GETDATE()) >= (@MaxExecutionTime * 60)
			BEGIN
				BREAK;
			END

		SET @Counter += 1;

		IF @Debug = 1
			BEGIN
				PRINT @StatisticsSQL
				PRINT '---------------------------------'
				PRINT ''
			END
		ELSE
			BEGIN
				SET @UpdateStatStartTime = GETDATE()
				IF @ConsoleMode = 1 OR @Debug=1
					BEGIN
						PRINT CONVERT(VARCHAR(23), @UpdateStatStartTime, 120) + ' Updating stats ' + @ObjectName
						PRINT 'Update stats statement: ' + @StatisticsSQL
					END

				EXECUTE sp_executesql  @StatisticsSQL;


				IF @ConsoleMode = 1 OR @Debug=1
					BEGIN
						PRINT CONVERT(VARCHAR(23), GETDATE(), 120) + ' stats updated in ' + CONVERT(VARCHAR(10), DATEDIFF(second, @UpdateStatStartTime, GETDATE())) + ' seconds'
						PRINT '---------------------------------------------------------------------------------------'
						PRINT ''
					END

			END

		FETCH NEXT FROM Stats_Cursor INTO  @ObjectName, @StatisticsName, @StatisticsSQL

	END  
	CLOSE Stats_Cursor
	DEALLOCATE Stats_Cursor

	DROP TABLE #Multiple
	DROP TABLE #Statistics;
END
GO


