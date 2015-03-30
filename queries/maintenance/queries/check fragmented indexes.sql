--5. Получение и анализ информации о дефрагментации индексов.
--На больших БД при наличии большого количества индексов зачастую дефрагментация индексов очень сильно влияет на время выполнения запроса. 
--С помощью этого скрипта можно получить информацию по индексам, дефрагментация которых составляет более 30% и количество страниц которых больше 100:
SELECT
      db.name AS databaseName
    , t.name as TableName
    , ps.index_id AS indexID
    , ps.partition_number AS partitionNumber
    , ps.avg_fragmentation_in_percent AS fragmentation
    , ps.page_count
FROM sys.databases db
  INNER JOIN sys.dm_db_index_physical_stats (9, NULL, NULL , NULL, N'Limited') ps
      ON db.database_id = ps.database_id
  JOIN sys.tables t on t.object_id = ps.object_id
WHERE ps.index_id > 0 
   AND ps.page_count > 100 
   AND ps.avg_fragmentation_in_percent > 30
order by fragmentation desc
OPTION (MaxDop 1);
