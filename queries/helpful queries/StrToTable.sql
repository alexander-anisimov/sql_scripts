ALTER FUNCTION fnStrToTable 
(	
	@pStr VARCHAR(4000),
    @pDelimeter CHAR(1)
)
RETURNS @tResult TABLE (Value BIGINT)
AS
BEGIN
    DECLARE @xml XML = CAST('<A>'+ REPLACE(@pStr,@pDelimeter,'</A><A>')+ '</A>' AS XML);  
    
    INSERT INTO @tResult (Value)
    SELECT t.value('.', 'int') AS inVal
    FROM @xml.nodes('/A') AS x(t);

    RETURN; 
END