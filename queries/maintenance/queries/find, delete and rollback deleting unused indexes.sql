-- script for deleting and recreating the list of indexes
-- useful when you have to delete a large number of unused indexes and have rollback script for this
DECLARE @t TABLE (  id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
                    TableName VARCHAR(100),
                    IndexName VARCHAR(100),
                    TotalWrites BIGINT,
                    TotalReads BIGINT,
                    DIFFERENCE BIGINT,
                    last_user_seek DATETIME,
                    last_user_scan DATETIME,
                    last_user_lookup DATETIME,
                    [% of using] FLOAT)
INSERT INTO @t                      
SELECT  OBJECT_NAME(s.object_id) AS 'Table Name',
        i.name AS 'Index Name',
        user_updates AS 'Total Writes',
        user_seeks + user_scans + user_lookups AS 'Total Reads',
        user_updates - ( user_seeks + user_scans + user_lookups ) AS 'Difference',
        last_user_seek,
        last_user_scan,
        s.last_user_lookup,
        CAST(((user_seeks + user_scans + user_lookups)*100.0)/user_updates AS NUMERIC(10,2)) AS '% of using'
FROM    sys.dm_db_index_usage_stats AS s WITH ( NOLOCK )
        INNER JOIN sys.indexes AS i WITH ( NOLOCK ) ON s.object_id = i.object_id
                                                       AND i.index_id = s.index_id
WHERE   OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
        AND s.database_id = DB_ID()
        AND user_updates > ( user_seeks + user_scans + user_lookups )
        and user_seeks + user_scans + user_lookups = 0
        AND i.index_id > 1
                
DECLARE @t2 TABLE ( id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
                    TableName           VARCHAR(100),
                    IndexName           VARCHAR(100),
                    ColumnName          VARCHAR(100),
                    index_column_id     INT,
                    key_ordinal         INT,
                    is_descending_key   BIT,
                    is_included_column  BIT
                  )
INSERT INTO @t2                    
SELECT 
        t.TableName AS TableName,
        t.IndexName AS IndexName,  
        c.name AS ColumnName,
        ic.index_column_id,
        ic.key_ordinal,
        ic.is_descending_key,
        ic.is_included_column
FROM sys.indexes i
JOIN @t t ON t.IndexName = i.name
JOIN sys.tables AS t2 ON t2.name = t.TableName AND t2.[object_id] = i.[object_id] 
JOIN sys.index_columns AS ic ON ic.OBJECT_ID = t2.OBJECT_ID AND ic.index_id = i.index_id
JOIN sys.[columns] AS c ON c.OBJECT_ID = t2.[object_id] AND c.column_id = ic.column_id
WHERE i.type_desc = 'NONCLUSTERED'

SELECT  DISTINCT
        'if (indexproperty(object_id(''dbo.' + t.TableName + '''),''' + t.IndexName + ''',''IsClustered'') is not null) begin;' + CHAR(10) + 
        '   print ''' + CAST(ROW_NUMBER() OVER (ORDER BY t.TableName, t.IndexName) AS VARCHAR) + ' Deleting index ' + t.IndexName + ''';' + CHAR(10) +
        '   drop index [' + t.IndexName + '] ON [dbo].[' + t.TableName + ']' + CHAR(10) +
        'end;'  + CHAR(10) +
        'go' + CHAR(10) AS [drop index statement],

        'if (indexproperty(object_id(''dbo.' + t.TableName + '''),''' + t.IndexName + ''',''IsClustered'') is null) begin;' + CHAR(10) + 
        '   print ''' + CAST(ROW_NUMBER() OVER (ORDER BY t.TableName, t.IndexName) AS VARCHAR) + ' Creating index ' + t.IndexName + ''';' + CHAR(10) +
        '   create nonclustered index [' + t.IndexName + '] ON [dbo].[' + t.TableName + ']' + CHAR(10) +
        '   (' + LEFT(string, LEN(string) - 1) + ')' + CASE WHEN included_string IS NOT NULL THEN ' INCLUDE (' + LEFT(included_string, LEN(included_string) - 1) + ')' ELSE '' END + CHAR(10) +
        'end;'  + CHAR(10) +
        'go' + CHAR(10) AS [create index statement]
FROM    (
            SELECT t.TableName,
                   t.IndexName,
                   t.is_included_column,
                   (select '[' + convert(varchar(200),td.ColumnName) + ']' + CASE td.is_descending_key WHEN 1 THEN ' DESC' ELSE ' ASC' END + ', ' from @t2 td where t.TableName = td.TableName AND t.IndexName = td.IndexName and td.is_included_column = 0 ORDER BY td.index_column_id     for xml path('')) AS string,
                   (select '[' + convert(varchar(200),td.ColumnName) + ']' + ', ' from @t2 td where t.TableName = td.TableName AND t.IndexName = td.IndexName and td.is_included_column = 1 ORDER BY td.index_column_id     for xml path('')) AS included_string 
            FROM @t2 t
) t
