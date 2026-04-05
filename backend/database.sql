-- SecureAttend Centralized MySQL Schema
-- Optimized for Real-time Sync, JWT Auth, and Fraud Detection

CREATE DATABASE IF NOT EXISTS secure_attendance;
USE secure_attendance;

-- 1. Users Table (Core Identity)
CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(128) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    role ENUM('student', 'teacher', 'admin') NOT NULL,
    department VARCHAR(100),
    device_id VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    is_blocked BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX (role),
    INDEX (device_id)
);

-- 2. Teacher Metadata (Extends Users)
CREATE TABLE IF NOT EXISTS teachers (
    teacher_id VARCHAR(128) PRIMARY KEY,
    subjects TEXT, -- JSON array of strings
    assigned_classes TEXT, -- JSON array of "Dept-Year-Sec"
    FOREIGN KEY (teacher_id) REFERENCES users(uid) ON DELETE CASCADE
);

-- 3. Student Metadata (Extends Users)
CREATE TABLE IF NOT EXISTS students (
    student_id VARCHAR(128) PRIMARY KEY,
    roll_number VARCHAR(50) UNIQUE NOT NULL,
    year VARCHAR(10),
    semester VARCHAR(10),
    section VARCHAR(10),
    department VARCHAR(100),
    FOREIGN KEY (student_id) REFERENCES users(uid) ON DELETE CASCADE,
    INDEX (roll_number),
    INDEX (department, year, section)
);

-- 4. Attendance Sessions (Teacher generated)
CREATE TABLE IF NOT EXISTS sessions (
    session_id VARCHAR(128) PRIMARY KEY,
    teacher_id VARCHAR(128),
    subject VARCHAR(255) NOT NULL,
    class_label VARCHAR(100) NOT NULL, -- "CSE-3-A"
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    ssid VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES users(uid) ON DELETE SET NULL,
    INDEX (status),
    INDEX (class_label)
);

-- 5. Attendance Records (Student marking)
CREATE TABLE IF NOT EXISTS attendance_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(128),
    student_id VARCHAR(128),
    roll_number VARCHAR(50),
    status ENUM('present', 'late', 'absent') DEFAULT 'present',
    device_id VARCHAR(255),
    device_ip VARCHAR(50),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_synced BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES users(uid) ON DELETE CASCADE,
    UNIQUE KEY (session_id, student_id), -- Prevent duplicate attendance
    INDEX (roll_number)
);

-- 6. Fraud & Security Logs
CREATE TABLE IF NOT EXISTS fraud_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(128),
    session_id VARCHAR(128),
    reason VARCHAR(255) NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(uid) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id) ON DELETE SET NULL
);

-- 7. System Audit Trails (Admin view)
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(128),
    action VARCHAR(100) NOT NULL,
    description TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(uid) ON DELETE SET NULL
);
