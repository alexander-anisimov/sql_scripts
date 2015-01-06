USE Limits
 GO
DBCC SHRINKFILE(Limits_Log, 1)
BACKUP LOG Limits 
  TO DISK = 'e:\Limits.bakl' 
DBCC SHRINKFILE(Limits_Log, 1)
GO
USE Admiral
 GO
DBCC SHRINKFILE(Admiral_log, 1)
BACKUP LOG Admiral
  TO DISK = 'e:\Admiral.bakl' 
DBCC SHRINKFILE(Admiral_log, 1)
GO
USE Accountant
 GO
DBCC SHRINKFILE(Accountant_log, 1)
BACKUP LOG Accountant
  TO DISK = 'e:\Accountant.bakl' 
DBCC SHRINKFILE(Accountant_log, 1)
GO