;WITH cte AS
(
    SELECT parent_object_id = OBJECT_ID('dbo.Table1', 'U')

    UNION ALL

    SELECT fk.parent_object_id
    FROM cte t
    JOIN sys.foreign_keys fk ON t.parent_object_id = fk.referenced_object_id
)
SELECT OBJECT_NAME(parent_object_id)
FROM cte