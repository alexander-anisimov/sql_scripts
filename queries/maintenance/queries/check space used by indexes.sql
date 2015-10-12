DECLARE @objname sysname = NULL;


SELECT o.name AS ObjName
		, i.name AS IdxName
		, ReservedMB = CONVERT(DECIMAL(19, 2), SUM(ps.reserved_page_count) / 128.0)
				/*
				-- ps.in_row_reserved_page_count + ps.lob_reserved_page_count + ps.row_overflow_reserved_page_count
				*/
		, TotalUsedMB = CONVERT(DECIMAL(19, 2), SUM( ps.used_page_count) / 128.0)
				/*
				-- ps.in_row_used_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count
				*/
		, TotalDataMB = CONVERT(DECIMAL(19, 2), SUM(ps.in_row_data_page_count
													 + ps.lob_used_page_count
													 + ps.row_overflow_used_page_count) / 128.0)
				/*
				--in_row_data_page_count = Number of pages in use for storing in-row data in this partition. If the partition is part of a heap, the value is the number of data pages in the heap. If the partition is part of an index, the value is the number of pages in the leaf level
				--lob_used_page_count = Number of pages in use for storing and managing out-of-row columns within the partition. IAM pages are included.
				--row_overflow_used_page_count = Number of pages in use for storing and managing row-overflow columns within the partition. IAM pages are included.
				*/	
		, UnusedMB = CONVERT(DECIMAL(19, 2), SUM(ps.reserved_page_count) / 128.0 - CONVERT(DECIMAL(19, 2), SUM( ps.used_page_count)) / 128.0)
		, RowCnt = MAX(ISNULL(row_count, 0))
	FROM sys.dm_db_partition_stats ps
		INNER JOIN sys.objects o
			ON o.object_id = ps.object_id
		INNER JOIN sys.indexes i
			ON i.object_id = o.object_id
				AND ps.index_id = i.index_id
	WHERE o.name = ISNULL(@objname, o.name)
		AND i.index_id NOT IN ( 0, 1, 255 )
		AND o.is_ms_shipped = 0
	GROUP BY GROUPING SETS(ROLLUP(o.name,i.name));