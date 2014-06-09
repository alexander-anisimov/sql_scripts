SELECT  SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(o.object_id) as Name, 
        o.type, 
        c.text
FROM syscomments c 
INNER JOIN sys.objects o ON c.id = o.object_id
WHERE c.text like '%SPROC_NAME%' 
Order by 2,1