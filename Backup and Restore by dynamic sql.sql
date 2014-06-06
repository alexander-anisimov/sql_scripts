-- initialization
DECLARE @full NVARCHAR(MAX) = '', 
		@diff NVARCHAR(MAX) = '',
		@log NVARCHAR(MAX) = '',
		@restore NVARCHAR(MAX) = '',
		@date NVARCHAR(23) = REPLACE(CONVERT(NVARCHAR(23), GETDATE(), 126), ':', '.'),
		@removeDate DATETIME = DATEADD(DAY, -14, GETDATE())

-- perform scripts
SELECT @full = @full + 
				'BACKUP DATABASE ' + d.name + ' TO DISK = ''d:\Data\Backup\DynamicSQL\' + d.name + '\' + d.name + '_full_' + @date + '.bak''
				MIRROR TO DISK = ''d:\Data\Backup\DynamicSQL\Mirror\' + d.name + '\' + d.name + '_full_' + @date + '.bak'' WITH FORMAT, COMPRESSION, CHECKSUM; 
				RESTORE VERIFYONLY FROM DISK = ''d:\Data\Backup\DynamicSQL\' + d.name + '\' + d.name + '_full_' + @date + '.bak'';'
FROM sys.databases AS d WHERE d.name IN ('myDB','master', 'msdb', 'model')
EXEC (@full)
--PRINT @full

SELECT @diff = @diff + 
				'BACKUP DATABASE ' + d.name + ' TO DISK = ''d:\Data\Backup\DynamicSQL\' + d.name + '\' + d.name + '_diff_' + @date + '.bak''
				MIRROR TO DISK = ''d:\Data\Backup\DynamicSQL\Mirror\' + d.name + '\' + d.name + '_diff_' + @date + '.bak'' WITH DIFFERENTIAL, FORMAT, COMPRESSION, CHECKSUM;
				RESTORE VERIFYONLY FROM DISK = ''d:\Data\Backup\DynamicSQL\' + d.name + '\' + d.name + '_diff_' + @date + '.bak'';'
FROM sys.databases AS d WHERE d.name IN ('myDB')
EXEC (@diff)
--PRINT @diff

SELECT @log = @log + 
				'BACKUP LOG ' + d.name + ' TO DISK = ''d:\Data\Backup\DynamicSQL\' + d.name + '\' + d.name + '_log_' + @date + '.trn''
				MIRROR TO DISK = ''d:\Data\Backup\DynamicSQL\Mirror\' + d.name + '\' + d.name + '_log_' + @date + '.trn'' WITH FORMAT, COMPRESSION, CHECKSUM;
				RESTORE VERIFYONLY FROM DISK = ''d:\Data\Backup\DynamicSQL\' + d.name + '\' + d.name + '_log_' + @date + '.trn'';'
FROM sys.databases AS d WHERE d.name IN ('myDB')
EXEC (@log)
--PRINT @log

-- restore scripts
SELECT @restore = @restore + 
				'RESTORE DATABASE ' + d.name + ' FROM DISK = ''d:\Data\Backup\' + d.name + '_full_' + @date + '.bak'';
				'
FROM sys.databases AS d WHERE d.name IN ('myDB')

SELECT @restore = @restore + 
				'RESTORE DATABASE ' + d.name + ' FROM DISK = ''d:\Data\Backup\' + d.name + '_full_' + @date + '.bak'' WITH REPLACE;
				'
FROM sys.databases AS d WHERE d.name IN ('master', 'msdb', 'model')

-- delete old data backup files (14 days)
--EXEC xp_delete_file  0, N'd:\Data\Backup\', N'bak', N'2014-05-30T12:16:04', 1;
EXEC xp_delete_file 0, 'd:\Data\Backup\DynamicSQL\', N'bak', @removeDate, 1;

-- delete old log backup files (14 days)
--EXEC xp_delete_file  0, N'd:\Data\Backup\', N'trn', N'2014-05-30T12:16:04', 1;
EXEC xp_delete_file 0, 'd:\Data\Backup\DynamicSQL\', N'trn', @removeDate, 1;