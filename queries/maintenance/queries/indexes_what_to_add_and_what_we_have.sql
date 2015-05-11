declare @tablename varchar(100) = 'case'
SELECT t.name AS 'affected_table'
    , 'Create NonClustered Index IX_' + t.name + '_missing_' 
        + CAST(ddmid.index_handle AS VARCHAR(10))
        + ' On ' + ddmid.STATEMENT COLLATE Latin1_General_CS_AS_KS_WS 
        + ' (' + IsNull(ddmid.equality_columns,'') COLLATE Latin1_General_CS_AS_KS_WS 
        + CASE WHEN ddmid.equality_columns IS Not Null 
            And ddmid.inequality_columns IS Not Null THEN ',' 
                ELSE '' END 
        + IsNull(ddmid.inequality_columns, '') COLLATE Latin1_General_CS_AS_KS_WS 
        + ')' 
        + IsNull(' Include (' + ddmid.included_columns + ');', ';'        ) COLLATE Latin1_General_CS_AS_KS_WS  AS sql_statement 
    , ddmigs.user_seeks
    , ddmigs.user_scans
    , CAST((ddmigs.user_seeks + ddmigs.user_scans) 
        * ddmigs.avg_user_impact AS INT) AS 'est_impact'
    , ddmigs.last_user_seek
FROM sys.dm_db_missing_index_groups AS ddmig
INNER JOIN sys.dm_db_missing_index_group_stats AS ddmigs
    ON ddmigs.group_handle = ddmig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS ddmid 
    ON ddmig.index_handle = ddmid.index_handle
INNER JOIN sys.tables AS t
    ON ddmid.OBJECT_ID = t.OBJECT_ID
WHERE ddmid.database_id = DB_ID()
    AND t.name = @tablename
ORDER BY CAST((ddmigs.user_seeks + ddmigs.user_scans) 
    * ddmigs.avg_user_impact AS INT) DESC

-- Index Read/Write stats for a single table
SELECT  OBJECT_NAME(s.object_id) AS 'TableName',
        i.name AS 'IndexName',
        i.index_id,
        SUM(user_seeks) AS 'User Seeks',
        SUM(user_scans) AS 'User Scans',
        SUM(user_lookups) AS 'User Lookups',
        SUM(user_seeks + user_scans + user_lookups) AS 'Total Reads',
        SUM(user_updates) AS 'Total Writes'
FROM    sys.dm_db_index_usage_stats AS s
        INNER JOIN sys.indexes AS i ON s.object_id = i.object_id
                                       AND i.index_id = s.index_id
WHERE   OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
        AND s.database_id = DB_ID()
        AND OBJECT_NAME(s.object_id) = @tableName
GROUP BY OBJECT_NAME(s.object_id),
        i.name,
        i.index_id
ORDER BY 'Total Writes' DESC,
        'Total Reads' DESC ;
