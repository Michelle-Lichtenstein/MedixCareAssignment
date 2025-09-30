 -- PHASE 3: BACKUP & RECOVERY STRATEGY

-- This creates the file since I have xp_cmdshell enabled
EXEC xp_cmdshell 'mkdir C:\SQLBackup';


-- 1. Set the recovery model to FULL.
USE master;
ALTER DATABASE MedixCareDB SET RECOVERY FULL;
GO




-- 2. Perform: 
-- •	A full backup (weekly) 
-- •	Differential backups every 6 hours 
-- •	Transaction log backups every 15 minutes 
-- THIS SECTION SET EVERYTHING UP AUTOMATICALLY USING AGENT JOBS

--	A full backup (weekly) 
USE msdb;
GO

EXEC sp_add_job @job_name = N'MedixCareDB_FullBackup_Weekly';
GO

EXEC sp_add_jobstep
    @job_name = N'MedixCareDB_FullBackup_Weekly',
    @step_name = N'Full Backup Step',
    @subsystem = N'TSQL',
    @command = N'
        DECLARE @filename VARCHAR(255) =''C:\SQLBackup\MedixCareDB_Full_'' + 
            CONVERT(VARCHAR, GETDATE(), 112) + ''.bak'';
        BACKUP DATABASE MedixCareDB
        TO DISK = @filename
        WITH INIT, NAME = ''MedixCareDB Full Backup'';',
    @retry_attempts = 1,
    @retry_interval = 5;
GO

EXEC sp_add_schedule
    @schedule_name = N'Weekly_Sunday_2355',
    @freq_type = 1,  -- One-time weekly
    @freq_interval = 1,  -- On Sunday
    @active_start_time = 235500;
GO

EXEC sp_attach_schedule
    @job_name = N'MedixCareDB_FullBackup_Weekly',
    @schedule_name = N'Weekly_Sunday_2355';
GO

EXEC sp_add_jobserver @job_name = N'MedixCareDB_FullBackup_Weekly';
GO


-- Differential backups every 6 hours 
USE msdb;
GO

EXEC sp_add_job @job_name = N'MedixCareDB_DiffBackup_6hr';
GO

EXEC sp_add_jobstep
    @job_name = N'MedixCareDB_DiffBackup_6hr',
    @step_name = N'Differential Backup Step',
    @subsystem = N'TSQL',
    @command = N'
        DECLARE @filename VARCHAR(255) = ''C:\SQLBackup\MedixCareDB_Diff_'' + 
            REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '':'', '''') + ''.bak'';
        BACKUP DATABASE MedixCareDB
        TO DISK = @filename
        WITH DIFFERENTIAL,
             INIT,
             NAME = ''MedixCareDB Differential Backup'';',
    @retry_attempts = 1,
    @retry_interval = 5;
GO

-- Creates a new schedule that starts at midnight
EXEC sp_add_schedule
    @schedule_name = N'Every_6_Hours',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @freq_subday_type = 8,  -- Hours
    @freq_subday_interval = 6,
    @active_start_time = 000000; -- This indicates that it starts at midnight
GO

-- This section attachs the new schedule to the job
EXEC sp_attach_schedule
    @job_name = N'MedixCareDB_DiffBackup_6hr',
    @schedule_name = N'Every_6_Hours';
GO

EXEC sp_add_jobserver @job_name = N'MedixCareDB_DiffBackup_6hr';
GO


-- Creates a full backup at 6:00
USE msdb;
GO

-- Delete the job if it exists
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'MedixCareDB_FullBackup_OneTime_0600')
BEGIN
    EXEC sp_delete_job @job_name = N'MedixCareDB_FullBackup_OneTime_0600';
END
GO

-- This section creates the job
EXEC sp_add_job 
    @job_name = N'MedixCareDB_FullBackup_OneTime_0600',
    @enabled = 1,
    @description = N'One-time full backup scheduled tomorrow at 06:00 AM';
GO

-- This section adds the job step
EXEC sp_add_jobstep
    @job_name = N'MedixCareDB_FullBackup_OneTime_0600',
    @step_name = N'Full Backup Step',
    @subsystem = N'TSQL',
    @command = N'
        DECLARE @filename VARCHAR(255) = ''C:\SQLBackup\MedixCareDB_Full_'' + 
            REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '':'' , '''') + ''.bak'';
        BACKUP DATABASE MedixCareDB
        TO DISK = @filename
        WITH INIT,
             NAME = ''MedixCareDB Full Backup'';
    ',
    @retry_attempts = 1,
    @retry_interval = 5;
GO

-- This section creates the schedule with tomorrow's date using dynamic SQL
DECLARE @tomorrow INT = CAST(CONVERT(VARCHAR, DATEADD(DAY, 1, GETDATE()), 112) AS INT);

DECLARE @sql NVARCHAR(MAX) = '
EXEC sp_add_schedule
    @schedule_name = N''FullBackup_OneTime_0600'',
    @freq_type = 1,
    @active_start_date = ' + CAST(@tomorrow AS NVARCHAR(8)) + ',
    @active_start_time = 60000;
';

EXEC sp_executesql @sql;
GO

-- This section attaches a schedule to the job
EXEC sp_attach_schedule
    @job_name = N'MedixCareDB_FullBackup_OneTime_0600',
    @schedule_name = N'FullBackup_OneTime_0600';
GO

-- This section adds the job to the server
EXEC sp_add_jobserver
    @job_name = N'MedixCareDB_FullBackup_OneTime_0600';
GO

-- This section confirms that the job exists
SELECT COUNT(*) AS JobExists
FROM msdb.dbo.sysjobs
WHERE name = 'MedixCareDB_FullBackup_OneTime_0600';


-- Transaction log backups every 15 minutes 
USE msdb;
GO

-- Delete job if it exists
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'MedixCareDB_LogBackup_15min')
BEGIN
    EXEC sp_delete_job @job_name = N'MedixCareDB_LogBackup_15min';
END
GO

-- This section creates the job
EXEC sp_add_job 
    @job_name = N'MedixCareDB_LogBackup_15min',
    @enabled = 1,
    @description = N'Backs up transaction log every 15 minutes starting at 8:00 AM';
GO

-- This section adds the job step
EXEC sp_add_jobstep
    @job_name = N'MedixCareDB_LogBackup_15min',
    @step_name = N'Transaction Log Backup Step',
    @subsystem = N'TSQL',
    @command = N'
        DECLARE @filename VARCHAR(255) = ''C:\SQLBackup\MedixCareDB_Log_'' + 
            REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '':'', '''') + ''.trn'';
        BACKUP LOG MedixCareDB
        TO DISK = @filename
        WITH INIT,
             NAME = ''MedixCareDB Transaction Log Backup'';',
    @retry_attempts = 1,
    @retry_interval = 5;
GO

-- This section creates a schedule which starts at 8:00 AM which runs every 15 minutes
EXEC sp_add_schedule
    @schedule_name = N'Every_15_Minutes_Starting_800',
    @freq_type = 4,              -- Daily
    @freq_interval = 1,
    @freq_subday_type = 4,       -- Minutes
    @freq_subday_interval = 15,
    @active_start_time = 80000;  -- 08:00:00 AM
GO

-- This section attaches a schedule to the job
EXEC sp_attach_schedule
    @job_name = N'MedixCareDB_LogBackup_15min',
    @schedule_name = N'Every_15_Minutes_Starting_800';
GO

-- This section adds the job to the server
EXEC sp_add_jobserver
    @job_name = N'MedixCareDB_LogBackup_15min';
GO

-- This section checks if the job exists
SELECT COUNT(*) AS JobExists
FROM msdb.dbo.sysjobs
WHERE name = 'MedixCareDB_LogBackup_15min';




-- 3. Simulate a failure at 14:35: 
-- •	Last full backup: 06:00 
-- •	Last differential: 12:00 
-- •	Last log backup: 14:30 
-- •	You must perform a tail-log backup before restoring. 
-- THIS SECTION SIMULATES THE FULL, DIFFERENTIAL, LOG BACKUP AND THE TAIL-LOG BY MANUALLY CREATING THEM 
 
-- Full backup (simulate at 06:00)
BACKUP DATABASE MedixCareDB 
TO DISK = 'C:\SQLBackup\MedixCareDB_Full_0600.bak'
WITH INIT, NAME = 'Full Backup 06:00';

-- Differential backup (simulate at 12:00)
BACKUP DATABASE MedixCareDB 
TO DISK = 'C:\SQLBackup\MedixCareDB_Diff_1200.bak' 
WITH DIFFERENTIAL, NAME = 'Differential Backup 12:00';

-- Transaction log backup (simulate at 14:30)
BACKUP LOG MedixCareDB 
TO DISK = 'C:\SQLBackup\MedixCareDB_Log_1430.trn' 
WITH NAME = 'Log Backup 14:30';

-- Tail-log backup before restore
BACKUP LOG MedixCareDB 
TO DISK = 'C:\SQLBackup\MedixCareDB_Tail_1435.trn' 
WITH NORECOVERY, NAME = 'Tail Log Backup 14:35';





-- 4. Restore sequence: 
-- •	Restore full backup (WITH NORECOVERY) 
-- •	Restore differential (WITH NORECOVERY) 
-- •	Restore logs up to 14:30 (WITH NORECOVERY) 
-- •	Restore tail-log (WITH RECOVERY)
-- FOR THIS TO WORK SUCCESSFULLY, I MANUALLY CREATED THE BACKUPS BUT HAD TO  
-- DISABLE THE AUTOMATIC JOBS (NR. 2)  FOR A WHILE FOR IT TO WORK

-- Restore full backup
RESTORE DATABASE MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Full_0600.bak'
WITH NORECOVERY;
GO


-- Restore differential backup
RESTORE DATABASE MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Diff_1200.bak'
WITH NORECOVERY;
GO


-- Restore transaction log backup at 14:30
RESTORE LOG MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Log_1430.trn'
WITH NORECOVERY;
GO

-- Restore tail-log backup and recover database
RESTORE LOG MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Tail_1435.trn'
WITH RECOVERY;
GO

