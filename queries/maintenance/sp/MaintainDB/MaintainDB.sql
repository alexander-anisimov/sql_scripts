ALTER procedure [dbo].[MaintainDB]
(
    @pActivateDefragmentation bit = 1,
    @pActivateUpdateStatistic bit = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET QUOTED_IDENTIFIER ON;

    declare @partitioncount INT,
            @action         VARCHAR(10),
            @start_time     DATETIME,
            @end_time       DATETIME,
            @object_id      INT,
            @index_id       INT,
            @StatisticName  VARCHAR(250),
            @no_recompute   bit,
            @TableName      VARCHAR(250),
            @SchemaName     VARCHAR(250),
            @indexName      VARCHAR(250),
            @defrag         FLOAT,
            @partition_num  INT,
            @sql            NVARCHAR(MAX),
            @Flag1          bit,
            @Flag2          bit,
            @indexType      int
    ;            
        
    declare @index_defrag_statistic table 
        (
            start_time              datetime,
            end_time                datetime,
            database_id             smallint,
            object_id               int,
            schema_name             varchar(250),
            table_name              varchar(250),
            index_id                int,
            index_name              varchar(250),
            avg_frag_percent_before float,
            fragment_count_before   bigint,
            pages_count_before      bigint,
            fill_factor             tinyint,
            partition_num           int,
            avg_frag_percent_after  float,
            fragment_count_after    bigint,
            pages_count_after       bigint,
            action                  varchar(10),
            Flag1                   bit,
            Flag2                   bit,
            indexType               int
        )
    ;
begin try
    if @pActivateDefragmentation = 1 begin;
        INSERT INTO @index_defrag_statistic 
            (
                database_id, 
                object_id, 
                schema_name,
                table_name, 
                index_id, 
                index_name, 
                avg_frag_percent_before, 
                fragment_count_before, 
                pages_count_before, 
                fill_factor, 
                partition_num,
                Flag1,
                Flag2,
                indexType
            )
        SELECT  
                dm.database_id, 
                dm.object_id, 
                s.name,
                tbl.name, 
                dm.index_id, 
                idx.name, 
                dm.avg_fragmentation_in_percent, 
                dm.fragment_count, 
                dm.page_count, 
                idx.fill_factor, 
                dm.partition_number,
                case when c.object_id is null then 0 else 1 end as Flag1,
                case when c2.object_id is null then 0 else 1 end as Flag2,
                idx.Type
        FROM    sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) dm 
        JOIN    sys.tables tbl WITH(NOLOCK) ON dm.object_id = tbl.object_id
        JOIN    sys.schemas s WITH(NOLOCK) ON tbl.schema_id = s.schema_id
        JOIN    sys.indexes idx WITH(NOLOCK) ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
        left join (
                    select distinct object_id
                    from (
                            SELECT c.object_id, c.system_type_id, c.max_length
                            FROM   sys.columns AS c 
                            where ((c.system_type_id IN (34,35,99,241)) -- image, text, ntext, xml
                                    OR (c.system_type_id IN (167,231,165) AND c.max_length = -1))  -- varchar, nvarchar, varbinary
                        ) c
                   ) c on idx.object_id = c.object_id
        left join (
                    select distinct object_id
                    from (
                    
                            SELECT ic.object_id, ic.index_id, c.system_type_id, max_length
                            FROM sys.index_columns AS ic
                            JOIN sys.columns AS c
                                ON ic.object_id = c.object_id
                                AND ic.column_id = c.column_id
                            where ((c.system_type_id IN (34,35,99,241)) -- image, text, ntext, xml
                                    OR (c.system_type_id IN (167,231,165) AND c.max_length = -1))  -- varchar, nvarchar, varbinary
                        ) c
                   ) c2 on idx.object_id = c2.object_id                   
        WHERE   
                page_count > 256
            AND avg_fragmentation_in_percent > 5
            AND dm.index_id > 0
            --and idx.name = 'PK_USERSLog'
            --and  tbl.Name = 'UsersLog'
        ORDER BY dm.page_count      
        ;
        
        declare defragCur cursor local fast_forward for
        SELECT 
            object_id, 
            index_id, 
            schema_name,
            table_name, 
            index_name, 
            avg_frag_percent_before, 
            partition_num,
            Flag1, 
            Flag2,
            indexType
        FROM @index_defrag_statistic
        ORDER BY object_id, index_id DESC
        ;

        OPEN defragCur
        FETCH NEXT FROM defragCur INTO @object_id, @index_id, @schemaname, @tableName, @indexName, @defrag, @partition_num, @Flag1, @Flag2, @IndexType
        WHILE @@FETCH_STATUS=0
        BEGIN
            select @sql = N'ALTER INDEX [' + @indexName + '] ON [' + rtrim(@SchemaName) + '].[' + rtrim(@TableName) + ']';

            SELECT @partitioncount = count (*)
            FROM sys.partitions
            WHERE object_id = @object_id AND index_id = @index_id;
            
            BEGIN 
                IF (@defrag > 30)
                BEGIN
                    IF @partitioncount > 1 or (@Flag1 = 1 and @IndexType = 1) or @Flag2 = 1
                        select @sql = @sql + N' REBUILD',
                               @action = 'rebuild';
                    ELSE 
                        select @sql = @sql + N' REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, MAXDOP = 1)',
                               @action = 'rebuild_o';
                END
                ELSE 
                BEGIN
                    select @sql = @sql + N' REORGANIZE',
                           @action = 'reorginize';
                END
            END
            
            IF @partitioncount > 1
                select @sql = @sql + N' PARTITION=' + CAST(@partition_num AS nvarchar(5))
            insert into dbo._MaintenanceLog (ActionText, DateTime, ErrorMessage)
            select @sql, SYSDATETIME(), ERROR_MESSAGE();
            --raiserror (@sql,0,1) with nowait;
            select @start_time = GETDATE();
            
            EXEC sp_executesql @sql;
            
            select @end_time = GETDATE();
            
            UPDATE @index_defrag_statistic
            SET 
                start_time = @start_time,
                end_time = @end_time,
                action = @action
            WHERE object_id = @object_id
                AND index_id = @index_id
            ;
            FETCH NEXT FROM defragCur INTO @object_id, @index_id, @schemaname, @tableName, @indexName, @defrag, @partition_num, @Flag1, @Flag2, @IndexType
        END;
        CLOSE defragCur;
        DEALLOCATE defragCur;

        UPDATE dba
        SET
            dba.avg_frag_percent_after = dm.avg_fragmentation_in_percent,
            dba.fragment_count_after = dm.fragment_count,
            dba.pages_count_after = dm.page_count
        FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) dm
        JOIN @index_defrag_statistic dba 
          ON dm.object_id = dba.object_id
         AND dm.index_id = dba.index_id
        WHERE dm.index_id > 0
        ;

        select * from @index_defrag_statistic;    
    end;
    
    
    if @pActivateUpdateStatistic = 1 begin;
        declare statisticsCur cursor local fast_forward for
        SELECT SCHEMA_NAME(o.[schema_id]),o.name,s.name,s.no_recompute
        FROM (
            SELECT 
                  [object_id]
                , name
                , stats_id
                , no_recompute
                , last_update = STATS_DATE([object_id], stats_id)
            FROM sys.stats WITH(NOLOCK)
            WHERE auto_created = 0
        ) s
        JOIN sys.objects o WITH(NOLOCK) ON s.[object_id] = o.[object_id]
        JOIN (
            SELECT
                  p.[object_id]
                , p.index_id
                , total_pages = SUM(a.total_pages)
            FROM sys.partitions p WITH(NOLOCK)
            JOIN sys.allocation_units a WITH(NOLOCK) ON p.[partition_id] = a.container_id
            GROUP BY 
                  p.[object_id]
                , p.index_id
        ) p ON o.[object_id] = p.[object_id] AND p.index_id = s.stats_id
        WHERE o.[type] IN ('U', 'V')
            AND o.is_ms_shipped = 0
            AND last_update <= DATEADD(dd, 
                    CASE 
                        WHEN p.total_pages > 4096 THEN -7 -- if > 4 MB and updated more than week ago
                        ELSE 0 
                    END, CAST(current_timestamp as date))
        ;
                
        open statisticsCur
        fetch from statisticsCur into @SchemaName, @TableName, @StatisticName, @no_recompute
        while @@fetch_status = 0 begin
            set @sql = N'UPDATE STATISTICS [' + @SchemaName + '].[' + @TableName + '] [' + @StatisticName + '] WITH FULLSCAN' + CASE WHEN @no_recompute = 1 THEN ', NORECOMPUTE' ELSE '' END + ';'
            --raiserror (@sql,0,1) with nowait;
            insert into dbo._MaintenanceLog (ActionText, DateTime, ErrorMessage)
            select @sql, SYSDATETIME(), ERROR_MESSAGE();
            EXEC sp_executesql @sql;
            fetch from statisticsCur into @SchemaName, @TableName, @StatisticName, @no_recompute
        end;
        close statisticsCur;
        deallocate statisticsCur;
            
        SELECT  SCHEMA_NAME(o.[schema_id]) + '.' + o.name as TableName,
                s.name as StatName,
                s.last_update
        FROM (
            SELECT 
                  [object_id]
                , name
                , stats_id
                , no_recompute
                , last_update = STATS_DATE([object_id], stats_id)
            FROM sys.stats WITH(NOLOCK)
            WHERE auto_created = 0
        ) s
        JOIN sys.objects o WITH(NOLOCK) ON s.[object_id] = o.[object_id]
        JOIN (
            SELECT
                  p.[object_id]
                , p.index_id
                , total_pages = SUM(a.total_pages)
            FROM sys.partitions p WITH(NOLOCK)
            JOIN sys.allocation_units a WITH(NOLOCK) ON p.[partition_id] = a.container_id
            GROUP BY 
                  p.[object_id]
                , p.index_id
        ) p ON o.[object_id] = p.[object_id] AND p.index_id = s.stats_id
        WHERE o.[type] IN ('U', 'V')
            AND o.is_ms_shipped = 0
            AND cast(last_update as date) = CAST(current_timestamp as date)
        ; 
    end;               
end try
begin catch
    insert into dbo._MaintenanceLog (ActionText, DateTime, ErrorMessage)
    select @sql, SYSDATETIME(), ERROR_MESSAGE();
end catch        
END


/*
begin tran

exec dbo.MaintainDB

rollback tran
*/


