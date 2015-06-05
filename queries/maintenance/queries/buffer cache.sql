select
       count(*)as cached_pages_count,
       obj.name as objectname,
       ind.name as indexname,
       obj.index_id as indexid
from sys.dm_os_buffer_descriptors as bd
    inner join
    (
        select       object_id as objectid,
                           object_name(object_id) as name,
                           index_id,allocation_unit_id
        from sys.allocation_units as au
            inner join sys.partitions as p
                on au.container_id = p.hobt_id
                    and (au.type = 1 or au.type = 3)
        union all
        select       object_id as objectid,
                           object_name(object_id) as name,
                           index_id,allocation_unit_id
        from sys.allocation_units as au
            inner join sys.partitions as p
                on au.container_id = p.partition_id
                    and au.type = 2
    ) as obj
        on bd.allocation_unit_id = obj.allocation_unit_id
left outer join sys.indexes ind 
  on  obj.objectid = ind.object_id
 and  obj.index_id = ind.index_id
where bd.database_id = db_id()
  and bd.page_type in ('data_page', 'index_page')
group by obj.name, ind.name, obj.index_id
order by cached_pages_count desc