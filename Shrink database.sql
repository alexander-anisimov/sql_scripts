-- 1 Step
DBCC SHRINKFILE (tempdev,5000)
DBCC SHRINKDATABASE (tempdev,10)

-- DB Status on Shrinkdatabase process
USE [YourDB]
SELECT percent_complete, start_time, status, command, estimated_completion_time, cpu_time, total_elapsed_time FROM sys.dm_exec_requests WHERE command = 'DbccFilesCompact'

-- View open transactions
DBCC opentran

-- Clean others
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
DBCC FREESYSTEMCACHE ('ALL')
DBCC FREESESSIONCACHE

-- 2 Step
DBCC shrinkfile (tempdev,5000)