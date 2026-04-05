import mysql.connector
from mysql.connector import Error
import hashlib
import datetime
import random
import json

def get_db_connection():
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='Sara@123',
            database='secure_attendance'
        )
        return connection
    except Error as e:
        print(f"Error: {e}")
        return None

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def seed_data():
    conn = get_db_connection()
    if not conn:
        return
    
    cursor = conn.cursor()
    
    try:
        # Clear existing data for a fresh start (Optional, but good for demo)
        print("🧹 Cleaning up existing data...")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        tables = ['audit_logs', 'fraud_logs', 'attendance_records', 'sessions', 'students', 'teachers', 'users']
        for table in tables:
            cursor.execute(f"TRUNCATE TABLE {table}")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

        # 1. Seed Users
        print("👤 Seeding Users...")
        users = [
            ('ADMIN', 'System Admin', 'admin', 'IT', 'DEV-001', hash_password('Admin123')),
            ('T101', 'Sara Firdose', 'teacher', 'Computer Science', 'DEV-T101', hash_password('Teacher123')),
            ('S101', 'Arjun Kumar', 'student', 'Computer Science', 'DEV-S101', hash_password('Student123')),
            ('S102', 'Priya Sharma', 'student', 'Computer Science', 'DEV-S102', hash_password('Student123')),
            ('S103', 'Rahul Verma', 'student', 'Computer Science', 'DEV-S103', hash_password('Student123')),
        ]
        cursor.executemany("INSERT INTO users (uid, name, role, department, device_id, password_hash) VALUES (%s, %s, %s, %s, %s, %s)", users)

        # 2. Seed Teacher Metadata
        print("👨‍🏫 Seeding Teacher Metadata...")
        cursor.execute("INSERT INTO teachers (teacher_id, subjects, assigned_classes) VALUES (%s, %s, %s)", 
                       ('T101', json.dumps(['Cloud Computing', 'Machine Learning', 'Cyber Security']), 
                        json.dumps(['CSE-3-A', 'CSE-4-B'])))

        # 3. Seed Student Metadata
        print("🎓 Seeding Student Metadata...")
        students = [
            ('S101', '2022045', '3rd', '6th', 'A', 'CSE'),
            ('S102', '2022046', '3rd', '6th', 'A', 'CSE'),
            ('S103', '2022047', '3rd', '6th', 'A', 'CSE'),
        ]
        cursor.executemany("INSERT INTO students (student_id, roll_number, year, semester, section, department) VALUES (%s, %s, %s, %s, %s, %s)", students)

        # 4. Seed Sessions & Attendance (Last 30 Days)
        print("📅 Seeding 30 days of Historical Data...")
        subjects = ['Cloud Computing', 'Machine Learning']
        start_date = datetime.datetime.now() - datetime.timedelta(days=30)
        
        for i in range(30):
            current_date = start_date + datetime.timedelta(days=i)
            # Skip weekends
            if current_date.weekday() >= 5:
                continue
            
            for subject in subjects:
                session_id = f"SESS-{current_date.strftime('%Y%m%d')}-{subject.replace(' ', '')}"
                start_time = current_date.replace(hour=10 + subjects.index(subject), minute=0, second=0)
                
                cursor.execute("INSERT INTO sessions (session_id, teacher_id, subject, class_label, start_time, status) VALUES (%s, %s, %s, %s, %s, %s)",
                               (session_id, 'T101', subject, 'CSE-3-A', start_time, 'completed'))
                
                # Seed Attendance Records for students
                # S101 (Arjun): Declining (Present 100% first 10 days, then 50% next 10 days, then 0% last 10 days)
                # S102 (Priya): Improving (0% first 10, 50% next 10, 100% last 10)
                # S103 (Rahul): Constant (80% always)
                
                attendance = []
                # Arjun
                if i < 10: status_arjun = 'present'
                elif i < 20: status_arjun = 'present' if random.random() > 0.5 else 'absent'
                else: status_arjun = 'absent'
                
                # Priya
                if i < 10: status_priya = 'absent'
                elif i < 20: status_priya = 'present' if random.random() > 0.5 else 'absent'
                else: status_priya = 'present'
                
                # Rahul
                status_rahul = 'present' if random.random() < 0.8 else 'absent'
                
                # Add records
                if status_arjun == 'present':
                    attendance.append((session_id, 'S101', '2022045', 'present', start_time))
                if status_priya == 'present':
                    attendance.append((session_id, 'S102', '2022046', 'present', start_time))
                if status_rahul == 'present':
                    attendance.append((session_id, 'S103', '2022047', 'present', start_time))
                
                if attendance:
                    cursor.executemany("INSERT INTO attendance_records (session_id, student_id, roll_number, status, timestamp) VALUES (%s, %s, %s, %s, %s)", attendance)

        conn.commit()
        print("✅ Seeding Complete! Data ready for AI analysis.")

    except Error as e:
        print(f"❌ Error seeding database: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    seed_data()
