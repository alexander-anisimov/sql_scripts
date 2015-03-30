SELECT sqlserver_start_time FROM sys.dm_os_sys_info
SELECT 'Statistics since: ' + CAST(sqlserver_start_time AS VARCHAR) FROM sys.dm_os_sys_info