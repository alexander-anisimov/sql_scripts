-- DROP TABLE
DROP TABLE csa_tree

-- VIEW FOREIFN KEYS
SELECT  OBJECT_NAME(k.parent_OBJECT_ID) AS 'TableName', k.name, k.[object_id], k.parent_object_id, k.type_desc
FROM sys.foreign_keys k
WHERE referenced_object_id = object_id('csa_tree')

-- DROP TEXT FOREIGN KEYS 
SELECT 
    'ALTER TABLE ' + OBJECT_NAME(parent_object_id) + 
    ' DROP CONSTRAINT ' + name
FROM sys.foreign_keys
WHERE referenced_object_id = object_id('csa_tree')

-- VIEW ALTER COMANDS
ALTER TABLE csa_tree DROP CONSTRAINT FK_CSA_TREE_ID_CSA_TREE_PARENTID

-- DROP COLUMNS
ALTER TABLE csa_reason_codes
DROP COLUMN ApproveSiteID

-- RENAME COLUMNS
EXEC sp_rename 'csa_reason_codes.ApproveUserID', 'aUserID', 'COLUMN'
