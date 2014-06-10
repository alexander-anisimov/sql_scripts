SET NOCOUNT ON;
IF OBJECT_ID('tempdb.dbo.#objects') IS NOT NULL
    DROP TABLE #objects

CREATE TABLE #objects (
      obj_id INT PRIMARY KEY
    , obj_name NVARCHAR(261)
    , err_message NVARCHAR(2048) NOT NULL
    , obj_type CHAR(2) NOT NULL
)

INSERT INTO #objects (obj_id, obj_name, err_message, obj_type)
SELECT 
      t.referencing_id
    , obj_name = QUOTENAME(SCHEMA_NAME(o.[schema_id])) + '.' + QUOTENAME(o.name)
    , 'Invalid object name ''' + t.obj_name + ''''
    , o.[type]
FROM (
    SELECT
          d.referencing_id
        , obj_name = MAX(COALESCE(d.referenced_database_name + '.', '') 
                + COALESCE(d.referenced_schema_name + '.', '') 
                + d.referenced_entity_name)
    FROM sys.sql_expression_dependencies d
    WHERE d.is_ambiguous = 0
        AND d.referenced_id IS NULL -- если не можем определить от какого объекта зависимость
        AND d.referenced_server_name IS NULL -- игнорируем объекты с Linked server
        AND CASE d.referenced_class -- если не существует
            WHEN 1 -- объекта
                THEN OBJECT_ID(
                    ISNULL(QUOTENAME(d.referenced_database_name), DB_NAME()) + '.' + 
                    ISNULL(QUOTENAME(d.referenced_schema_name), SCHEMA_NAME()) + '.' + 
                    QUOTENAME(d.referenced_entity_name))
            WHEN 6 -- или типа данных
                THEN TYPE_ID(
                    ISNULL(d.referenced_schema_name, SCHEMA_NAME()) + '.' + d.referenced_entity_name) 
            WHEN 10 -- или XML схемы
                THEN (
                    SELECT 1 FROM sys.xml_schema_collections x 
                    WHERE x.name = d.referenced_entity_name
                        AND x.[schema_id] = ISNULL(SCHEMA_ID(d.referenced_schema_name), SCHEMA_ID())
                    )
            END IS NULL
    GROUP BY d.referencing_id
) t
JOIN sys.objects o ON t.referencing_id = o.[object_id]
WHERE LEN(t.obj_name) > 4 -- чтобы не показывать валидные алиасы, как невалидные объекты

DECLARE
      @obj_id INT
    , @obj_name NVARCHAR(261)
    , @obj_type CHAR(2)

DECLARE cur CURSOR FAST_FORWARD READ_ONLY LOCAL FOR
    SELECT
          sm.[object_id]
        , QUOTENAME(SCHEMA_NAME(o.[schema_id])) + '.' + QUOTENAME(o.name)
        , o.[type]
    FROM sys.sql_modules sm
    JOIN sys.objects o ON sm.[object_id] = o.[object_id]
    LEFT JOIN (
        SELECT s.referenced_id
        FROM sys.sql_expression_dependencies s
        JOIN sys.objects o ON o.object_id = s.referencing_id
        WHERE s.is_ambiguous = 0
            AND s.referenced_server_name IS NULL
            AND o.[type] IN ('C', 'D', 'U')
        GROUP BY s.referenced_id
    ) sed ON sed.referenced_id = sm.[object_id]
    WHERE sm.is_schema_bound = 0 -- объект создан без опции WITH SCHEMABINDING
        AND sm.[object_id] NOT IN (SELECT o2.obj_id FROM #objects o2) -- чтобы повторно не определ€ть невалидные объекты
        AND OBJECTPROPERTY(sm.[object_id], 'IsEncrypted') = 0
        AND (
              o.[type] IN ('IF', 'TF', 'V', 'TR')
            -- в редких случа€х, sp_refreshsqlmodule может портить метаданные хранимых процедур (Bug #656863)
            --OR o.[type] = 'P' 
            OR (
                   o.[type] = 'FN'
                AND
                   -- игнорируем скал€рные функции, которые используютс€ в DEFAULT/CHECK констрейнтах и в COMPUTED столбцах
                   sed.referenced_id IS NULL
            )
       )

OPEN cur

FETCH NEXT FROM cur INTO @obj_id, @obj_name, @obj_type

WHILE @@FETCH_STATUS = 0 BEGIN

    BEGIN TRY

        BEGIN TRANSACTION
            EXEC sys.sp_refreshsqlmodule @name = @obj_name, @namespace = N'OBJECT' 
        COMMIT TRANSACTION

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION

        INSERT INTO #objects (obj_id, obj_name, err_message, obj_type) 
        SELECT @obj_id, @obj_name, ERROR_MESSAGE(), @obj_type

    END CATCH

    FETCH NEXT FROM cur INTO @obj_id, @obj_name, @obj_type

END

CLOSE cur
DEALLOCATE cur

SELECT obj_name, err_message, obj_type
FROM #objects