IF OBJECT_ID(N'[dbo].[usp_readFromErrorLog]') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[usp_readFromErrorLog]
END
GO

Create Proc usp_readFromErrorLog (@dbmail_profile varchar(100) = NULL, @dbmail_recipient varchar(100) = NULL)
as 
Begin
Begin TRY

/*   Description: Sends Back Critical Alerts from ErrorLog occurred in the last 24 Hrs. You can even modify the data [Check @start and change the value]

	 RUN:=		EXEC usp_readFromErrorLog 
					  @dbmail_profile= 'Operators',
					  @dbmail_recipient = 'mymail@myemail.com';

*/		


SET NOCOUNT ON
CREATE TABLE #temp
   (
       
	   [ErrorLogDate] DATETIME,
       [ProcessInfo] VARCHAR(50),
       [Text] NVARCHAR(4000),
	   [CapturedDate] SMALLDATETIME NOT NULL default getdate()
   );


CREATE TABLE #temp1
   (
       
	   [ErrorLogDate] DATETIME,
	   [ProcessInfo] VARCHAR(50),
       [Text] NVARCHAR(4000),
   );

-- Extract data from errorlog older than a day
 DECLARE @start varchar(40), @end varchar(40), @MinLogDate varchar(40);

 SET @start =  (select RTRIM(convert(varchar(40), GETDATE() - 1, 121)))
 SET @end =  (select RTRIM(convert(varchar(40), GETDATE(), 121)))

 --PRint @start
 --PRint @end

 Insert into #temp1 ( ErrorLogDate , processinfo , [text] ) 
 EXEC sp_readerrorlog 0,1

 SET @MinLogDate = (select Min(Errorlogdate) from #temp1); -- 2015-05-14 02:50:43.220


 -- Include the Kind Of Alerts from SQL ErrorLog.
 Insert into #temp (ErrorLogDate, processinfo , text ) 
 EXEC xp_readerrorlog 0, 1,N'Failed', N'Login' ,@start,@end , 'desc';

  Insert into #temp (ErrorLogDate, processinfo , text ) 
 EXEC xp_readerrorlog 0, 1,N' 5', N'State:' ,@start,@end , 'desc';

  Insert into #temp (ErrorLogDate, processinfo , text ) 
 EXEC xp_readerrorlog 0, 1, NULL, N'deadlock' ,@start,@end , 'desc';

   Insert into #temp (ErrorLogDate, processinfo , text ) 
 EXEC xp_readerrorlog 0, 1,NULL, N'fail' ,@start,@end , 'desc';

 Insert into #temp (ErrorLogDate, processinfo , text ) 
 EXEC xp_readerrorlog 0, 1,NULL, N'Warning' ,@start,@end , 'desc';

  Insert into #temp (ErrorLogDate, processinfo , text ) 
 EXEC xp_readerrorlog 0, 1, N'stack', N'dump' ,@start,@end , 'desc';


  Insert into #temp (ErrorLogDate, processinfo , text ) 
 EXEC xp_readerrorlog 0, 1, N'back', N'rolled' ,@start,@end , 'desc';


 SELECT Count(*)                                AS [Failed Occurrence Count],


       Substring(Substring(text, Charindex('''', text) + 1, Len(text) - Charindex('''', text)), 0, 
       Charindex('''', Substring(text, Charindex('''', text) + 1, 
       Len(text) - Charindex( '''', text))))                    AS [Login Name],


       Dateadd(dd, 0, Datediff(dd, 0, ErrorLogDate)) AS DATE_Captured 
INTO #TEMP2 -- Enters data to Table.
FROM   #temp 
GROUP  BY Substring(Substring(text, Charindex('''', text) + 1, 
                    Len(text) - Charindex('''', 
                                          text) 
                              ), 0, Charindex('''', Substring(text, 
                                                    Charindex('''', text) 
                                                    + 1, 
          Len(text) - Charindex( 
          '''', text)))), 
          Dateadd(dd, 0, Datediff(dd, 0, ErrorLogDate)) 

select * from #temp;

select * from #TEMP2
where [Login Name] like '%\%'

select * from #TEMP2

--SELECT PATINDEX('%\%',[Login Name])
--FROM #TEMP2
--where PATINDEX('%\%',[Login Name]) <> 0

DECLARE @bodyMsg nvarchar(max)
DECLARE @subject nvarchar(max)
DECLARE @tableHTML nvarchar(max)
DECLARE @Table NVARCHAR(MAX) = N''



IF (select count(*) from #temp) > 0 

   BEGIN 
          SELECT @subject = 'SQL Errorlog Events:= ' + '  '+ Substring(@@servername, 1, 20);
                           
         -- SELECT @body = 'Reading Crtitical Events from SQL ErrorLog:= ' + Substring(@@servername, 1, 20);
   
	SET @tableHTML =
			N'<H1> <Font Color = "red"> SQL Server Errorlog Critical Events :  </font> </H1>' + 
			N'<body><H3> <Font Color = "red"> Server: ' + @@servername + '</H3></font>' +
			N'<h3> <Font Color = "red"> First Logged Date in the ErrorLog File :=   '+' <Font Color = "magenta"><bold>' + @MinLogDate +' </h3></font></bold>' +
		 
		  N'<table border="1">' +
			N'<tr> <th>Failed Occurrence Count</th>' +
			N'<th>Login Name</th>
			<th>CapturedDate</th></tr>' +
		CAST ( ( SELECT td = count(*), '',
		td = Substring(Substring(text, Charindex('''', text) + 1, Len(text) - Charindex('''', text)), 0, 
       Charindex('''', Substring(text, Charindex('''', text) + 1, 
       Len(text) - Charindex( '''', text))))      , '',

		td = Convert(varchar(20),Dateadd(dd, 0, Datediff(dd, 0, ErrorLogDate)))

		FROM   #temp 
		GROUP  BY Substring(Substring(text, Charindex('''', text) + 1, 
							Len(text) - Charindex('''', 
												  text) 
									  ), 0, Charindex('''', Substring(text, 
															Charindex('''', text) 
															+ 1, 
				  Len(text) - Charindex( 
				  '''', text)))), 
				  Dateadd(dd, 0, Datediff(dd, 0, ErrorLogDate)) 
		FOR XML PATH('tr'), ELEMENTS 
		) AS NVARCHAR(MAX) ) +
		N'</table>' 
		+ '<BR>' + '<BR>' + '<BR>' +
			N'<table border="1">' +
			N'<tr> <th>ErrorlogDate</th>
			<th>ProcessInfo</th>' +
			N'<th>Text</th>
			<th>CapturedDate</th></tr>' +
		CAST ( ( SELECT td = Convert(varchar(20), ErrorlogDate,120), '',
		td = ProcessInfo, '',
		--td = ISNULL(ObjName,'NO Data Found'), '',
		td = [Text], '',
		td = Convert(varchar(20), [CapturedDate], 120)
		FROM #temp
		ORDER By ErrorlogDate desc
		FOR XML PATH('tr'), ELEMENTS 
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;

		-- SHOW HTML Content
		--SELECT (@tableHTML1);

		-- DECLARE @subss VARCHAR(1024)
		--DECLARE @bodys VARCHAR(1024) 
		--DECLARE @filename VARCHAR(50) 
		--SET @subss = 'File from: '+ CONVERT(VARCHAR, GETDATE()) 
		--SET @bodys = 'attached file for the date '+ CONVERT(VARCHAR, GETDATE()) 
		--SET @filename = 'file.txt'

		IF (@dbmail_profile IS NOT NULL) OR (@dbmail_recipient IS NOT NULL)
         BEGIN

          -- Sending Email to Recipients. 
          EXEC msdb.dbo.Sp_send_dbmail 
            @profile_name = @dbmail_profile, 
            @recipients = @dbmail_recipient, 
            @subject = @subject, 
            @body = @tableHTML,
			@importance = 'HIGH',
            @body_format = 'HTML'
		END
END
		--@attach_query_result_as_file = 1,
			--@query_attachment_filename ='C:\SQLJObOutput\dbcccheckdbOutPut.txt'

/*
	  --Test Queued Email. ... 
       
        Query 1 : SELECT [profile_id]  
           ,[name]   
           ,[description]  
           ,[last_mod_datetime]  
           ,[last_mod_user]  
           ,'EXEC msdb.dbo.sp_send_dbmail  
        @profile_name = ''' + name + ''',  
        @recipients = ''mymail@myemail.com'',   
        @subject = ''Test'',  
        @body  = ''Message'',  
          @body_format = ''HTML'';' AS TestSQL  
          FROM [msdb].[dbo].[sysmail_profile]  
*/

-- Cleanup Table.
drop table #temp
drop table #temp1
drop table #TEMP2
SET NOCOUNT OFF
END TRY

 begin catch  
        print ERROR_MESSAGE();  -- save to log, etc.
 end catch
 END