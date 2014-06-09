/*
Script for creating randomizing functions:
- random date value
- random time value
- random float value
- random int value
*/

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'RandView')	
	exec('CREATE VIEW [dbo].[RandView] AS SELECT 1 as t ')
go
--
ALTER VIEW [dbo].[RandView]
AS
SELECT     RAND(CAST(NEWID() AS VARBINARY)) AS RAND
go
--
IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'RandomDate')
   exec('CREATE FUNCTION [dbo].[RandomDate] () RETURNS date AS BEGIN  RETURN ''19700101'' END')
go     
--
ALTER FUNCTION [dbo].[RandomDate] (@Begin date,@End date)
RETURNS date
AS
BEGIN
DECLARE @result DATE
Select  top 1 @result = DATEADD(day, [Rand] * CAST(datediff(day,@Begin, @End) as Int),@Begin) from  dbo.RandView

return   @result
END;
go
--
IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'RandomFloat')
   exec('CREATE FUNCTION [dbo].[RandomFloat] () RETURNS float AS BEGIN  RETURN 1.0 END')
go     
--
ALTER FUNCTION [dbo].[RandomFloat] (@Begin float,@End float)
RETURNS Float
AS
BEGIN
DECLARE @Random Float
select      @Random = @Begin   + (select [Rand] from dbo.RandView) * (@End-@Begin)
RETURN @Random
END;
go
--
IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'RandomTime')
   exec('CREATE FUNCTION [dbo].[RandomTime] () RETURNS time AS BEGIN  RETURN ''23:59:59.000'' END')  
go
--
ALTER FUNCTION [dbo].[RandomTime] (@TimeBegin time,@TimeEnd time)
RETURNS time
AS
BEGIN
declare @result time
Select  top 1 @result = DATEADD(second, [Rand] * CAST(datediff(second,@TimeBegin, @TimeEnd) as Int),@TimeBegin) from  dbo.RandView

return   @result
END;
go
--
IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'RandomInt')
   exec('CREATE FUNCTION [dbo].[RandomInt] () RETURNS INT AS BEGIN  RETURN 1 END')  
go
--
ALTER FUNCTION [dbo].[RandomInt] (@Begin INT,@End INT)
RETURNS INT
AS
BEGIN
DECLARE @Random INT
SELECT @Random = ROUND(dbo.RandomFloat(@Begin,@End),0)
RETURN @Random
END;


