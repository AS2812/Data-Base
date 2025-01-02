CREATE DATABASE DBASSES;
USE DBASSES;

CREATE TABLE Address (    --independant entity
    City VARCHAR(100) NOT NULL,
    Zip_Code VARCHAR(10) PRIMARY KEY
);

CREATE TABLE Person (  --independant entity   Generalized Entity  Attributes: Id, Name, Date_of_birth, Gender, Address, Mob_no 
					   --and specialization in Employee--> Adds attributes like Salary, Hire_Date, Shift
					   --and in patient--> Adds attributes like Room, Disease_ID, Admission_Date
    Id INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Date_of_birth DATE NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    Address VARCHAR(10),
    Mob_no VARCHAR(15) NOT NULL,
    FOREIGN KEY (Address) REFERENCES Address(Zip_Code) ON DELETE CASCADE  -- Keep ON DELETE CASCADE: If an address is removed all associated people should also be removed
);

--Room, Department, Disease, and Medication: Resources or classifications used across multiple entities.

CREATE TABLE Room (
    ID INT PRIMARY KEY,
    Type VARCHAR(50) NOT NULL,
    Capacity INT CHECK (Capacity >= 0),
    Availability INT DEFAULT 1
);

CREATE TABLE Disease (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    Status VARCHAR(20) CHECK (Status IN ('chronic', 'normal'))
);

CREATE TABLE Medication (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    UNIQUE (Name)
);

--Patient: Depends on Person (every patient is a person)
CREATE TABLE Patient (
    Patient_ID INT PRIMARY KEY IDENTITY(1,1),
    Person_ID INT NOT NULL,
    Room INT,
    Disease_ID INT,
    Admission_Date DATE NOT NULL,
    Release_Date DATE,
    PCP INT,
    Job VARCHAR(100),
    Feedback TEXT,
    FOREIGN KEY (Person_ID) REFERENCES Person(Id) ON DELETE CASCADE,  -- Keep ON DELETE CASCADE: If a person is removed all associated patients should also be removed
    FOREIGN KEY (Room) REFERENCES Room(ID) on delete set null,
    FOREIGN KEY (Disease_ID) REFERENCES Disease(Id) on delete set null 
);
--Depend on Patient
CREATE TABLE Patient_Medication (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Patient_ID INT NOT NULL,
    Medication_ID INT NULL,
    Dosage VARCHAR(50) NOT NULL,
    Start_Date DATE NOT NULL,
    End_Date DATE,
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID) ON DELETE CASCADE, -- Keep ON DELETE CASCADE: If a patient is removed all their medications should also be removed
    FOREIGN KEY (Medication_ID) REFERENCES Medication(ID) ON DELETE SET NULL, -- Changed to ON DELETE SET NULL
    UNIQUE (Patient_ID, Medication_ID, Dosage, Start_Date)
);

CREATE TABLE Department (
    ID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Doctor_Count INT DEFAULT 0
);


--Employee: Depends on Person (every employee is a person)

CREATE TABLE Employee (  -- generalization entity --> Attributes: Id, Person_ID, Salary, Hire_Date 

  Id INT PRIMARY KEY,
    Person_ID INT NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL,
    Hire_Date DATE NOT NULL,
    Shift VARCHAR(50) NOT NULL,
    Bonus DECIMAL(10, 2) DEFAULT 0,
    Taxes DECIMAL(10, 2) DEFAULT 0,
    Employment_Status VARCHAR(50) CHECK (Employment_Status IN ('Active', 'On Leave', 'Terminated', 'Retired')),
    Performance_Rating DECIMAL(3, 2) CHECK (Performance_Rating BETWEEN 0 AND 5),
    Job_Title VARCHAR(100),
    FOREIGN KEY (Person_ID) REFERENCES Person(Id) ON DELETE CASCADE  -- Keep ON DELETE CASCADE: If a person is removed all associated employees should also be removed
);
--Doctor and Nurse--> Specializations of Employee
CREATE TABLE Doctor (
    Id INT PRIMARY KEY,
    Emp_id INT NOT NULL,
    Department_id INT NULL,
    Specialism VARCHAR(100) NOT NULL,
    Qualification VARCHAR(100) NOT NULL,
    Supervisor INT,
    FOREIGN KEY (Emp_id) REFERENCES Employee(Id) ON DELETE CASCADE, -- Keep ON DELETE CASCADE: If an employee is removed any doctors that were that employee should also be removed
    FOREIGN KEY (Department_id) REFERENCES Department(ID) on delete set null, -- Department does not get cascading
    FOREIGN KEY (Supervisor) REFERENCES Doctor(Id) 
);
CREATE TRIGGER SetSupervisorNull
ON Doctor
AFTER DELETE
AS
BEGIN
    -- Set Supervisor to NULL for doctors supervised by the deleted doctor
    UPDATE Doctor
    SET Supervisor = NULL
    WHERE Supervisor IN (SELECT Id FROM Deleted);
END;
GO


CREATE TABLE Nurse (
	ID INT PRIMARY KEY IDENTITY(1,1),
    Emp_id int not null,
    Supervisor_ID INT,
    FOREIGN KEY (Emp_id) REFERENCES Employee(Id) ON DELETE CASCADE,  -- Keep ON DELETE CASCADE: If an employee is removed any nurses that were that employee should also be removed
    FOREIGN KEY (Supervisor_ID) REFERENCES Employee(Id)
);
CREATE TRIGGER SetNURSESupervisorNull
ON Nurse
AFTER DELETE
AS
BEGIN
    -- Set Supervisor to NULL for doctors supervised by the deleted doctor
    UPDATE Nurse
    SET Supervisor_ID = NULL
    WHERE Supervisor_ID  IN (SELECT ID FROM Deleted);
END;
GO

CREATE TRIGGER UpdateDoctorCount
ON Doctor
AFTER INSERT
AS
BEGIN
    UPDATE Department
    SET Doctor_Count = Doctor_Count + 1
    FROM Inserted
    WHERE Department.ID = Inserted.Department_id;
END;
GO

CREATE TRIGGER Set_Job_Title_After_Insert_Doctor
ON Doctor
AFTER INSERT
AS
BEGIN
    UPDATE Employee
    SET Job_Title = 'Doctor'
    FROM Inserted
    WHERE Employee.Id = Inserted.Emp_id;
END;
GO

CREATE TRIGGER Set_Job_Title_After_Insert_Nurse
ON Nurse
AFTER INSERT
AS
BEGIN
    UPDATE Employee
    SET Job_Title = 'Nurse'
    FROM Inserted
    WHERE Employee.Id = Inserted.Emp_id;
END;
GO

CREATE TABLE Patient_Medical_History (
    ID INT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    disease_id INT,
    Surgery_Type VARCHAR(100),
    Surgery_Date DATE,
    Description TEXT,
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID) ON DELETE CASCADE -- Keep ON DELETE CASCADE: If a patient is removed all of their medical history should also be removed
);
CREATE TABLE Medical_equipment (
    ID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Type VARCHAR(100),
    Availability INT DEFAULT 1,
    Room_ID INT,
    equipment_Count INT DEFAULT 0,
    FOREIGN KEY (Room_ID) REFERENCES Room(ID) ON DELETE SET NULL  -- Changed to ON DELETE SET NULL
);


CREATE TABLE Bill (
    ID INT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    Date DATE NOT NULL,
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID) ON DELETE CASCADE -- Keep ON DELETE CASCADE: If a patient is removed all of their bills should also be removed
);

CREATE TABLE Appointments (
    ID INT PRIMARY KEY,
    Doctor_ID INT NOT NULL,
    Patient_ID INT NOT NULL,
    Appointment_Date DATETIME NOT NULL,
    Status VARCHAR(20) DEFAULT 'Scheduled',
    FOREIGN KEY (Doctor_ID) REFERENCES Doctor(Id) ON DELETE NO ACTION,  -- Keep ON DELETE NO ACTION: If the doctor is deleted we should keep the appointment record
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID) ON DELETE CASCADE -- Keep ON DELETE CASCADE: If the patient is deleted all of their appointments should also be removed
);

CREATE TABLE Ambulance (
    License_Plate VARCHAR(50) PRIMARY KEY,
    Driver_E_ID INT UNIQUE,
    Availability_Status VARCHAR(50) DEFAULT 'Available',
    FOREIGN KEY (Driver_E_ID) REFERENCES Employee(Id) ON DELETE SET NULL -- Keep ON DELETE CASCADE: If an employee is removed any ambulances that were driven by that employee shouldn't also be removed could be driven by another employee
);

CREATE TRIGGER Set_Job_Title_After_Insert_Ambulance
ON Ambulance
AFTER INSERT
AS
BEGIN
    UPDATE Employee
    SET Job_Title = 'Ambulance Driver'
    FROM Inserted
    WHERE Employee.Id = Inserted.Driver_E_ID;
END;
GO


--Person
-- ├── Employee
-- │     ├── Doctor
-- │     ├── Nurse
-- │     └── Ambulance Driver
-- └── Patient
--       ├── Patient_Medication
--       ├── Patient_Medical_History
--       └── Appointments
