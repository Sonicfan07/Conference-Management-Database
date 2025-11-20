------------------------------------------------------------
-- CSE 111 PHASE 2: Conference Management Database Schema
-- Author: Kris Pichon
-- File: conference_database.sql
------------------------------------------------------------

------------------------------------------------------------
-- TABLE: Conference
------------------------------------------------------------
CREATE TABLE Conference (
    conference_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    start_date DATE,
    end_date DATE
);

------------------------------------------------------------
-- TABLE: Session
------------------------------------------------------------
CREATE TABLE Session (
    session_id INTEGER PRIMARY KEY,
    conference_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    FOREIGN KEY (conference_id) REFERENCES Conference(conference_id)
);

------------------------------------------------------------
-- TABLE: Room
------------------------------------------------------------
CREATE TABLE Room (
    room_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    capacity INTEGER
);

------------------------------------------------------------
-- TABLE: RoomSchedule (independent time slots)
------------------------------------------------------------
CREATE TABLE RoomSchedule (
    schedule_id INTEGER PRIMARY KEY,
    room_id INTEGER NOT NULL,
    date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    status TEXT CHECK(status IN ('Available', 'Reserved', 'Completed')),
    FOREIGN KEY (room_id) REFERENCES Room(room_id)
);

------------------------------------------------------------
-- TABLE: SessionRoomAssignment (bridge for Session ↔ RoomSchedule)
------------------------------------------------------------
CREATE TABLE SessionRoomAssignment (
    session_id INTEGER,
    schedule_id INTEGER,
    PRIMARY KEY (session_id, schedule_id),
    FOREIGN KEY (session_id) REFERENCES Session(session_id),
    FOREIGN KEY (schedule_id) REFERENCES RoomSchedule(schedule_id)
);

------------------------------------------------------------
-- TABLE: Speaker
------------------------------------------------------------
CREATE TABLE Speaker (
    speaker_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    affiliation TEXT
);

------------------------------------------------------------
-- TABLE: SpeakerAssignment (bridge for Session ↔ Speaker)
------------------------------------------------------------
CREATE TABLE SpeakerAssignment (
    session_id INTEGER,
    speaker_id INTEGER,
    PRIMARY KEY (session_id, speaker_id),
    FOREIGN KEY (session_id) REFERENCES Session(session_id),
    FOREIGN KEY (speaker_id) REFERENCES Speaker(speaker_id)
);

------------------------------------------------------------
-- TABLE: LogEntry (system logging)
------------------------------------------------------------
CREATE TABLE LogEntry (
    log_id INTEGER PRIMARY KEY,
    user TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    action TEXT,
    entity_affected TEXT
);

------------------------------------------------------------
------------------------------------------------------------
-- INSERT SAMPLE DATA
------------------------------------------------------------

-- Conferences
INSERT INTO Conference VALUES 
(1, 'TechFuture 2025', 'San Francisco', '2025-05-10', '2025-05-13'),
(2, 'AI Global Summit', 'Berlin', '2025-09-02', '2025-09-05');

-- Sessions
INSERT INTO Session VALUES
(1, 1, 'Advances in Quantum AI'),
(2, 1, 'The Future of Cloud Systems'),
(3, 2, 'AI Policy and Ethics');

-- Rooms
INSERT INTO Room VALUES
(1, 'Hall A', 150),
(2, 'Hall B', 80),
(3, 'Main Auditorium', 300);

-- RoomSchedule slots
INSERT INTO RoomSchedule VALUES
(1, 1, '2025-05-10', '09:00', '11:00', 'Reserved'),
(2, 2, '2025-05-11', '11:00', '13:00', 'Available'),
(3, 3, '2025-09-03', '10:00', '12:00', 'Reserved');

-- SessionRoomAssignment
INSERT INTO SessionRoomAssignment VALUES
(1, 1),
(2, 2),
(3, 3);

-- Speakers
INSERT INTO Speaker VALUES
(1, 'Dr. Elena Fischer', 'elena.f@tech.edu', 'MIT'),
(2, 'Carlos Vega', 'cvega@aiworld.com', 'OpenAI'),
(3, 'Li Wei', 'liwei@berlin.ai', 'TU Berlin');

-- SpeakerAssignment
INSERT INTO SpeakerAssignment VALUES
(1, 1),
(2, 2),
(3, 3);

-- LogEntry
INSERT INTO LogEntry (log_id, user, action, entity_affected)
VALUES
(1, 'Admin', 'Inserted Session Data', 'Session'),
(2, 'Scheduler', 'Updated schedule status', 'RoomSchedule');
