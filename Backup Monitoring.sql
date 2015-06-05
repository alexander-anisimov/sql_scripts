-- Get some helpful information about last backups
SELECT CAST(@@ServerName AS VarChar) AS Server_Name, 
	CAST(sysdatabases.name AS VarChar) AS Database_Name, CAST(sysdatabases.cmptlevel AS Int) CtmpLevel, 
	CAST(ISNULL(DatabasePropertyEx(sysdatabases.name,'Status'),'Removed') AS VarChar) AS Status,
	CAST(DatabasePropertyEx(sysdatabases.name,'Updateability') AS VarChar) AS Updateability,
	CAST(DatabasePropertyEx(sysdatabases.name,'UserAccess') AS VarChar) AS UserAccess,
	CAST(DatabasePropertyEx(sysdatabases.name,'Recovery') AS VarChar) AS Recovery,
	MAX(CASE WHEN type = 'D' THEN backup_finish_date ELSE NULL END) AS LastFull,
	MAX(CASE WHEN type = 'I' THEN backup_finish_date ELSE NULL END) AS LastDifferential,
	MAX(CASE WHEN type = 'L' THEN backup_finish_date ELSE NULL END) AS LastLog,
	-- I'm not worrying about the following types of backups although that could
	-- obviously be pulled just as easily.
	--	F = File or filegroup 
	--	G = Differential file 
	--	P = Partial 
	--	Q = Differential partial 
	SUSER_SNAME(sid) AS DBOwner
FROM master.dbo.sysdatabases sysdatabases
LEFT OUTER JOIN msdb.dbo.backupset backupset 
	ON backupset.database_name = sysdatabases.name
WHERE sysdatabases.name <> 'tempdb'
GROUP BY sysdatabases.name, sysdatabases.cmptlevel, 
	DatabasePropertyEx(sysdatabases.name,'Status'),
	DatabasePropertyEx(sysdatabases.name,'Updateability'),
	DatabasePropertyEx(sysdatabases.name,'UserAccess'),
	DatabasePropertyEx(sysdatabases.name,'Recovery'),
	SUSER_SNAME(sid)