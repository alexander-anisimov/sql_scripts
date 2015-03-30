/*=============================================
  File: SQL_Server_last_restart.sql
 
  Author: Thomas LaRock, http://thomaslarock.com/contact-me/  
  http://thomaslarock.com/2015/03/how-to-find-when-wait-stats-were-last-cleared
 
  Summary: This script will return the following items:
		1. The last time the server was rebooted
		2. The last time the SQL instance was restarted
		3. The last time DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR) was executed
 
  Variables:
    None
 
  Date: March 19th, 2015
 
  SQL Server Versions: SQL2008R2, SQL2012, SQL2014
 
  You may alter this code for your own purposes. You may republish
  altered code as long as you give due credit. 
 
  THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
  FITNESS FOR A PARTICULAR PURPOSE.
 
=============================================*/
 
/*=============================================
 Drop/create our temp table
=============================================*/
IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects 
	WHERE id = OBJECT_ID(N'tempdb.dbo.#tmp_RestartTime')
	AND type IN (N'U'))
	DROP TABLE #tmp_RestartTime
GO
 
CREATE TABLE #tmp_RestartTime
	(Name VARCHAR(20),
	RestartDate DATETIME)
GO
 
 
/*=============================================
 Get the ServerRestart time, insert into #tmp_RestartTime 
=============================================*/
INSERT INTO #tmp_RestartTime
SELECT 'ServerRestart', DATEADD(ms, -ms_ticks, GETDATE())
FROM sys.dm_os_sys_info
 
 
/*=============================================
 Get the SQLRestart time, insert into #tmp_RestartTime 
=============================================*/
INSERT INTO #tmp_RestartTime
SELECT 'SQLRestart', sqlserver_start_time
FROM sys.dm_os_sys_info
 
 
/*=============================================
 Get the DMVRestart time, insert into #tmp_RestartTime 
=============================================*/
INSERT INTO #tmp_RestartTime
SELECT 'DMVRestart', DATEADD(ms, -wait_time_ms, GETDATE())
FROM sys.dm_os_wait_stats
WHERE wait_type = 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
 
 
/*=============================================
 Return result from #tmp_RestartTime
=============================================*/
SELECT *
FROM #tmp_RestartTime