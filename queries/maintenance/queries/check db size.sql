SELECT 
      database_name = DB_NAME(database_id)
    , row_size_mb = CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
FROM sys.master_files
WHERE database_id IN (DB_ID('SQLF'), DB_ID('SQLF_v2'))
GROUP BY database_id