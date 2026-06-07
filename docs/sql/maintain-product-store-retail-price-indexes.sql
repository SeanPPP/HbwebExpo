/*
Product / StoreRetailPrice 每周索引维护脚本

用途：
1. 创建 dbo.IndexMaintenanceLog，用于记录每次索引维护结果。
2. 创建 dbo.usp_MaintainProductStoreRetailPriceIndexes。
3. 只维护 dbo.Product 和 dbo.StoreRetailPrice，不删除索引、不创建业务索引。

执行示例：
-- 只查看候选索引，不执行维护。
EXEC dbo.usp_MaintainProductStoreRetailPriceIndexes @DryRun = 1;

-- 正式执行维护。
EXEC dbo.usp_MaintainProductStoreRetailPriceIndexes;
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.IndexMaintenanceLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.IndexMaintenanceLog
    (
        Id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_IndexMaintenanceLog PRIMARY KEY,
        RunId UNIQUEIDENTIFIER NOT NULL,
        SchemaName SYSNAME NOT NULL,
        TableName SYSNAME NOT NULL,
        IndexName SYSNAME NOT NULL,
        PageCount BIGINT NOT NULL,
        FragmentationPercent DECIMAL(10,2) NOT NULL,
        ActionName NVARCHAR(32) NOT NULL,
        StatusName NVARCHAR(32) NOT NULL,
        CommandText NVARCHAR(MAX) NULL,
        StartedAt DATETIME2(0) NOT NULL,
        EndedAt DATETIME2(0) NULL,
        ErrorNumber INT NULL,
        ErrorMessage NVARCHAR(4000) NULL
    );

    CREATE INDEX IX_IndexMaintenanceLog_RunId
        ON dbo.IndexMaintenanceLog (RunId, StartedAt);

    CREATE INDEX IX_IndexMaintenanceLog_TableIndex
        ON dbo.IndexMaintenanceLog (TableName, IndexName, StartedAt);
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_MaintainProductStoreRetailPriceIndexes
    @DryRun BIT = 0,
    @MinPageCount INT = 1000,
    @ReorganizeThreshold DECIMAL(10,2) = 5.00,
    @RebuildThreshold DECIMAL(10,2) = 30.00,
    @MaxDop INT = 2,
    @LowPriorityMaxDurationMinutes INT = 5,
    @UseOnlineRebuild BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    DECLARE @RunId UNIQUEIDENTIFIER = NEWID();

    IF OBJECT_ID(N'dbo.Product', N'U') IS NULL
        THROW 51000, N'缺少 dbo.Product 表，索引维护已停止。', 1;

    IF OBJECT_ID(N'dbo.StoreRetailPrice', N'U') IS NULL
        THROW 51001, N'缺少 dbo.StoreRetailPrice 表，索引维护已停止。', 1;

    IF @MinPageCount < 1
        THROW 51002, N'@MinPageCount 必须大于 0。', 1;

    IF @ReorganizeThreshold < 0 OR @RebuildThreshold <= @ReorganizeThreshold
        THROW 51003, N'碎片率阈值无效，要求 0 <= reorganize < rebuild。', 1;

    IF @MaxDop < 1
        THROW 51004, N'@MaxDop 必须大于 0。', 1;

    CREATE TABLE #IndexCandidates
    (
        SchemaName SYSNAME NOT NULL,
        TableName SYSNAME NOT NULL,
        IndexName SYSNAME NOT NULL,
        ObjectId INT NOT NULL,
        IndexId INT NOT NULL,
        PageCount BIGINT NOT NULL,
        FragmentationPercent DECIMAL(10,2) NOT NULL,
        ActionName NVARCHAR(32) NOT NULL,
        CommandText NVARCHAR(MAX) NULL
    );

    INSERT INTO #IndexCandidates
    (
        SchemaName,
        TableName,
        IndexName,
        ObjectId,
        IndexId,
        PageCount,
        FragmentationPercent,
        ActionName
    )
    SELECT
        s.name AS SchemaName,
        t.name AS TableName,
        i.name AS IndexName,
        i.object_id AS ObjectId,
        i.index_id AS IndexId,
        ps.page_count AS PageCount,
        CONVERT(DECIMAL(10,2), ps.avg_fragmentation_in_percent) AS FragmentationPercent,
        CASE
            WHEN ps.avg_fragmentation_in_percent >= @RebuildThreshold THEN N'REBUILD'
            ELSE N'REORGANIZE'
        END AS ActionName
    FROM sys.dm_db_index_physical_stats
    (
        DB_ID(),
        NULL,
        NULL,
        NULL,
        N'LIMITED'
    ) AS ps
    INNER JOIN sys.indexes AS i
        ON ps.object_id = i.object_id
       AND ps.index_id = i.index_id
    INNER JOIN sys.tables AS t
        ON i.object_id = t.object_id
    INNER JOIN sys.schemas AS s
        ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo'
      AND t.name IN (N'Product', N'StoreRetailPrice')
      AND i.index_id > 0
      AND i.type IN (1, 2)
      AND i.name IS NOT NULL
      AND i.is_disabled = 0
      AND i.is_hypothetical = 0
      AND ps.page_count >= @MinPageCount
      AND ps.avg_fragmentation_in_percent >= @ReorganizeThreshold;

    UPDATE c
    SET CommandText =
        CASE c.ActionName
            WHEN N'REBUILD' THEN
                N'ALTER INDEX ' + QUOTENAME(c.IndexName) +
                N' ON ' + QUOTENAME(c.SchemaName) + N'.' + QUOTENAME(c.TableName) +
                N' REBUILD WITH (' +
                CASE
                    WHEN @UseOnlineRebuild = 1 THEN
                        N'ONLINE = ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION = ' +
                        CONVERT(NVARCHAR(12), @LowPriorityMaxDurationMinutes) +
                        N' MINUTES, ABORT_AFTER_WAIT = SELF)), '
                    ELSE N''
                END +
                N'MAXDOP = ' + CONVERT(NVARCHAR(12), @MaxDop) +
                N', SORT_IN_TEMPDB = ON);'
            ELSE
                N'ALTER INDEX ' + QUOTENAME(c.IndexName) +
                N' ON ' + QUOTENAME(c.SchemaName) + N'.' + QUOTENAME(c.TableName) +
                N' REORGANIZE;'
        END
    FROM #IndexCandidates AS c;

    IF @DryRun = 1
    BEGIN
        SELECT
            @RunId AS RunId,
            SchemaName,
            TableName,
            IndexName,
            PageCount,
            FragmentationPercent,
            ActionName,
            CommandText
        FROM #IndexCandidates
        ORDER BY
            CASE ActionName WHEN N'REBUILD' THEN 0 ELSE 1 END,
            PageCount DESC,
            FragmentationPercent DESC;

        RETURN;
    END

    DECLARE
        @SchemaName SYSNAME,
        @TableName SYSNAME,
        @IndexName SYSNAME,
        @PageCount BIGINT,
        @FragmentationPercent DECIMAL(10,2),
        @ActionName NVARCHAR(32),
        @CommandText NVARCHAR(MAX),
        @FallbackCommandText NVARCHAR(MAX),
        @LogId BIGINT;

    DECLARE index_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            SchemaName,
            TableName,
            IndexName,
            PageCount,
            FragmentationPercent,
            ActionName,
            CommandText
        FROM #IndexCandidates
        ORDER BY
            CASE ActionName WHEN N'REBUILD' THEN 0 ELSE 1 END,
            PageCount DESC,
            FragmentationPercent DESC;

    OPEN index_cursor;

    FETCH NEXT FROM index_cursor INTO
        @SchemaName,
        @TableName,
        @IndexName,
        @PageCount,
        @FragmentationPercent,
        @ActionName,
        @CommandText;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @LogId = NULL;

        INSERT INTO dbo.IndexMaintenanceLog
        (
            RunId,
            SchemaName,
            TableName,
            IndexName,
            PageCount,
            FragmentationPercent,
            ActionName,
            StatusName,
            CommandText,
            StartedAt
        )
        VALUES
        (
            @RunId,
            @SchemaName,
            @TableName,
            @IndexName,
            @PageCount,
            @FragmentationPercent,
            @ActionName,
            N'RUNNING',
            @CommandText,
            SYSDATETIME()
        );

        SET @LogId = SCOPE_IDENTITY();

        BEGIN TRY
            EXEC sys.sp_executesql @CommandText;

            UPDATE dbo.IndexMaintenanceLog
            SET
                StatusName = N'SUCCEEDED',
                EndedAt = SYSDATETIME()
            WHERE Id = @LogId;
        END TRY
        BEGIN CATCH
            UPDATE dbo.IndexMaintenanceLog
            SET
                StatusName = N'FAILED',
                EndedAt = SYSDATETIME(),
                ErrorNumber = ERROR_NUMBER(),
                ErrorMessage = ERROR_MESSAGE()
            WHERE Id = @LogId;

            -- ONLINE REBUILD 对个别索引失败时，只降级为 REORGANIZE，不自动执行离线 REBUILD。
            IF @ActionName = N'REBUILD'
            BEGIN
                SET @FallbackCommandText =
                    N'ALTER INDEX ' + QUOTENAME(@IndexName) +
                    N' ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) +
                    N' REORGANIZE;';

                INSERT INTO dbo.IndexMaintenanceLog
                (
                    RunId,
                    SchemaName,
                    TableName,
                    IndexName,
                    PageCount,
                    FragmentationPercent,
                    ActionName,
                    StatusName,
                    CommandText,
                    StartedAt
                )
                VALUES
                (
                    @RunId,
                    @SchemaName,
                    @TableName,
                    @IndexName,
                    @PageCount,
                    @FragmentationPercent,
                    N'REORGANIZE_FALLBACK',
                    N'RUNNING',
                    @FallbackCommandText,
                    SYSDATETIME()
                );

                SET @LogId = SCOPE_IDENTITY();

                BEGIN TRY
                    EXEC sys.sp_executesql @FallbackCommandText;

                    UPDATE dbo.IndexMaintenanceLog
                    SET
                        StatusName = N'SUCCEEDED',
                        EndedAt = SYSDATETIME()
                    WHERE Id = @LogId;
                END TRY
                BEGIN CATCH
                    UPDATE dbo.IndexMaintenanceLog
                    SET
                        StatusName = N'FAILED',
                        EndedAt = SYSDATETIME(),
                        ErrorNumber = ERROR_NUMBER(),
                        ErrorMessage = ERROR_MESSAGE()
                    WHERE Id = @LogId;
                END CATCH
            END
        END CATCH

        FETCH NEXT FROM index_cursor INTO
            @SchemaName,
            @TableName,
            @IndexName,
            @PageCount,
            @FragmentationPercent,
            @ActionName,
            @CommandText;
    END

    CLOSE index_cursor;
    DEALLOCATE index_cursor;

    SELECT
        RunId,
        SchemaName,
        TableName,
        IndexName,
        PageCount,
        FragmentationPercent,
        ActionName,
        StatusName,
        StartedAt,
        EndedAt,
        ErrorNumber,
        ErrorMessage
    FROM dbo.IndexMaintenanceLog
    WHERE RunId = @RunId
    ORDER BY Id;
END
GO
