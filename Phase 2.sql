--PHASE 2: CONFIGURING AUDITING

--1. Create a Server Audit that writes to a file C:\SQLAudit\ . 
-- This section enables the xp_cmdshell due to me not having it enabled
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- This part creates the folder on the C:\ Drive
EXEC xp_cmdshell 'mkdir C:\SQLAudit';


-- This part actually creates the Server Audit
CREATE SERVER AUDIT MedixCareServerAudit
TO FILE (
    FILEPATH = 'C:\SQLAudit\',
    MAXSIZE = 5 MB,
    MAX_FILES = 10,
    RESERVE_DISK_SPACE = OFF
)
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);



-- 2. Create a Server Audit Specification to track:
--    • Successful and failed logins
--    • Logout events
CREATE SERVER AUDIT SPECIFICATION MedixCareServerAuditSpec
FOR SERVER AUDIT MedixCareServerAudit
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (LOGOUT_GROUP);


-- 3. Create a Database Audit Specification (on MedixCareDB) to track:
--    • Changes to permissions (DATABASE_PERMISSION_CHANGE_GROUP)
--    • Backup/restore actions (BACKUP_RESTORE_GROUP)
--    • DML changes to Patients table (INSERT, UPDATE, DELETE actions)
USE MedixCareDB;
GO

CREATE DATABASE AUDIT SPECIFICATION MedixCareDBAuditSpec
FOR SERVER AUDIT MedixCareServerAudit
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (BACKUP_RESTORE_GROUP),
ADD (INSERT ON dbo.Patients BY PUBLIC),
ADD (UPDATE ON dbo.Patients BY PUBLIC),
ADD (DELETE ON dbo.Patients BY PUBLIC)
WITH (STATE = OFF);





-- 4. Enable the audit and perform test actions (e.g., login as DrJames, update a record).
USE master;
GO
ALTER SERVER AUDIT MedixCareServerAudit WITH (STATE = ON);
ALTER SERVER AUDIT SPECIFICATION MedixCareServerAuditSpec WITH (STATE = ON);

-- Now switch to the user database:
USE MedixCareDB;
GO
ALTER DATABASE AUDIT SPECIFICATION MedixCareDBAuditSpec WITH (STATE = ON);




-- This tests to see if logged in as DrJames is successful , it gets logged
EXECUTE AS LOGIN = 'DrJames';

-- This tests to see if DrJames can update the patients info, it gets logged
UPDATE Patients
SET PatientName = 'Audit Testing'
WHERE PatientID = 1;

INSERT INTO Patients (PatientName , IDNumber, DateOfBirth, EmergencyContact)
VALUES ('Audit Testing' , '9001015009082', '1990-01-01', '082 985 1206');


-- This part adds a patient which will be deleted 
IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientName = 'Tomas Lee')
BEGIN
    INSERT INTO Patients (PatientName,IDNumber, DateOfBirth, EmergencyContact)
    VALUES ('Tomas Lee','8001010158039', '1980-01-01', '080 123 4567');
END

-- This will delete the patient to test the delete and log the delete
DELETE FROM Patients
WHERE PatientName = 'Tomas Lee';

REVERT;



-- 5. View the audit log using: 
SELECT * FROM sys.fn_get_audit_file('C:\SQLAudit\*.sqlaudit', DEFAULT, DEFAULT);




