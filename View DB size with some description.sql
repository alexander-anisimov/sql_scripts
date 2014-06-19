-- DB SIZE USED/UNUSED
SELECT	db_name() AS 'DB', file_id, name, type_desc, physical_name, size/128. AS 'Size (MB)', CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128. AS 'Used Space (MB)', 
		size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128. AS 'Available Space (MB)'
FROM sys.database_files;

-- DB FILES WITH DESCRIPTION
SELECT * FROM sys.master_files WHERE database_id = 2;

-- FREE SPACE ON DB
SELECT	SUM(unallocated_extent_page_count)				AS 'free pages', 
		(SUM(unallocated_extent_page_count)*1.0/128)	AS 'free space in MB'
FROM sys.dm_db_file_space_usage;

-- Get Longer Transactions at this moment
SELECT transaction_id, * FROM sys.dm_tran_active_snapshot_database_transactions ORDER BY elapsed_time_seconds DESC;

-- Standart sp for view database size
exec sp_spaceused

-- GET OPEN TRANSACTIONS
dbcc opentran 