/*
HBweb / POSM 每周索引维护 Job 安装脚本

用途：
1. 创建 SQL Server Agent Job。
2. 每周日 18:00 串行执行 HBweb 和 POSM 索引维护。
3. 不会立即运行 Job；安装后等待下一个计划时间自动运行。

执行前请先在 HBweb 数据库执行：
docs/sql/maintain-product-store-retail-price-indexes.sql

执行前请先在 POSM 数据库执行：
docs/sql/maintain-posm-indexes.sql
*/

USE msdb;
GO

SET NOCOUNT ON;
GO

DECLARE @JobName SYSNAME = N'Weekly HBweb POSM Index Maintenance';
DECLARE @LegacyJobName SYSNAME = N'HBweb - Weekly Product StoreRetailPrice Index Maintenance';
DECLARE @ScheduleName SYSNAME = N'Weekly HBweb POSM Index Maintenance - Sunday 18:00';
DECLARE @CategoryName SYSNAME = N'Database Maintenance';
DECLARE @JobId UNIQUEIDENTIFIER;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.databases
    WHERE name = N'HBweb'
)
BEGIN
    THROW 52000, N'缺少 HBweb 数据库，无法安装索引维护 Job。', 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.databases
    WHERE name = N'POSM'
)
BEGIN
    THROW 52002, N'缺少 POSM 数据库，无法安装索引维护 Job。', 1;
END;

IF OBJECT_ID(N'HBweb.dbo.usp_MaintainProductStoreRetailPriceIndexes', N'P') IS NULL
BEGIN
    THROW 52001, N'缺少 HBweb.dbo.usp_MaintainProductStoreRetailPriceIndexes，请先执行维护存储过程脚本。', 1;
END;

IF OBJECT_ID(N'POSM.dbo.usp_MaintainPosmIndexes', N'P') IS NULL
BEGIN
    THROW 52003, N'缺少 POSM.dbo.usp_MaintainPosmIndexes，请先执行 POSM 维护存储过程脚本。', 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.syscategories
    WHERE name = @CategoryName
      AND category_class = 1
)
BEGIN
    EXEC msdb.dbo.sp_add_category
        @class = N'JOB',
        @type = N'LOCAL',
        @name = @CategoryName;
END;

IF EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobs
    WHERE name = @JobName
)
BEGIN
    EXEC msdb.dbo.sp_update_job
        @job_name = @JobName,
        @enabled = 0;

    EXEC msdb.dbo.sp_delete_job
        @job_name = @JobName,
        @delete_unused_schedule = 1;
END;

IF EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobs
    WHERE name = @LegacyJobName
)
BEGIN
    EXEC msdb.dbo.sp_update_job
        @job_name = @LegacyJobName,
        @enabled = 0;

    EXEC msdb.dbo.sp_delete_job
        @job_name = @LegacyJobName,
        @delete_unused_schedule = 1;
END;

EXEC msdb.dbo.sp_add_job
    @job_name = @JobName,
    @enabled = 1,
    @description = N'每周串行维护 HBweb.dbo.Product、HBweb.dbo.StoreRetailPrice 和 POSM 全库普通索引碎片。只执行 REORGANIZE / ONLINE REBUILD，不删除索引，不创建业务索引。',
    @category_name = @CategoryName,
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'维护 HBweb Product / StoreRetailPrice 索引碎片',
    @subsystem = N'TSQL',
    @database_name = N'HBweb',
    @command = N'EXEC dbo.usp_MaintainProductStoreRetailPriceIndexes;',
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'维护 POSM 全库索引碎片',
    @subsystem = N'TSQL',
    @database_name = N'POSM',
    @command = N'EXEC dbo.usp_MaintainPosmIndexes;',
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0;

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = @ScheduleName,
    @enabled = 1,
    @freq_type = 8,
    @freq_interval = 1,
    @freq_recurrence_factor = 1,
    @active_start_time = 180000;

EXEC msdb.dbo.sp_attach_schedule
    @job_id = @JobId,
    @schedule_name = @ScheduleName;

EXEC msdb.dbo.sp_add_jobserver
    @job_id = @JobId,
    @server_name = N'(LOCAL)';

SELECT
    j.name AS JobName,
    j.enabled AS JobEnabled,
    s.name AS ScheduleName,
    s.enabled AS ScheduleEnabled,
    s.freq_type AS FrequencyType,
    s.freq_interval AS FrequencyInterval,
    s.active_start_time AS ActiveStartTime
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobschedules AS js
    ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules AS s
    ON js.schedule_id = s.schedule_id
WHERE j.job_id = @JobId;
GO
