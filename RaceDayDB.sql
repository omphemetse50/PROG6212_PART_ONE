/*
    RaceDay System - Part 1 SQL Server Database Script
    Compatible with Microsoft SQL Server / SSMS.

    Entities:
    Roles, Users, Categories, Events, Enrolments, Results

    Roles:
    1. Organiser
    2. Participant
*/

IF DB_ID('RaceDayDB') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB;
END;
GO

USE RaceDayDB;
GO

-- Drop tables in dependency order so the script can be re-run during testing.
IF OBJECT_ID('dbo.Results', 'U') IS NOT NULL DROP TABLE dbo.Results;
IF OBJECT_ID('dbo.Enrolments', 'U') IS NOT NULL DROP TABLE dbo.Enrolments;
IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL DROP TABLE dbo.Roles;
GO

CREATE TABLE dbo.Roles
(
    role_id INT IDENTITY(1,1) NOT NULL,
    role_name VARCHAR(30) NOT NULL,
    description VARCHAR(255) NULL,

    CONSTRAINT PK_Roles PRIMARY KEY (role_id),
    CONSTRAINT UQ_Roles_role_name UNIQUE (role_name)
);
GO

CREATE TABLE dbo.Users
(
    user_id INT IDENTITY(1,1) NOT NULL,
    role_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_Users_is_active DEFAULT (1),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_Users_created_at DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Users PRIMARY KEY (user_id),
    CONSTRAINT UQ_Users_email UNIQUE (email),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (role_id)
        REFERENCES dbo.Roles(role_id)
);
GO

CREATE TABLE dbo.Categories
(
    category_id INT IDENTITY(1,1) NOT NULL,
    category_name VARCHAR(80) NOT NULL,
    description VARCHAR(255) NULL,

    CONSTRAINT PK_Categories PRIMARY KEY (category_id),
    CONSTRAINT UQ_Categories_category_name UNIQUE (category_name)
);
GO

CREATE TABLE dbo.Events
(
    event_id INT IDENTITY(1,1) NOT NULL,
    organizer_id INT NOT NULL,
    category_id INT NOT NULL,
    event_name VARCHAR(120) NOT NULL,
    description VARCHAR(500) NULL,
    location VARCHAR(150) NOT NULL,
    event_date DATETIME2 NOT NULL,
    capacity INT NOT NULL,
    entry_fee DECIMAL(10,2) NOT NULL CONSTRAINT DF_Events_entry_fee DEFAULT (0.00),
    status VARCHAR(20) NOT NULL CONSTRAINT DF_Events_status DEFAULT ('Open'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_Events_created_at DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Events PRIMARY KEY (event_id),
    CONSTRAINT FK_Events_Organizer FOREIGN KEY (organizer_id)
        REFERENCES dbo.Users(user_id),
    CONSTRAINT FK_Events_Category FOREIGN KEY (category_id)
        REFERENCES dbo.Categories(category_id),
    CONSTRAINT CK_Events_capacity CHECK (capacity > 0),
    CONSTRAINT CK_Events_entry_fee CHECK (entry_fee >= 0),
    CONSTRAINT CK_Events_status CHECK (status IN ('Draft', 'Open', 'Closed', 'Completed', 'Cancelled'))
);
GO

CREATE TABLE dbo.Enrolments
(
    enrolment_id INT IDENTITY(1,1) NOT NULL,
    event_id INT NOT NULL,
    participant_id INT NOT NULL,
    enrolled_at DATETIME2 NOT NULL CONSTRAINT DF_Enrolments_enrolled_at DEFAULT (SYSDATETIME()),
    status VARCHAR(20) NOT NULL CONSTRAINT DF_Enrolments_status DEFAULT ('Confirmed'),
    emergency_contact VARCHAR(100) NULL,
    emergency_phone VARCHAR(20) NULL,

    CONSTRAINT PK_Enrolments PRIMARY KEY (enrolment_id),
    CONSTRAINT FK_Enrolments_Event FOREIGN KEY (event_id)
        REFERENCES dbo.Events(event_id),
    CONSTRAINT FK_Enrolments_Participant FOREIGN KEY (participant_id)
        REFERENCES dbo.Users(user_id),
    CONSTRAINT UQ_Enrolments_EventParticipant UNIQUE (event_id, participant_id),
    CONSTRAINT CK_Enrolments_status CHECK (status IN ('Pending', 'Confirmed', 'Cancelled', 'Completed'))
);
GO

CREATE TABLE dbo.Results
(
    result_id INT IDENTITY(1,1) NOT NULL,
    enrolment_id INT NOT NULL,
    finish_position INT NULL,
    finish_time_seconds DECIMAL(10,2) NULL,
    score DECIMAL(10,2) NULL,
    result_status VARCHAR(20) NOT NULL CONSTRAINT DF_Results_status DEFAULT ('Recorded'),
    recorded_at DATETIME2 NOT NULL CONSTRAINT DF_Results_recorded_at DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Results PRIMARY KEY (result_id),
    CONSTRAINT UQ_Results_enrolment UNIQUE (enrolment_id),
    CONSTRAINT FK_Results_Enrolment FOREIGN KEY (enrolment_id)
        REFERENCES dbo.Enrolments(enrolment_id),
    CONSTRAINT CK_Results_position CHECK (finish_position IS NULL OR finish_position > 0),
    CONSTRAINT CK_Results_time CHECK (finish_time_seconds IS NULL OR finish_time_seconds > 0),
    CONSTRAINT CK_Results_score CHECK (score IS NULL OR score >= 0),
    CONSTRAINT CK_Results_status CHECK (result_status IN ('Recorded', 'Disqualified', 'Pending'))
);
GO

-- Seed roles: exactly the two application roles required by the brief.
INSERT INTO dbo.Roles (role_name, description)
VALUES
('Organiser', 'Creates and manages RaceDay events and records results'),
('Participant', 'Registers for RaceDay events and views personal results');
GO

-- Seed users: at least two organisers and two participants.
-- Passwords are sample hashes/placeholders for the planning database only.
INSERT INTO dbo.Users
    (role_id, first_name, last_name, email, password_hash, phone)
VALUES
((SELECT role_id FROM dbo.Roles WHERE role_name = 'Organiser'),
 'Lerato', 'Mokoena', 'lerato.organiser@raceday.test', 'HASH_SAMPLE_001', '0711111111'),
((SELECT role_id FROM dbo.Roles WHERE role_name = 'Organiser'),
 'Thabo', 'Dlamini', 'thabo.organiser@raceday.test', 'HASH_SAMPLE_002', '0722222222'),
((SELECT role_id FROM dbo.Roles WHERE role_name = 'Participant'),
 'Omphemetse', 'Mabone', 'omphemetse.participant@raceday.test', 'HASH_SAMPLE_003', '0733333333'),
((SELECT role_id FROM dbo.Roles WHERE role_name = 'Participant'),
 'Naledi', 'Molefe', 'naledi.participant@raceday.test', 'HASH_SAMPLE_004', '0744444444');
GO

-- Event categories.
INSERT INTO dbo.Categories (category_name, description)
VALUES
('Road Race', 'Road-running events'),
('Trail Run', 'Off-road running events'),
('Cycling', 'Cycling and road cycling events');
GO

-- At least three events.
INSERT INTO dbo.Events
    (organizer_id, category_id, event_name, description, location, event_date, capacity, entry_fee, status)
VALUES
(
 (SELECT user_id FROM dbo.Users WHERE email = 'lerato.organiser@raceday.test'),
 (SELECT category_id FROM dbo.Categories WHERE category_name = 'Road Race'),
 'Johannesburg City 10K',
 'A 10 kilometre city road race.',
 'Johannesburg, Gauteng',
 '2026-10-10 07:00:00',
 500,
 120.00,
 'Open'
),
(
 (SELECT user_id FROM dbo.Users WHERE email = 'thabo.organiser@raceday.test'),
 (SELECT category_id FROM dbo.Categories WHERE category_name = 'Trail Run'),
 'Magaliesberg Trail Challenge',
 'A scenic trail-running challenge.',
 'Magaliesberg, Gauteng',
 '2026-11-14 06:30:00',
 250,
 180.00,
 'Open'
),
(
 (SELECT user_id FROM dbo.Users WHERE email = 'lerato.organiser@raceday.test'),
 (SELECT category_id FROM dbo.Categories WHERE category_name = 'Cycling'),
 'Pretoria Cycle Classic',
 'A community cycling event.',
 'Pretoria, Gauteng',
 '2026-12-05 06:00:00',
 400,
 220.00,
 'Open'
);
GO

-- Enrolments.
INSERT INTO dbo.Enrolments
    (event_id, participant_id, status, emergency_contact, emergency_phone)
VALUES
(
 (SELECT event_id FROM dbo.Events WHERE event_name = 'Johannesburg City 10K'),
 (SELECT user_id FROM dbo.Users WHERE email = 'omphemetse.participant@raceday.test'),
 'Confirmed', 'Kagiso Mabone', '0755555555'
),
(
 (SELECT event_id FROM dbo.Events WHERE event_name = 'Johannesburg City 10K'),
 (SELECT user_id FROM dbo.Users WHERE email = 'naledi.participant@raceday.test'),
 'Confirmed', 'Mpho Molefe', '0766666666'
),
(
 (SELECT event_id FROM dbo.Events WHERE event_name = 'Magaliesberg Trail Challenge'),
 (SELECT user_id FROM dbo.Users WHERE email = 'omphemetse.participant@raceday.test'),
 'Confirmed', 'Kagiso Mabone', '0755555555'
);
GO

-- Results for completed/recorded enrolments.
INSERT INTO dbo.Results
    (enrolment_id, finish_position, finish_time_seconds, score, result_status)
VALUES
(
 (SELECT e.enrolment_id
  FROM dbo.Enrolments e
  JOIN dbo.Events ev ON ev.event_id = e.event_id
  JOIN dbo.Users u ON u.user_id = e.participant_id
  WHERE ev.event_name = 'Johannesburg City 10K'
    AND u.email = 'omphemetse.participant@raceday.test'),
 12, 3245.50, 88.00, 'Recorded'
),
(
 (SELECT e.enrolment_id
  FROM dbo.Enrolments e
  JOIN dbo.Events ev ON ev.event_id = e.event_id
  JOIN dbo.Users u ON u.user_id = e.participant_id
  WHERE ev.event_name = 'Johannesburg City 10K'
    AND u.email = 'naledi.participant@raceday.test'),
 18, 3412.25, 82.00, 'Recorded'
);
GO

-- Verification queries for SSMS.
SELECT * FROM dbo.Roles;
SELECT * FROM dbo.Users;
SELECT * FROM dbo.Categories;
SELECT * FROM dbo.Events;
SELECT * FROM dbo.Enrolments;
SELECT * FROM dbo.Results;
GO
