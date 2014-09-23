DECLARE @sql NVARCHAR(MAX) = ''
SELECT @sql = @sql + 'ALTER LOGIN [' + loginname + '] WITH CHECK_EXPIRATION=OFF, CHECK_POLICY=ON; ' 
FROM syslogins 
WHERE	loginname NOT LIKE '%##%' 
	AND loginname NOT LIKE '%\%' 
	AND loginname NOT IN ('sa')

EXEC(@sql)