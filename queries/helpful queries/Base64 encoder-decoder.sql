DECLARE @source varbinary(max),  
        @encoded_base64 varchar(max),  
        @decoded varbinary(max) 
SET @source = CONVERT(varbinary(max), 'welcome') 
-- Convert from varbinary to base64 string 
SET @encoded_base64 = CAST(N'' AS xml).value('xs:base64Binary(sql:variable ("@source"))', 'varchar(max)') 
-- Convert back from base64 to varbinary 
SET @decoded = CAST(N'' AS xml).value('xs:base64Binary(sql:variable ("@encoded_base64"))', 'varbinary(max)') 
SELECT
    CONVERT(varchar(max), @source) AS [Source varchar], 
    @source AS [Source varbinary], 
    @encoded_base64 AS [Encoded base64], 
    @decoded AS [Decoded varbinary], 
    CONVERT(varchar(max), @decoded) AS [Decoded varchar]