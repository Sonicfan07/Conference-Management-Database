import sqlite3
from datetime import datetime
3
DB_PATH = "conference.db"


def get_connection():
    return sqlite3.connect(DB_PATH)


# ---------- HELPER PRINTS ----------

def print_header(title):
    print("\n" + "=" * 60)
    print(title)
    print("=" * 60)


def print_row(row):
    print(" | ".join(str(x) for x in row))


# ---------- MENU OPERATIONS ----------

def list_conferences():
    print_header("All Conferences")
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("SELECT conference_id, name, location, start_date, end_date FROM Conference")
        rows = cur.fetchall()
    if not rows:
        print("No conferences found.")
        return
    for row in rows:
        print_row(row)


def view_sessions_for_conference():
    list_conferences()
    try:
        conf_id = int(input("\nEnter conference_id to view its sessions: ").strip())
    except ValueError:
        print("Invalid conference_id.")
        return

    print_header(f"Sessions for Conference {conf_id}")
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT s.session_id, s.title
            FROM Session s
            WHERE s.conference_id = ?
        """, (conf_id,))
        rows = cur.fetchall()
    if not rows:
        print("No sessions found for this conference.")
        return
    for row in rows:
        print_row(row)


def view_room_schedule_by_date():
    date_str = input("Enter date (YYYY-MM-DD): ").strip()
    # no strict validation, but we can try to parse:
    try:
        datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        print("Invalid date format.")
        return

    print_header(f"Room Schedule for {date_str}")
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT rs.schedule_id, r.name, rs.start_time, rs.end_time, rs.status
            FROM RoomSchedule rs
            JOIN Room r ON rs.room_id = r.room_id
            WHERE rs.date = ?
            ORDER BY rs.start_time
        """, (date_str,))
        rows = cur.fetchall()
    if not rows:
        print("No schedules found for that date.")
        return
    print("schedule_id | room | start_time | end_time | status")
    for row in rows:
        print_row(row)


def add_new_session():
    list_conferences()
    try:
        conf_id = int(input("\nEnter conference_id to attach the new session to: ").strip())
    except ValueError:
        print("Invalid conference_id.")
        return
    title = input("Enter session title: ").strip()
    if not title:
        print("Title cannot be empty.")
        return

    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO Session (session_id, conference_id, title)
            VALUES (
                COALESCE((SELECT MAX(session_id) + 1 FROM Session), 1),
                ?, ?
            )
        """, (conf_id, title))
        conn.commit()
    print("New session created successfully.")


def list_sessions():
    print_header("All Sessions")
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("SELECT session_id, title, conference_id FROM Session")
        rows = cur.fetchall()
    if not rows:
        print("No sessions found.")
        return
    print("session_id | title | conference_id")
    for row in rows:
        print_row(row)


def list_speakers():
    print_header("All Speakers")
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("SELECT speaker_id, name, affiliation FROM Speaker")
        rows = cur.fetchall()
    if not rows:
        print("No speakers found.")
        return
    print("speaker_id | name | affiliation")
    for row in rows:
        print_row(row)


def assign_speaker_to_session():
    list_sessions()
    try:
        session_id = int(input("\nEnter session_id to assign a speaker to: ").strip())
    except ValueError:
        print("Invalid session_id.")
        return

    list_speakers()
    try:
        speaker_id = int(input("\nEnter speaker_id to assign: ").strip())
    except ValueError:
        print("Invalid speaker_id.")
        return

    with get_connection() as conn:
        cur = conn.cursor()
        try:
            cur.execute("""
                INSERT INTO SpeakerAssignment (session_id, speaker_id)
                VALUES (?, ?)
            """, (session_id, speaker_id))
            conn.commit()
            print("Speaker successfully assigned to session.")
        except sqlite3.IntegrityError:
            print("This assignment already exists or invalid IDs were provided.")


def list_room_schedules():
    print_header("All Room Schedules")
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT rs.schedule_id, r.name, rs.date, rs.start_time, rs.end_time, rs.status
            FROM RoomSchedule rs
            JOIN Room r ON rs.room_id = r.room_id
            ORDER BY rs.date, rs.start_time
        """)
        rows = cur.fetchall()
    if not rows:
        print("No schedules found.")
        return
    print("schedule_id | room | date | start_time | end_time | status")
    for row in rows:
        print_row(row)


def assign_session_to_schedule():
    list_sessions()
    try:
        session_id = int(input("\nEnter session_id to schedule: ").strip())
    except ValueError:
        print("Invalid session_id.")
        return

    list_room_schedules()
    try:
        schedule_id = int(input("\nEnter schedule_id (time slot) to assign this session to: ").strip())
    except ValueError:
        print("Invalid schedule_id.")
        return

    with get_connection() as conn:
        cur = conn.cursor()
        try:
            cur.execute("""
                INSERT INTO SessionRoomAssignment (session_id, schedule_id)
                VALUES (?, ?)
            """, (session_id, schedule_id))
            conn.commit()
            print("Session assigned to schedule slot successfully.")
        except sqlite3.IntegrityError:
            print("This session is already assigned to that schedule or IDs are invalid.")


def update_schedule_status():
    list_room_schedules()
    try:
        schedule_id = int(input("\nEnter schedule_id to update: ").strip())
    except ValueError:
        print("Invalid schedule_id.")
        return

    new_status = input("Enter new status (Available / Reserved / Completed): ").strip()
    if new_status not in ("Available", "Reserved", "Completed"):
        print("Invalid status.")
        return

    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            UPDATE RoomSchedule
            SET status = ?
            WHERE schedule_id = ?
        """, (new_status, schedule_id))
        conn.commit()

        # Log the update
        cur.execute("""
            INSERT INTO LogEntry (user, action, entity_affected)
            VALUES (?, ?, ?)
        """, ("Scheduler", f"Updated schedule {schedule_id} to {new_status}", "RoomSchedule"))
        conn.commit()

    print("Schedule status updated and logged.")
9

def delete_session():
    list_sessions()
    try:
        session_id = int(input("\nEnter session_id to delete: ").strip())
    except ValueError:
        print("Invalid session_id.")
        return

    confirm = input(f"Are you sure you want to delete session {session_id}? (y/n): ").strip().lower()
    if confirm != "y":
        print("Delete cancelled.")
        return

    with get_connection() as conn:
        cur = conn.cursor()

        # First remove many-to-many relationships
        cur.execute("DELETE FROM SessionRoomAssignment WHERE session_id = ?", (session_id,))
        cur.execute("DELETE FROM SpeakerAssignment WHERE session_id = ?", (session_id,))

        # Then delete the session itself
        cur.execute("DELETE FROM Session WHERE session_id = ?", (session_id,))
        conn.commit()

        if cur.rowcount == 0:
            print("No session found with that ID.")
        else:
            print(f"Session {session_id} and its related assignments were deleted.")


def view_logs():
    print_header("Log Entries")
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT log_id, user, timestamp, action, entity_affected
            FROM LogEntry
            ORDER BY timestamp DESC
        """)
        rows = cur.fetchall()
    if not rows:
        print("No log entries found.")
        return
    print("log_id | user | timestamp | action | entity_affected")
    for row in rows:
        print_row(row)


# ---------- MAIN MENU LOOP ----------

def main_menu():
    while True:
        print_header("Conference Management System - Main Menu")
        print("1. List all conferences")
        print("2. View sessions for a conference")
        print("3. View room schedule by date")
        print("4. Add a new session")
        print("5. Assign speaker to a session")
        print("6. Assign session to a room schedule slot")
        print("7. Update room schedule status")
        print("8. View log entries")
        print("9. Delete a session")
        print("10. Exit")


        choice = input("\nSelect an option (1-10): ").strip()

        if choice == "1":
            list_conferences()
        elif choice == "2":
            view_sessions_for_conference()
        elif choice == "3":
            view_room_schedule_by_date()
        elif choice == "4":
            add_new_session()
        elif choice == "5":
            assign_speaker_to_session()
        elif choice == "6":
            assign_session_to_schedule()
        elif choice == "7":
            update_schedule_status()
        elif choice == "8":
            view_logs()
        elif choice == "9":
            delete_session()
        elif choice == "10":
            print("Exiting application.")
            break
        else:
            print("Invalid option, please try again.")



if __name__ == "__main__":
    main_menu()
