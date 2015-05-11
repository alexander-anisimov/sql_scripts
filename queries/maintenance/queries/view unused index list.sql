--Possible bad Indexes (writes > reads)
SELECT  OBJECT_NAME(s.object_id) AS 'Table Name',
        i.name AS 'Index Name',
        i.index_id,
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
        AND i.index_id > 1
ORDER BY '% of using',
        'Table Name'
        --'Difference' DESC,
        --'Total Writes' DESC,
        --'Total Reads' ASC ;
        
        
-- Index Read/Write stats for a single table
SELECT  OBJECT_NAME(s.object_id) AS 'TableName',
        i.name AS 'IndexName',
        i.index_id,
        SUM(user_seeks) AS 'User Seeks',
        SUM(user_scans) AS 'User Scans',
        SUM(user_lookups) AS 'User Lookups',
        SUM(user_seeks + user_scans + user_lookups) AS 'Total Reads',
        SUM(user_updates) AS 'Total Writes'
FROM    sys.indexes AS i
        LEFT JOIN sys.dm_db_index_usage_stats AS s ON s.object_id = i.object_id
                                       AND i.index_id = s.index_id
WHERE   OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
        AND s.database_id = DB_ID()
        AND OBJECT_NAME(s.object_id) = 'InsuranceCoverage'
GROUP BY OBJECT_NAME(s.object_id),
        i.name,
        i.index_id
ORDER BY 'Total Writes' DESC,
        'Total Reads' DESC ;

