USE DBName

DECLARE @DBName NVARCHAR(MAX) = 'DBName'

CREATE TABLE #users(ID INT IDENTITY(1, 1), UserName NVARCHAR(MAX), [GUID] UNIQUEIDENTIFIER)
CREATE TABLE #login_mapping (LoginName NVARCHAR(MAX), DBname NVARCHAR(MAX), Username NVARCHAR(MAX), AliasName NVARCHAR(MAX))

INSERT INTO #users(UserName, [GUID])
EXEC sp_change_users_login @Action='Report';

INSERT INTO #login_mapping 
EXEC master..sp_msloginmappings 

DECLARE @id INT = 1, @maxid INT = (SELECT COUNT(*) FROM #users), @UserName NVARCHAR(MAX), @LoginName NVARCHAR(MAX)

WHILE (@id < @maxid)
BEGIN
	SELECT @UserName = u.UserName FROM #users AS u WHERE u.ID = @id
	SELECT @LoginName = lm.LoginName FROM #login_mapping AS lm WHERE lm.Username = @UserName AND lm.DBname = @DBName

	--EXEC sp_change_users_login @Action='update_one', @UserNamePattern=@UserName, @LoginName=@LoginName;
	EXEC sp_change_users_login @Action='update_one', @UserNamePattern=@UserName, @LoginName=@UserName;
	--SELECT @UserName AS 'UN', @LoginName AS 'LN'

	SET @id = @id + 1
END

DROP TABLE #login_mapping
DROP TABLE #users