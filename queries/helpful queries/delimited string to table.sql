-- first variant
CREATE FUNCTION [dbo].[fnSplit] 
(
    @InputString    VARCHAR(8000),
    @Delimiter      CHAR(1)
)

RETURNS @Items TABLE (Item VARCHAR(8000))

AS
BEGIN
    DECLARE @XML AS XML

    SET @XML = CAST(('<X>'+REPLACE(@InputString,@Delimiter ,'</X><X>')+'</X>') AS XML)

    INSERT INTO @Items
    SELECT N.value('.', 'VARCHAR(100)') AS ID FROM @XML.nodes('X') AS T(N)

    RETURN

END

-- second variant
CREATE FUNCTION [dbo].[fnSplit] 
(
    @InputString    VARCHAR(8000),
    @Delimiter      VARCHAR(50)
)

RETURNS @Items TABLE (Item VARCHAR(8000))

AS
BEGIN
    IF @Delimiter = ' '
    BEGIN
          SET @Delimiter = ','
          SET @InputString = REPLACE(@InputString, ' ', @Delimiter)
    END

    IF (@Delimiter IS NULL OR @Delimiter = '')
        SET @Delimiter = ','

    DECLARE @Item           VARCHAR(8000)
    DECLARE @ItemList       VARCHAR(8000)
    DECLARE @DelimIndex     INT

    SET @ItemList = @InputString
    SET @DelimIndex = CHARINDEX(@Delimiter, @ItemList, 0)
    WHILE (@DelimIndex != 0)
    BEGIN
          SET @Item = SUBSTRING(@ItemList, 0, @DelimIndex)
          INSERT INTO @Items VALUES (@Item)

          SET @ItemList = SUBSTRING(@ItemList, @DelimIndex+1, LEN(@ItemList)-@DelimIndex)
          SET @DelimIndex = CHARINDEX(@Delimiter, @ItemList, 0)
    END

    IF @Item IS NOT NULL
    BEGIN
          SET @Item = @ItemList
          INSERT INTO @Items VALUES (@Item)
    END

    ELSE INSERT INTO @Items VALUES (@InputString)

    RETURN

END