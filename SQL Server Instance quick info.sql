/******1.Run this script in sql query analyzer using management studio. 
       2.Feel free to pitch-in if you have any recommendations to modify this script.
*******/

EXEC sp_configure 'xp_cmdshell', 1
PRINT 'Ignore the line above.'
RECONFIGURE
PRINT CHAR(13)
PRINT CHAR(13)
PRINT CHAR(13)

USE [YOURDATABASE]
GO

SET NOCOUNT ON;
declare @errorlog VARCHAR(500) 
print '***************************************************************'
print '            DBA SQL Instance quality check '
print '                                                               '
print ' A. See SQL server name                          '
print ' B. See Instance name              '
print ' C. See Current Date Time          '
print ' D. See SQL version      '
print ' E. See ErrorLog file location               '
print ' F. See per our standard Login audit mode we want is  2 = failed Logins only   '
print ' G. See server auth, Mixed Mode = 0 or 2 ,Integrated = 1'
print ' H. See Name of Members in SysAdmin role'
print ' I. See Name of members in ServerAdmin'
print ' J. See Temp DB File Location.'
print ' K. See MDF, LDF & NDF File Location'
print ' L. See Max server Memory(GB)'
print ' M. See Min server memory (GB)'
print ' N. See Lock Pages in Memory'
print '***************************************************************'

print ''
print ' General Info'
print '****************************************************************'
print ''

print 'A. SQL Server Name.....................: ' + convert(varchar(30),@@SERVERNAME)        
print 'B. Instance............................: ' + convert(varchar(30),@@SERVICENAME)       
print 'C. Current Date Time...................: ' + convert(varchar(30),getdate(),113)
print 'D. SQL version.........................: '  + convert(varchar(300),@@VERSION) 

SELECT @errorlog = REPLACE(CAST(SERVERPROPERTY('ErrorLogFileName') AS VARCHAR(500)), 'ERRORLOG','')

print 'E. ErrorLog file location..............: ' +@errorlog

declare @AuditLevel int,
		@AuditLvltxt VARCHAR(50)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', @AuditLevel OUTPUT

SELECT @AuditLvltxt = CASE 
		WHEN @AuditLevel = 0
		THEN 'None.'
		WHEN @AuditLevel = 1
		THEN 'Successful logins only.'
		WHEN @AuditLevel = 2
		THEN 'Failed logins only.'
		WHEN @AuditLevel = 3
		THEN 'Both failed and successful logins.'
		ELSE 'Unknown.'
		END

--print 'F. AuditLevel.................: ' + convert(varchar(300), @AuditLevel)
print 'F. AuditLevel..........................: ' + @AuditLvltxt

declare @LoginMode int,
		@LoginModetxt VARCHAR(50)

exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', @LoginMode OUTPUT

SELECT @LoginModetxt = CASE
		WHEN @LoginMode IN (0,2)
		THEN 'SQL Server and Windows Authentication mode.'
		WHEN @LoginMode = 1
		THEN 'Windows Authentication mode.'
		ELSE 'Unknown.'
		END
print 'G. LoginMode...........................: ' + @LoginModetxt
--select 'we want LoginMode = 1'

--Verify Account RoleMembers for serverAdmin and SYSAdmin

SET NOCOUNT ON
print 'H. Name of Members in SysAdmin role....:'

--DECLARE @sysAdmin table (ServerRole CHAR(20), name CHAR(50), memberid VARBINARY(128))
DECLARE @sysAdmin table (ServerRole CHAR(20), name sysname) 
DECLARE @ServerRole CHAR(20), @name  CHAR(50)

--INSERT @sysAdmin exec sp_helpsrvrolemember 'sysadmin' Changed to IS_SRVROLEMEMBER('sysadmin', name), 
INSERT INTO @sysAdmin
SELECT	'sysadmin',
		name COLLATE DATABASE_DEFAULT AS MemberName
  FROM	sys.server_principals
 WHERE	IS_SRVROLEMEMBER('sysadmin', name) = 1

DECLARE sysAdmin_cursor CURSOR FOR SELECT ServerRole, name from @sysAdmin

Open sysAdmin_cursor

FETCH NEXT FROM sysAdmin_cursor INTO 
@ServerRole, @name

WHILE (@@FETCH_STATUS = 0) 
BEGIN
      PRINT '        Login - ' + @name  + '    LoginIs - ' +  @ServerRole

      FETCH NEXT FROM sysAdmin_cursor INTO 
		@ServerRole, @name


END

CLOSE sysAdmin_cursor
DEALLOCATE sysAdmin_cursor

print ''

print 'I. Name of Members in Serveradmin role.:'

--DECLARE @serverAdmin table (ServerRole CHAR(20), name CHAR(50), memberid VARBINARY(128))
DECLARE @serverAdmin table (ServerRole CHAR(20), name sysname) 
DECLARE @ServerRole1 CHAR(20), @name1  CHAR(50)


INSERT INTO @serverAdmin
SELECT	r.name,
		p.name  AS MemberName
  FROM	sys.server_principals r
  JOIN	sys.server_role_members m 
    ON	r.principal_id = m.role_principal_id
  JOIN	sys.server_principals p 
    ON	p.principal_id = m.member_principal_id
 WHERE	(r.type ='R')and(r.name='serveradmin')

DECLARE serverAdmin_cursor CURSOR FOR SELECT ServerRole, name from @serverAdmin

Open serverAdmin_cursor

FETCH NEXT FROM serverAdmin_cursor INTO 
@ServerRole1, @name1

WHILE (@@FETCH_STATUS = 0) 
BEGIN
      PRINT '        Login - ' + @name1  + '    LoginIs - ' +  @ServerRole1

      FETCH NEXT FROM serverAdmin_cursor INTO 
		@ServerRole1, @name1


END

CLOSE serverAdmin_cursor
DEALLOCATE serverAdmin_cursor

print ' ' 

--Verify TEMP DB files.
print 'J. Temp DB File Location.................:'

      DECLARE @filename NVARCHAR(520)

      DECLARE tempfile_cursor CURSOR FOR SELECT filename from sys.sysaltfiles where name like '%temp%'

      Open tempfile_cursor

      FETCH NEXT FROM tempfile_cursor INTO 
      @filename

      WHILE (@@FETCH_STATUS = 0) 
      BEGIN

              PRINT 'TEMP DB File......' + @filename
            
              FETCH NEXT FROM tempfile_cursor INTO 
              @filename
      END
      CLOSE tempfile_cursor
      DEALLOCATE tempfile_cursor
      

--Query to get LUN names from SQL server
print ' ' 
print 'K. MDF, LDF & NDF File Location..........:'
      DECLARE @Physical_Name NVARCHAR(520)

      DECLARE masterfile_cursor CURSOR FOR SELECT physical_name FROM sys.master_files WHERE physical_name NOT LIKE '%tempdb%'

      Open masterfile_cursor

      FETCH NEXT FROM masterfile_cursor INTO 
      @Physical_Name 

      WHILE (@@FETCH_STATUS = 0) 
      BEGIN

              PRINT 'Physical Name......' + @Physical_Name
            
              FETCH NEXT FROM masterfile_cursor INTO 
              @Physical_Name
      END
      CLOSE masterfile_cursor
      DEALLOCATE masterfile_cursor

--use below query to  display the Minimun and Maximum memory in (MB)
print ' ' 

Declare @Value sql_variant
DECLARE @val_InDecimal DECIMAL
select @Value = value from sys.configurations where name = 'max server memory (MB)';
SET @val_InDecimal = convert(DECIMAL, @Value)/ 1024
print 'L. Max server Memory(GB).................: ' + convert(varchar(50), @val_InDecimal)

SET @Value = NULL
SET @val_InDecimal = NULL
select @Value = value from sys.configurations where name = 'min server memory (MB)';
SET @val_InDecimal = convert(DECIMAL, @Value)/ 1024
print 'M. Min server memory (GB)................: ' + convert(varchar(50), @val_InDecimal)


-- How to check Lock Pages In Memory is enabled
--You can use below simple technique to check whether lock pages in memory is enabled or not. 


CREATE TABLE #xp_cmdshell_output (Output VARCHAR (8000)); 

-- The whoami command is run as the AD Account that SQL is running under
-- which is the account that needs to have lock pages in memory.
INSERT INTO #xp_cmdshell_output EXEC ('xp_cmdshell ''whoami /priv'''); 

IF EXISTS (SELECT * FROM #xp_cmdshell_output WHERE Output LIKE '%SeLockMemoryPrivilege%enabled%') 
PRINT 'N. Lock Pages in Memory..................: Enabled'
ELSE 
PRINT 'N. Lock Pages in Memory..................: Disabled'; 

DROP TABLE #xp_cmdshell_output; 

PRINT CHAR(13)
PRINT CHAR(13)
PRINT CHAR(13)
PRINT 'Ignore the line below.'
EXEC sp_configure 'xp_cmdshell', 0
RECONFIGURE
