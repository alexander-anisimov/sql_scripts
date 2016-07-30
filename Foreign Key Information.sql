SELECT name AS ForeignKey_Name,
	object_schema_name(referenced_object_id) Parent_Schema_Name,
    object_name(referenced_object_id) Parent_Object_Name,
	object_schema_name(parent_object_id) Child_Schema_Name,
    object_name(parent_object_id) Child_Object_Name,
	is_disabled, is_not_trusted,
	'ALTER TABLE ' + quotename(object_schema_name(parent_object_id)) + '.' +
               quotename(object_name(parent_object_id)) + ' NOCHECK CONSTRAINT ' + 
               object_name(object_id) + '; ' AS Disable,
    'ALTER TABLE ' + quotename(object_schema_name(parent_object_id)) + '.' +
               quotename(object_name(parent_object_id)) + ' WITH CHECK CHECK CONSTRAINT ' + 
               object_name(object_id) + '; ' AS Enable
FROM sys.foreign_keys
-- Include this WHERE clause to pull the foreign keys for a single table (parent & child).
-- WHERE parent_object_id = object_id('TableName')
--   OR referenced_object_id = object_id('TableName')