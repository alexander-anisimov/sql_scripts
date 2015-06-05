CREATE TABLE dbo.Numbers
  (
    n INT NOT NULL ,
    CONSTRAINT PK_Numbers PRIMARY KEY ( n )
  ) ; 
GO
DECLARE @i INT ;
SET @i = 1 ;
INSERT  INTO dbo.Numbers
        ( n )
VALUES  ( 1 ) ;
WHILE @i < 100000
  BEGIN ;
    INSERT  INTO dbo.Numbers
            ( n )
            SELECT  @i + n
            FROM    dbo.Numbers ;
    SET @i = @i * 2 ;
  END ;