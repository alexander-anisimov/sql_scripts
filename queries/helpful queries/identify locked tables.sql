SELECT
OBJECT_NAME(p.OBJECT_ID) AS TableName,
resource_type, resource_description
FROM
sys.dm_tran_locks l
JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id