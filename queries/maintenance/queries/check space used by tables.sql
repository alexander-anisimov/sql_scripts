CREATE TABLE #t(t_name varchar(255), rows varchar(255), reserved varchar(255), data varchar(255), index_size varchar(255), unused varchar(255));
INSERT INTO #t
exec sp_msforeachtable N'exec sp_spaceused ''?''';
SELECT --top 20
 t_name,
 rows,
 CONVERT(money, REPLACE(reserved, ' KB', ''))/1024 as [reserved (mb)],
 CONVERT(money, REPLACE(data, ' KB', ''))/1024 as [data (mb)],
 CONVERT(money, REPLACE(index_size, ' KB', ''))/1024 as [index_size (mb)],
 CONVERT(money, REPLACE(unused, ' KB', ''))/1024 as [unused (mb)]
FROM #t
ORDER BY 5 desc,4 DESC;
DROP TABLE #t;


