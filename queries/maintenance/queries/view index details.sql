SELECT * FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID(N'dbo.Accounts'), NULL, NULL , 'DETAILED');
exec sp_spaceused 'accounts'