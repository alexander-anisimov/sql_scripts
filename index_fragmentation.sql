SELECT db_name(database_id) AS 'DBName', OBJECT_NAME([object_id]) AS 'TableName', index_id, index_type_desc, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) 
WHERE	avg_fragmentation_in_percent > 50
	AND OBJECT_NAME([object_id]) NOT LIKE 'sys%' 
	AND index_type_desc <> 'HEAP' 
ORDER BY avg_fragmentation_in_percent DESC
