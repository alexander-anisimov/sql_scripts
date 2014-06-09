sp_configure 'show advanced options', 1;
go
RECONFIGURE
go
EXEC sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
go

/*
курс валют центробанка на сегодня
*/
declare @xmlString nvarchar(4000), @url varchar(255), @retVal INT, @oXML INT, @loadRetVal INT, @h int
declare @d1 datetime
set @d1 = GetDate()

select @url =  
'http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1='+ Convert(char(10), @d1, 103)+'&date_req2='+ Convert(char(10), @d1, 103)+'&VAL_NM_RQ=R01235'
	EXEC @retVal = sp_OACreate 'MSXML2.DOMDocument', @oXML OUTPUT
	print 'sp_OACreate @retVal =' + cast(@retVal as varchar)
	EXEC @retVal = sp_OASetProperty @oXML, 'async', 0
	print 'sp_OASetProperty @retVal =' + cast(@retVal as varchar)
	EXEC @retVal = sp_OAMethod @oXML, 'load', @loadRetVal OUTPUT, @url
	print 'sp_OAMethod load @retVal =' + cast(@retVal as varchar)
	EXEC @retVal = sp_OAMethod @oXML, 'xml', @xmlString OUTPUT
	print 'sp_OAMethod xml @retVal =' + cast(@retVal as varchar)
	EXEC sp_OADestroy @oXML
print '@xmlString = ' + @xmlString
	exec sp_xml_preparedocument  @h output, @xmlString
select cast(floor(cast(@d1 as float)) as smalldatetime) as Data, Nominal, Convert(money, replace(Value, ',', '.')) 'Value'
from OpenXML (@h, '//ValCurs/Record', 0)
with ( Name varchar(99) './Name', Nominal int './Nominal', Value varchar(10) './Value' )
print @h

	exec sp_xml_removedocument @h





/*
load html file
*/

declare @hr int	
declare @object int
declare @src int
declare @desc varchar(255)

declare @url varchar(1000) 

--
exec @hr=sp_OACreate 'MSXML2.XMLHTTP', @object OUT
if @hr<>0
begin
	exec sp_OAGetErrorInfo @object, @src OUT, @desc OUT
	print @src
	print @desc
end
--
--set @url='http://www.google.ru/search?q="sql.ru"'
set @url='http://finance.tut.by/arhiv/?currency=USD&from=2014-01-01&to=2014-02-18'
exec @hr=sp_OAMethod @object, 'Open', NULL, 'GET', @url , 0
if @hr<>0
begin
	exec sp_OAGetErrorInfo @object, @src OUT, @desc OUT
	print 'Open'
	print @src
	print @desc
end
--
exec @hr=sp_OAMethod @object, 'send', NULL
if @hr<>0
begin
	exec sp_OAGetErrorInfo @object, @src OUT, @desc OUT
	print 'send'
	print @src
	print @desc
end
--
DECLARE	@Response TABLE ( Response NVarChar(max) )

SET TEXTSIZE 2147483647;

INSERT	@Response
exec @hr=sp_OAGetProperty @object, 'responseText' 

if @hr<>0
begin
	exec sp_OAGetErrorInfo @object, @src OUT, @desc OUT
	print 'responseText'
	print @src
	print @desc
end

select Response from @Response

--
exec @hr=sp_OADestroy @object