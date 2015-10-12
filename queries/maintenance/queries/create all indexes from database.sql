select 'CREATE NONCLUSTERED INDEX ' + i.name + ' ON [' + o.name + '] (' + Columns.[Normal] + ')' + CASE WHEN Columns.[Included] IS NULL THEN '' ELSE ' INCLUDE (' + Columns.[Included] + ')' END as SQLStatement,
    o.name as ObjectName, 
    i.name as IndexName, 
    i.is_primary_key as [PrimaryKey],
    SUBSTRING(i.[type_desc],0,6) as IndexType,
    i.is_unique as [Unique],
    Columns.[Normal] as IndexColumns,
    Columns.[Included] as IncludedColumns
from sys.indexes i 
join sys.objects o on i.object_id = o.object_id
cross apply
(
    select
        substring
        (
            (
                select ', ' + co.[name]
                from sys.index_columns ic
                join sys.columns co on co.object_id = i.object_id and co.column_id = ic.column_id
                where ic.object_id = i.object_id and ic.index_id = i.index_id and ic.is_included_column = 0
                order by ic.key_ordinal
                for xml path('')
            )
            , 3
            , 10000
        )    as [Normal]    
        , substring
        (
            (
                select ', ' + co.[name]
                from sys.index_columns ic
                join sys.columns co on co.object_id = i.object_id and co.column_id = ic.column_id
                where ic.object_id = i.object_id and ic.index_id = i.index_id and ic.is_included_column = 1
                order by ic.key_ordinal
                for xml path('')
            )
            , 3
            , 10000
        )    as [Included]    

) Columns
where o.[type] = 'U' AND o.name NOT LIKE 'sys%' AND o.name NOT LIKE 'MSpeer%' AND o.name NOT LIKE 'mspub%' AND o.name NOT LIKE 'MSsaved%' AND o.name NOT LIKE 'MSSnapshot%' AND o.name NOT LIKE 'MSSubscription%' AND SUBSTRING(i.[type_desc],0,6) = 'NONCL'--USER_TABLE
order by o.[name], i.[name], i.is_primary_key desc
