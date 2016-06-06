USE [master]
GO
/****** 
Objective	: Compare the structure/layout of two tables within an instance of SQL Server (version 2012) and return non-matches.
Date		: 23/04/2014
Author		: Trevor Makoni
******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[proc_Compare_Table_Structure]
(
	@DATABASE1	VARCHAR(500),
	@TABLE1		VARCHAR(500),
	@DATABASE2	VARCHAR(500),
	@TABLE2		VARCHAR(500)
)
AS
BEGIN;
IF LTRIM(RTRIM(ISNULL(@DATABASE1,'')))=''
BEGIN;
	PRINT 'PLEASE PROVIDE DATABASE1 NAME!!!'
	RETURN;
END;
IF LTRIM(RTRIM(ISNULL(@TABLE1,'')))=''
BEGIN;
	PRINT 'PLEASE PROVIDE TABLE1 NAME!!!'
	RETURN;
END;
IF LTRIM(RTRIM(ISNULL(@DATABASE2,'')))=''
BEGIN;
	PRINT 'PLEASE PROVIDE DATABASE2 NAME!!!'
	RETURN;
END;
IF LTRIM(RTRIM(ISNULL(@TABLE2,'')))=''
BEGIN;
	PRINT 'PLEASE PROVIDE TABLE2 NAME!!!'
	RETURN;
END;

SET @DATABASE1 = REPLACE(REPLACE(@DATABASE1, '[',''), ']','');	
SET @TABLE1 = REPLACE(REPLACE(@TABLE1, '[',''), ']','');
SET @DATABASE2 = REPLACE(REPLACE(@DATABASE2, '[',''), ']','');
SET @TABLE2 = REPLACE(REPLACE(@TABLE2, '[',''), ']','');

DECLARE @SQL	VARCHAR(MAX);

SET @SQL = '
DECLARE @MSG VARCHAR(MAX);
SELECT @MSG = '''+@DATABASE1+'.'+@TABLE1+''' + '' : '' + CAST(COUNT(1) AS VARCHAR(50)) + '' Columns''
FROM ['+@DATABASE1+'].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '''+@TABLE1+''';
PRINT @MSG';
EXEC (@SQL);

SET @SQL = '
DECLARE @MSG VARCHAR(MAX);
SELECT @MSG = '''+@DATABASE2+'.'+@TABLE2+''' + '' : '' + CAST(COUNT(1) AS VARCHAR(50)) + '' Columns''
FROM ['+@DATABASE2+'].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '''+@TABLE2+''';
PRINT @MSG';
EXEC (@SQL);

SET @SQL = '
WITH A AS (
SELECT COLUMN_NAME, DATA_TYPE + case when CHARACTER_MAXIMUM_LENGTH is null then '''' else '' (''+CAST(CHARACTER_MAXIMUM_LENGTH as varchar(10))+'')'' end as DATA_TYPE
FROM ['+@DATABASE1+'].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '''+@TABLE1+''')
,B AS (
SELECT COLUMN_NAME, DATA_TYPE + case when CHARACTER_MAXIMUM_LENGTH is null then '''' else '' (''+CAST(CHARACTER_MAXIMUM_LENGTH as varchar(10))+'')'' end as DATA_TYPE
FROM ['+@DATABASE2+'].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '''+@TABLE2+''')
,C AS (
SELECT ''IN A NOT IN B'' [CASE], COLUMN_NAME, DATA_TYPE FROM (SELECT  COLUMN_NAME, DATA_TYPE FROM A
EXCEPT
SELECT COLUMN_NAME, DATA_TYPE FROM B) Q)
,D AS (
SELECT ''IN B NOT IN A'' [CASE], COLUMN_NAME, DATA_TYPE FROM (SELECT  COLUMN_NAME, DATA_TYPE FROM B
EXCEPT
SELECT COLUMN_NAME, DATA_TYPE FROM A) Q)
SELECT * FROM C
UNION ALL
SELECT * FROM D;';
EXEC (@SQL);
END;
GO