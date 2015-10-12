USE agile_pm_20150602_develop;
GO
-- Truncate the log by changing the database recovery model to SIMPLE.
ALTER DATABASE agile_pm_20150602_develop
SET RECOVERY SIMPLE;
GO
-- Shrink the truncated log file to 1 MB.
DBCC SHRINKFILE (agile_pm_log, 1);
GO
-- Reset the database recovery model.
ALTER DATABASE agile_pm_20150602_develop
SET RECOVERY FULL;