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
    --AND t.name = 'myTableName' 
ORDER BY CAST((ddmigs.user_seeks + ddmigs.user_scans) 
    * ddmigs.avg_user_impact AS INT) DESC


SELECT  TOP 10 
        [Total Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
        , avg_user_impact
        , TableName = statement
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [Include Cloumns] = included_columns
FROM        sys.dm_db_missing_index_groups g 
INNER JOIN    sys.dm_db_missing_index_group_stats s 
       ON s.group_handle = g.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details d 
       ON d.index_handle = g.index_handle
ORDER BY [Total Cost] DESC;    