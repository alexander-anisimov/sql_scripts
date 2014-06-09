set nocount on
declare @db char (128) = db_name(), 
        @cTable varchar (110), 
        @cIndex varchar (100), 
        @nFragm float, 
        @sql varchar (max)

declare btsPoz cursor local fast_forward for
select  s.name + '.' + t.name as TableName, 
        b.name as IndexName,
        ps.avg_fragmentation_in_percent
from    sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS ps
join    sys.indexes AS b 
    on  ps.OBJECT_ID = b.OBJECT_ID
    and ps.index_id = b.index_id
join    sys.objects t 
    on ps.object_id = t.object_id
join    sys.schemas s
    on  t.schema_id = s.schema_id
where   ps.database_id = DB_ID() 
    and ps.avg_fragmentation_in_percent > 30
    and ps.page_count > 100 
    and b.Name is not null
    AND ps.index_id > 0
order by ps.avg_fragmentation_in_percent desc

open btsPoz
fetch from btsPoz into @cTable, @cIndex, @nFragm
while @@fetch_status = 0 begin
    --DBCC INDEXDEFRAG (@db, @cTable, @cIndex)-- WITH NO_INFOMSGS
    --set @sql = 'ALTER INDEX ' + rtrim(@cIndex) + ' ON ' + rtrim(@cTable) + ' REBUILD PARTITION = ALL'
    --print @sql
    --exec (@sql)

    set @sql = 'ALTER INDEX ' + rtrim(@cIndex) + ' ON ' + rtrim(@cTable) + ' REORGANIZE'
    print @sql
    exec (@sql)
    print ''
    fetch from btsPoz into @cTable, @cIndex, @nFragm
end

close btsPoz
deallocate btsPoz
