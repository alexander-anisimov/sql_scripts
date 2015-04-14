SET NOCOUNT ON;
DECLARE @TableName VARCHAR(100),
        @ColumnName VARCHAR(100),
        @CurrentLength VARCHAR(5),
        @sql VARCHAR(MAX);
        
DECLARE @t TABLE 
    (  
        TableName VARCHAR(100),
        ColumnName VARCHAR(100),
        CurrentLength VARCHAR(5),
        MaxLength INT 
    );
                    
DECLARE c1 CURSOR FOR 
    SELECT t.name AS TableName, c.name AS ColumnName, case c.max_length WHEN -1 THEN 'MAX' ELSE CAST(c.max_length as VARCHAR ) END AS CurrentLength
    FROM sys.[columns] AS c 
    JOIN sys.tables t ON t.[object_id] = c.[object_id]
    WHERE c.max_length = -1 OR c.max_length BETWEEN 2000 AND 10000 
    ORDER BY 1,2	

    OPEN c1
    FETCH NEXT FROM c1 INTO @TableName, @ColumnName, @CurrentLength

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SELECT @sql = 'SELECT ''' + @TableName + ''', ''' + @ColumnName + ''', ''' + @CurrentLength + ''', MAX(LEN(ISNULL(' + @ColumnName + ',0))) FROM [' + @TableName +  ']';
        RAISERROR(@sql,10,0) WITH NOWAIT;
        
        INSERT INTO @t (TableName,ColumnName, CurrentLength, MaxLength)
        EXEC (@sql);
        
        FETCH NEXT FROM c1 INTO @TableName, @ColumnName, @CurrentLength
    END

    CLOSE c1
    DEALLOCATE c1

SELECT * FROM @t
    