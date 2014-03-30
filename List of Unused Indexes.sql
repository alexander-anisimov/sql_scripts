-- неиспользуемые индексы, кандидаты на удаление
SELECT DatabaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       user_updates,
       system_updates,
      'alter index [' +OBJECT_SCHEMA_NAME(i.object_id, DB_ID())+ '].['+i.name+'] ON ['+OBJECT_NAME(s.[object_id])+'] DISABLE' as [Disable],
      'exec sp_rename ''['+OBJECT_SCHEMA_NAME(i.object_id, DB_ID())+'].['+OBJECT_NAME(s.[object_id])+'].['+i.name+']'',''disable_'+i.name+''',''INDEX''' as [Rename]
  FROM sys.dm_db_index_usage_stats s 
  INNER JOIN sys.indexes i ON s.object_id = i.object_id and
                              s.index_id  = i.index_id
  WHERE s.database_id = DB_ID() and
        OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 and
        s.user_seeks   = 0 and
        s.user_scans   = 0 and
        s.user_lookups = 0 and
        i.is_disabled  = 0 and
        i.is_unique = 0 and
        i.is_primary_key = 0 and
        i.type_desc <> 'HEAP'
  order by user_updates + system_updates desc