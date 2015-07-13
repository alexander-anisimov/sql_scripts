USE MASTER
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'd:\datatempdb.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'e:\datatemplog.ldf')
GO