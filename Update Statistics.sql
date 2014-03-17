DECLARE @DateNow DATETIME
SELECT @DateNow = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))

DECLARE @SQL NVARCHAR(MAX)
SELECT @SQL = (
    SELECT '
    UPDATE STATISTICS [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] [' + s.name + ']
        WITH FULLSCAN' + CASE WHEN s.no_recompute = 1 THEN ', NORECOMPUTE' ELSE '' END + ';'
    FROM (
        SELECT 
              [object_id]
            , name
            , stats_id
            , no_recompute
            , last_update = STATS_DATE([object_id], stats_id)
        FROM sys.stats WITH(NOLOCK)
        WHERE auto_created = 0
            AND is_temporary = 0
    ) s
    JOIN sys.objects o WITH(NOLOCK) ON s.[object_id] = o.[object_id]
    JOIN (
        SELECT
              p.[object_id]
            , p.index_id
            , total_pages = SUM(a.total_pages)
        FROM sys.partitions p WITH(NOLOCK)
        JOIN sys.allocation_units a WITH(NOLOCK) ON p.[partition_id] = a.container_id
        GROUP BY 
              p.[object_id]
            , p.index_id
    ) p ON o.[object_id] = p.[object_id] AND p.index_id = s.stats_id
    WHERE o.[type] IN ('U', 'V')
        AND o.is_ms_shipped = 0
        AND (
              last_update IS NULL AND p.total_pages > 0 -- never updated and contains rows
            OR
              last_update <= DATEADD(dd, 
                CASE WHEN p.total_pages > 4096 -- > 4 MB
                    THEN -2 -- updated 3 days ago
                    ELSE 0 
                END, @DateNow)
        )
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')

PRINT @SQL
EXEC sys.sp_executesql @SQL
