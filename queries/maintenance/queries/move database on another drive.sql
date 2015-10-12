--Step 1: Get the current database files Logical Name and Physical Location

USE master
GO
SELECT name AS LogicalFileName, physical_name AS FileLocation
, state_desc AS Status 
FROM sys.master_files 
WHERE database_id = DB_ID('Test');

--Step 2: Take the Database offline
USE master
GO
ALTER DATABASE Test SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

--Step 3: Move DB files to new logical drive

--Step 4: Use ALTER DATABASE to modify the FILENAME to new location for every file moved
--        Only one file can be moved at a time using ALTER DATABASE.
USE master
GO
ALTER DATABASE test
MODIFY FILE 
( NAME = test, 
FILENAME = 'Q:\BvtDatabases\test.mdf'); -- New file path

USE master
GO
ALTER DATABASE test 
MODIFY FILE 
( NAME = test_log, 
FILENAME = 'Q:\BvtDatabases\test_log.ldf'); -- New file path

--Step 5: Set the database ONLINE

USE master
GO
ALTER DATABASE test SET ONLINE;

--Step 6: Now, verify the database files Physical location

USE master
GO
SELECT name AS FileName, physical_name AS CurrentFileLocation, state_desc AS Status 
FROM sys.master_files 
WHERE database_id = DB_ID('test');