# MedixCareAssignment

This project builds a complete SQL Server database solution for MedixCare Clinic. It covers three main areas of database security and maintenance: secure data access and permissions, auditing and activity tracking, and backup and recovery strategy. The goal is to simulate a realistic healthcare database environment where sensitive data is securely managed, monitored, and recoverable.

## Phase 1: Secure Data Access & Permissions

The script creates a database named `MedixCareDB` and defines the following tables:

| Table          | Purpose                                             |
|---------------|-----------------------------------------------------|
| `Doctors`     | Stores doctor details and specialization.           |
| `Patients`    | Stores patient records and links them to doctors.   |
| `Appointments`| Tracks patient appointments.                        |
| `Staff`       | Stores clinic staff details and roles.              |
| `StaffDuties` | Tracks staff duties and schedules.                  |
| `Sales`       | Tracks product sales related to treatments.         |

Each table is populated with sample data for testing.

Users and roles are created as follows:

| Login/User    | Role   | Purpose                                        |
|---------------|--------|------------------------------------------------|
| `DrJames`     | Doctor | View and insert patient and appointment data.  |
| `NurseThandi` | Nurse  | View patient data and update appointments.     |
| `AdminPete`   | Admin  | Full control of the database.                  |

Roles and permissions:

- `Role_Doctor`: `SELECT`, `INSERT` on `Patients` and `Appointments`  
- `Role_Nurse`: `SELECT` on `Patients`, `UPDATE` on `Appointments`  
- `Role_Admin`: `CONTROL` on the database

To test permissions:

- Attempt a `DELETE` as `NurseThandi` → should fail  
- Run a `SELECT` on `Appointments` as `DrJames` → should succeed

## Phase 2: Configuring Auditing

Auditing is set up to track key database activities. A server audit writes to `C:\SQLAudit\` (ensure the folder exists and `xp_cmdshell` is enabled). The server audit specification monitors successful logins, failed logins, and logout events. The database audit specification logs permission changes, backup/restore actions, and `INSERT`, `UPDATE`, `DELETE` operations on `Patients`. Enable the audits and test by logging in as `DrJames`, updating a patient record, and inserting/deleting test records. View audit logs with:

```sql
SELECT *
FROM sys.fn_get_audit_file('C:\SQLAudit\*.sqlaudit', DEFAULT, DEFAULT);
```

## Phase 3: Backup & Recovery Strategy

A comprehensive backup plan ensures data availability and recoverability.

### 1. Recovery Model
Set the database recovery model to FULL:

```sql
ALTER DATABASE MedixCareDB SET RECOVERY FULL;
```

2. Automated Backup Jobs

| Backup                  | Type              | Frequency Purpose                               |
|-----------------------  |-----------------  |------------------------------------------------ |
| Full Backup             | Weekly            | Complete database snapshot.                     |
| Differential Backup     | Every 6 Hours     | Backup changes since last full backup.          |
| Transaction Log Backup  | Every 15 minutes  | Backup all transactions since last log backup.  |

SQL Server Agent jobs handle all scheduled backups.

3. Simulated Failure Scenario
Simulate a system failure at 14:35:

- Last full backup: 06:00
- Last differential: 12:00
- Last log backup: 14:30
- Create a tail-log backup before restoring

4. Restore Sequence

Restore the database to its state just before failure:
```sql
-- Full backup
RESTORE DATABASE MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Full_0600.bak'
WITH NORECOVERY;

-- Differential backup
RESTORE DATABASE MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Diff_1200.bak'
WITH NORECOVERY;

-- Transaction log backup
RESTORE LOG MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Log_1430.trn'
WITH NORECOVERY;

-- Tail-log backup
RESTORE LOG MedixCareDB
FROM DISK = 'C:\SQLBackup\MedixCareDB_Tail_1435.trn'
WITH RECOVERY;
```

## Requirements:

- Microsoft SQL Server 2019 or newer
- SQL Server Management Studio (SSMS)
- Permissions to create databases, logins, jobs, and audits

## How to Run:

Clone the repository:

```sql
git clone https://github.com/your-username/MedixCareAssignment.git
```

- Open MedixCareDB_Script.sql in SSMS.
- Run the script in order: Phase 1 → Phase 2 → Phase 3.
- Verify roles, auditing, and backup jobs.
- Simulate failure and test the restore sequence.

## About the Project

This project was created as part of a database security and infrastructure assignment for MedixCare Clinic. It demonstrates: 
  - Role-based security and least privilege 
  - Auditing for compliance and accountability 
  - Backup and recovery for business continuity.
