------------------------------------------------------------
-- CSE 111 PHASE 2: SQL Query Script
-- Author: Kris Pichon
-- File: queries.sql
------------------------------------------------------------

------------------------------------------------------------
-- BASIC SELECTS
------------------------------------------------------------

-- 1. List all conferences
SELECT * FROM Conference;

-- 2. List all sessions with their conference names
SELECT c.name AS conference, s.title
FROM Session s
JOIN Conference c ON c.conference_id = s.conference_id;

-- 3. List all rooms with capacity
SELECT name, capacity FROM Room;

-- 4. Show all room schedules with room names
SELECT r.name, rs."date", rs.start_time, rs.end_time, rs.status
FROM Room r
JOIN RoomSchedule rs ON r.room_id = rs.room_id;

-- 5. Show all speakers for each session
SELECT s.title, sp.name AS speaker
FROM Session s
JOIN SpeakerAssignment sa ON s.session_id = sa.session_id
JOIN Speaker sp ON sa.speaker_id = sp.speaker_id;

------------------------------------------------------------
-- FILTERS AND AGGREGATION
------------------------------------------------------------

-- 6. Count sessions per conference
SELECT c.name, COUNT(s.session_id) AS session_count
FROM Conference c
LEFT JOIN Session s ON c.conference_id = s.conference_id
GROUP BY c.conference_id, c.name;

-- 7. Rooms with capacity over 100
SELECT name FROM Room WHERE capacity > 100;

-- 8. All available room slots
SELECT * FROM RoomSchedule WHERE status = 'Available';

-- 9. Speakers from Berlin
SELECT name FROM Speaker WHERE affiliation LIKE '%Berlin%';

-- 10. Log entries grouped by user
SELECT "user", COUNT(*) AS entries
FROM LogEntry
GROUP BY "user";

------------------------------------------------------------
-- INSERT / UPDATE / DELETE (MODIFICATION QUERIES)
-- (made idempotent to avoid UNIQUE constraint errors)
------------------------------------------------------------

-- 11. Insert a new conference (only if not already present)
INSERT INTO Conference (name, location, start_date, end_date)
SELECT 'CyberTech Expo', 'Tokyo', '2025-11-20', '2025-11-23'
WHERE NOT EXISTS (
  SELECT 1 FROM Conference
  WHERE name = 'CyberTech Expo' AND start_date = '2025-11-20'
);

-- 12. Update a room schedule status
UPDATE RoomSchedule SET status = 'Reserved' WHERE schedule_id = 2;

-- 13. Add a new speaker (only if email not present)
INSERT INTO Speaker (name, email, affiliation)
SELECT 'Ava Richardson', 'ava.richardson@cyber.org', 'Cyber University'
WHERE NOT EXISTS (
  SELECT 1 FROM Speaker WHERE email = 'ava.richardson@cyber.org'
);

-- 14. Delete a speaker who withdrew
DELETE FROM Speaker WHERE speaker_id = 4;

-- 15. Insert a log entry (always insert a log)
INSERT INTO LogEntry ("user", action, entity_affected)
VALUES ('Admin', 'Speaker withdrawn', 'Speaker');

------------------------------------------------------------
-- COMPLEX QUERIES (JOINS, NESTED, ETC.)
------------------------------------------------------------

-- 16. Find all sessions scheduled in 'Hall A'
SELECT s.title
FROM Session s
JOIN SessionRoomAssignment sra ON s.session_id = sra.session_id
JOIN RoomSchedule rs ON rs.schedule_id = sra.schedule_id
JOIN Room r ON r.room_id = rs.room_id
WHERE r.name = 'Hall A';

-- 17. Find sessions with no assigned speakers
SELECT title FROM Session
WHERE session_id NOT IN (SELECT session_id FROM SpeakerAssignment);

-- 18. List all scheduled sessions with conference, room, date/time
SELECT c.name AS conference, s.title AS session, r.name AS room,
       rs."date", rs.start_time, rs.end_time
FROM Session s
JOIN Conference c ON s.conference_id = c.conference_id
JOIN SessionRoomAssignment sra ON s.session_id = sra.session_id
JOIN RoomSchedule rs ON rs.schedule_id = sra.schedule_id
JOIN Room r ON r.room_id = rs.room_id;

-- 19. Transaction-safe update
BEGIN TRANSACTION;
UPDATE RoomSchedule SET status = 'Reserved' WHERE schedule_id = 3;
INSERT INTO LogEntry ("user", action, entity_affected)
VALUES ('Scheduler', 'Reserved Room Slot 3', 'RoomSchedule');
COMMIT;

-- 20. Delete completed room schedules older than a date
DELETE FROM RoomSchedule
WHERE status = 'Completed' AND "date" < '2025-05-01';
