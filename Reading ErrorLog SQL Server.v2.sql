IF OBJECT_ID(N'tempdb..##tbl_sql_error_log') IS NOT NULL 
    BEGIN  
        DROP TABLE ##tbl_sql_error_log 
    END 

DECLARE @site_value INT;
DECLARE @NumberOfLogfiles INT;

DECLARE @FileList AS TABLE (
subdirectory NVARCHAR(4000) NOT NULL 
,DEPTH BIGINT NOT NULL
,[FILE] BIGINT NOT NULL
);

create table ##tbl_sql_error_log (LogDate datetime,Processinfo nvarchar(max),[text] nvarchar (max))
     
DECLARE @ErrorLog NVARCHAR(4000), @ErrorLogPath NVARCHAR(4000);
SELECT @ErrorLog = CAST(SERVERPROPERTY(N'errorlogfilename') AS NVARCHAR(4000));
SELECT @ErrorLogPath = SUBSTRING(@ErrorLog, 1, LEN(@ErrorLog) - CHARINDEX(N'\', REVERSE(@ErrorLog))) + N'\';
     
INSERT INTO @FileList
EXEC xp_dirtree @ErrorLogPath, 0, 1;
     
SET @NumberOfLogfiles = (SELECT COUNT(*) FROM @FileList WHERE [@FileList].subdirectory LIKE N'ERRORLOG%');
--print @NumberOfLogfiles

SET @site_value = 0;
WHILE @site_value < @NumberOfLogfiles
BEGIN
   insert into ##tbl_sql_error_log
exec sp_readerrorlog @site_value
SET @site_value = @site_value + 1;
END;


select*from ##tbl_sql_error_log
--where text like '%corrupt%' or text like '%19-25%'
order by logdate

drop table ##tbl_sql_error_log
