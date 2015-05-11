with pages as (
    SELECT object_id, SUM (reserved_page_count) as reserved_pages, SUM (used_page_count) as used_pages,
            SUM (case 
                    when (index_id < 2) then (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
                    else lob_used_page_count + row_overflow_used_page_count
                 end) as pages
    FROM sys.dm_db_partition_stats
    group by object_id
), extra as (
    SELECT p.object_id, sum(reserved_page_count) as reserved_pages, sum(used_page_count) as used_pages
    FROM sys.dm_db_partition_stats p, sys.internal_tables it
    WHERE it.internal_type IN (202,204,211,212,213,214,215,216) AND p.object_id = it.object_id
    group by p.object_id
)
SELECT object_schema_name(p.object_id) + '.' + object_name(p.object_id) as TableName, (p.reserved_pages + isnull(e.reserved_pages, 0)) * 8 as reserved_kb,
        pages * 8 as data_kb,
        (CASE WHEN p.used_pages + isnull(e.used_pages, 0) > pages THEN (p.used_pages + isnull(e.used_pages, 0) - pages) ELSE 0 END) * 8 as index_kb,
        (CASE WHEN p.reserved_pages + isnull(e.reserved_pages, 0) > p.used_pages + isnull(e.used_pages, 0) THEN (p.reserved_pages + isnull(e.reserved_pages, 0) - p.used_pages + isnull(e.used_pages, 0)) else 0 end) * 8 as unused_kb
from pages p
left outer join extra e on p.object_id = e.object_id