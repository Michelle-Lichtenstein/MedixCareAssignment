-- 1.Create a database named MedixCareDB with the given tables and populate them with 
--sample data of your choice.

-- 1. Create the database
CREATE DATABASE MedixCareDB;
GO

USE MedixCareDB;
GO

-- This creates the Doctors Table
CREATE TABLE Doctors (
    DoctorID		INT IDENTITY(1,1) PRIMARY KEY,
    DoctorName		VARCHAR(100) NOT NULL,
    Specialization  VARCHAR(100),
    HireDate		DATE,
    IsActive		BIT DEFAULT 1
);

-- This creates the Patients Table
CREATE TABLE Patients (
    PatientID		 INT IDENTITY(1,1) PRIMARY KEY,
    PatientName		 VARCHAR(100) NOT NULL,
    IDNumber		 CHAR(13) NOT NULL,
    DateOfBirth		 DATE NOT NULL,
    ContactPhone	 VARCHAR(100),
    EmergencyContact NVARCHAR(100),
    AdmissionDate	 DATETIME DEFAULT GETDATE(),
    Diagnosis		 INT,
    DoctorID		 INT FOREIGN KEY REFERENCES Doctors(DoctorID)
);

-- This creates the Appointments Table
CREATE TABLE Appointments (
    AppointmentID	INT IDENTITY(1,1) PRIMARY KEY,
    PatientID		INT FOREIGN KEY REFERENCES Patients(PatientID),
    DoctorID		INT FOREIGN KEY REFERENCES Doctors(DoctorID),
    AppointmentDate DATETIME NOT NULL,
    Reason			VARCHAR(200),
    Status			VARCHAR(20) DEFAULT 'Scheduled',
    Notes			VARCHAR(20)
);


-- This creates the Staff Table
CREATE TABLE Staff (
    StaffID			INT IDENTITY(1,1) PRIMARY KEY,
    StaffName		VARCHAR(100) NOT NULL,
    Role			VARCHAR(50),
    DepartmentID	INT,
    HireDate		DATE
);


-- This creates the StaffDuties Table
CREATE TABLE StaffDuties (
    DutyID			INT IDENTITY(1,1) PRIMARY KEY,
    StaffID			INT,
    DepartmentID	INT,
    StartDate		DATE,
    EndDate			DATE,
    Description		VARCHAR(20)
);

-- This creates the Sales Table
CREATE TABLE Sales (
    SalesID			INT IDENTITY(1,1) PRIMARY KEY,
    ProductName		VARCHAR(100),
    Quantity		INT,
    UnitPrice		DECIMAL(10,2),
    TotalAmount		AS (Quantity * UnitPrice),
    SaleDate		DATETIME DEFAULT GETDATE(),
    Storelocation	VARCHAR(50),
    Diagnosis		INT,
    DoctorID		INT FOREIGN KEY REFERENCES Doctors(DoctorID)
);

-- Insert sample data into the Doctors Table
INSERT INTO Doctors (DoctorName, Specialization, HireDate) VALUES 
('Dr James Dean', 'General Practitioner', '2020-05-01'),
('Dr Sarah Adams', 'Cardiology', '2021-02-14'),
('Dr Gregory House', 'Diagnostics', '2023-08-29'),
('Dr Jade Lewis', 'Orthopedics', '2022-05-01'),
('Dr Brad Black', 'Oncology', '2024-09-20');


-- Insert sample data into the Patients Table
INSERT INTO Patients (PatientName, IDNumber, DateOfBirth, ContactPhone, EmergencyContact, DoctorID) VALUES
('Mary Lewis', '9001015800081', '1990-01-01', '082 741 0239', '082 985 1206', 1),
('Natalie Blackwoods', '9206230479067', '1992-06-23', '076 901 4302', '072 943 7512', 4),
('Jeffrey Williams', '9711120169075', '1997-11-12', '073 462 1590', '082 402 3367', 2),
('Jenny Snow', '9203140159073', '1992-03-14', '076 189 1237', '078 820 4459', 5),
('Dmitri Volkov', '9901280693089', '1999-01-28', '074 562 0046', '083 471 9620', 3);


-- Insert sample data into the Appointments Table
INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, Reason) VALUES
(1, 1, '2025-08-06 09:00', 'Routine check-up'),
(2, 1, '2025-08-06 11:15', 'Body Pain'),
(3, 4, '2025-06-06 13:00', 'Surgery Consultation'),
(4, 5, '2025-09-25 14:20', 'Routine check-up'),
(5, 3, '2025-07-06 10:26', 'Sudden Faint');


-- Insert sample staff members (including more nurses and doctors)
INSERT INTO Staff (StaffName, Role, DepartmentID, HireDate) VALUES
('Nurse Thandi Knight', 'Nurse', 1, '2019-11-01'),
('Nurse Charles Woods', 'Nurse', 3, '2018-09-05'),
('Nurse Patricia Evans', 'Nurse', 4, '2022-02-28'),
('Lab Technician Stephen James', 'Lab Technician', 2, '2020-08-15'),
('Admin Pete Jacobs', 'Administrator', 3, '2018-01-10'),
('Dr James Dean', 'Doctor', 1, '2020-05-01'),
('Dr Sarah Adams', 'Doctor', 2, '2021-02-14'),
('Dr Gregory House', 'Doctor', 1, '2023-08-29'),
('Dr Jade Lewis', 'Doctor', 3, '2022-05-01'),
('Dr Brad Black', 'Doctor', 4, '2024-09-20');


-- Insert sample data into the Appointments Table
INSERT INTO StaffDuties (StaffID, DepartmentID, StartDate, EndDate, Description) VALUES
(1, 1, '2025-01-08', '2025-03-30', 'Ward Rounds'),
(1, 1, '2025-07-12', '2025-09-25', 'Triage'),
(2, 2, '2025-03-01', '2025-05-14', 'Blood Tests'),
(3, 3, '2025-05-01', '2025-10-25', 'Scheduling');


-- Insert sample data into the Appointments Table
INSERT INTO Sales (ProductName, Quantity, UnitPrice, Storelocation, Diagnosis, DoctorID) VALUES
('Paracetamol', 10, 5.00, 'Pharmacy - Main', 101, 1),
('Cough Syrup', 5, 15.00, 'Pharmacy - Main', 102, 2),
('Antibiotics', 7, 12.50, 'Pharmacy - Main', 103, 1),
('Vitamin C', 20, 2.00, 'Pharmacy - Extension', 104, 2);


SELECT * FROM Doctors;
SELECT * FROM Patients;
SELECT * FROM Appointments;
SELECT * FROM StaffDuties;
SELECT * FROM Sales;



-- 2. Create login-based users
-- Use the master database to add the users first
USE master;

CREATE LOGIN DrJames WITH PASSWORD = 'DrJames!@753';
CREATE LOGIN NurseThandi WITH PASSWORD = 'NurseThandi@_760!';
CREATE LOGIN AdminPete WITH PASSWORD = 'AdminPete@!720';


-- Switch back to MedixCareDB to add the users
USE MedixCareDB;

-- Add the Users
CREATE USER DrJames FOR LOGIN DrJames;
CREATE USER NurseThandi FOR LOGIN NurseThandi;
CREATE USER AdminPete FOR LOGIN AdminPete;

-- 3. Create the required roles
CREATE ROLE Role_Doctor;
CREATE ROLE Role_Nurse;
CREATE ROLE Role_Admin;

-- Link the users to the roles
ALTER ROLE Role_Doctor ADD MEMBER DrJames;
ALTER ROLE Role_Nurse ADD MEMBER NurseThandi;
ALTER ROLE Role_Admin ADD MEMBER AdminPete;

--  Grant the required permissions to Role_Doctor
GRANT SELECT, INSERT ON Patients TO Role_Doctor;
GRANT SELECT, INSERT ON Appointments TO Role_Doctor;

--Grant the required permissions to Role_Nurse
GRANT SELECT ON Patients TO Role_Nurse;
GRANT UPDATE ON Appointments TO Role_Nurse;

--Grant the required permissions to Role_Admin
GRANT CONTROL ON DATABASE::MedixCareDB TO Role_Admin;


-- 4. Test to see if NurseThandi can delete from Patients
EXECUTE AS USER = 'NurseThandi';
DELETE FROM Patients WHERE PatientID = 1;  
REVERT;

-- Test to see if DrJames can SELECT from Appointments as well as login
EXECUTE AS USER = 'DrJames';
SELECT * FROM Appointments; 
REVERT;


