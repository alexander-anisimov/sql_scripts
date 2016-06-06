CREATE FUNCTION dbo.[fn_split_string_using_multiple_delimiters]
(
      @String    VARCHAR(MAX),  -- input string
      @delimiter VARCHAR(32)    -- delimiter list 
)
RETURNS @Table TABLE(rowid INT IDENTITY PRIMARY KEY,        
stringlist VARCHAR(MAX)
)
BEGIN
 
        DECLARE @Xml AS XML
        DECLARE @derived_string VARCHAR(MAX)
 
        ;WITH N1 (n) AS (SELECT 1 UNION ALL SELECT 1),
        N2 (n) AS (SELECT 1 FROM N1 AS X, N1 AS Y),
        N3 (n) AS (SELECT 1 FROM N2 AS X, N2 AS Y),
        N4 (n) AS (SELECT ROW_NUMBER() OVER(ORDER BY X.n)
        FROM N3 AS X, N3 AS Y)
 
        SELECT @derived_string=STUFF((SELECT '' + (Case When
                PATINDEX('%[' + @delimiter + ']%',SUBSTRING(@String,Nums.n,1)) >0
                Then ',' else LTRIM(RTRIM(SUBSTRING(@String,Nums.n,1))) end)
        FROM N4 Nums WHERE Nums.n<=LEN(@String)  FOR XML PATH('')),1,0,'')
 
        SET @Xml = cast(('<a>'+replace(@derived_string,
                ',','</a><a>')+'</a>') AS XML)
 
        INSERT INTO @Table SELECT A.value('.', 'VARCHAR(MAX)')
                as [Column] FROM @Xml.nodes('a') AS FN(a)
 
RETURN
END
GO

SELECT * FROM dbo.[fn_split_string_using_multiple_delimiters]
('india,uk ; usa ; spain:italy',',;:')
GO