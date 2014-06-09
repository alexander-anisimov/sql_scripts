SELECT 
      table_name = SCHEMA_NAME(o.[schema_id]) + '.' + o.name
    , data_size_mb = CAST(do.pages * 8. / 1024 AS DECIMAL(8,4))
FROM sys.objects o
JOIN (
    SELECT
          p.[object_id]
        , total_rows = SUM(p.[rows])
        , total_pages = SUM(a.total_pages)
        , usedpages = SUM(a.used_pages)
        , pages = SUM(
            CASE
                WHEN it.internal_type IN (202, 204, 207, 211, 212, 213, 214, 215, 216, 221, 222) THEN 0
                WHEN a.[type] != 1 AND p.index_id < 2 THEN a.used_pages
                WHEN p.index_id < 2 THEN a.data_pages ELSE 0
            END
          )
    FROM sys.partitions p
    JOIN sys.allocation_units a ON p.[partition_id] = a.container_id
    LEFT JOIN sys.internal_tables it ON p.[object_id] = it.[object_id]
    GROUP BY p.[object_id]
) do ON o.[object_id] = do.[object_id]
WHERE o.[type] = 'U'