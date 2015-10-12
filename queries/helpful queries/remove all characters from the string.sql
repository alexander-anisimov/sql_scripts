SET NOCOUNT ON
DECLARE @loop INT
DECLARE @str VARCHAR(8000)
SELECT @str = 'ab123ce234fe'
SET @loop = 0
WHILE @loop < 26
BEGIN
SET @str = REPLACE(@str, CHAR(65 + @loop), '')
SET @loop = @loop + 1
END
SELECT @str