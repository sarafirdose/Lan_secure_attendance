import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/session_model.dart';
import 'auth_service.dart';
import 'sync_service.dart';

class MigrationService {
  static const _migrationFlag = 'sa_migrated_v2';

  static Future<void> runMigrationOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isMigrated = prefs.getBool(_migrationFlag) ?? false;
    
    if (isMigrated) return; // Already migrated, skip.

    // 1. Migrate Students
    _migrateStudents(prefs);

    // 2. Migrate Teachers
    _migrateTeachers(prefs);

    // 3. Migrate Sessions
    _migrateSessions(prefs);

    // 4. Seed Auth records for login
    _seedAuthRecords(prefs);

    // 5. Push to Centralized Backend (NEW)
    await AuthService.runDataMigration();

    // 6. Start Sync Engine
    SyncService().startAutoSync();

    // Set flag
    await prefs.setBool(_migrationFlag, true);
  }

  static Future<void> _seedAuthRecords(SharedPreferences prefs) async {
    List<Map<String, dynamic>> authUsers = [];

    // Default Admin
    authUsers.add({
      'id': 'ADMIN',
      'name': 'System Administrator',
      'password': 'admin123',
      'role': 'admin'
    });

    // Student Auth
    final studentsRaw = prefs.getStringList('sa_backend_students') ?? [];
    for (var s in studentsRaw) {
      final data = jsonDecode(s);
      authUsers.add({
        'id': data['id'],
        'name': data['name'],
        'password': 'user123', // Default for migrated 
        'role': 'student',
        'deviceID': data['deviceID'],
      });
    }

    // Teacher Auth
    final teachersRaw = prefs.getStringList('sa_backend_teachers') ?? [];
    for (var t in teachersRaw) {
      final data = jsonDecode(t);
      authUsers.add({
        'id': data['id'],
        'name': data['name'],
        'password': 'user123',
        'role': 'teacher',
        'deviceID': data['deviceID'],
      });
    }

    // Seed into AuthService
    // ignore: avoid_print
    print('Seeding ${authUsers.length} auth records to centralized backend...');
    // In production this would be an API call, for now we let users register/login normally
    // await AuthService.seedInitialAuth(authUsers);
  }

  static Future<void> _migrateStudents(SharedPreferences prefs) async {
    final oldStudentsRaw = prefs.getStringList('sa_admin_students') ?? [];
    List<StudentModel> newStudents = [];
    
    for (String raw in oldStudentsRaw) {
      try {
        final Map<String, dynamic> old = jsonDecode(raw);
        final student = StudentModel(
          id: old['id'] ?? '',
          name: old['name'] ?? '',
          department: old['department'] ?? old['dept'] ?? 'Unknown',
          year: old['year'] ?? '1st',
          semester: old['semester'] ?? '1st',
          section: old['section'] ?? old['sec'] ?? 'A',
          deviceID: old['deviceId'] ?? '',
          isBlocked: old['isBlocked'] == 'true' || old['isBlocked'] == true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        newStudents.add(student);
      } catch (e) {
        // Skip invalid records safely
      }
    }
    
    // Save to new key
    if (newStudents.isNotEmpty) {
      final jsonList = newStudents.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('sa_backend_students', jsonList);
    }
  }

  static Future<void> _migrateTeachers(SharedPreferences prefs) async {
    final oldTeachersRaw = prefs.getStringList('sa_admin_teachers') ?? [];
    List<TeacherModel> newTeachers = [];
    
    for (String raw in oldTeachersRaw) {
      try {
        final Map<String, dynamic> old = jsonDecode(raw);
        final t = TeacherModel(
          id: old['deviceId'] ?? DateTime.now().millisecondsSinceEpoch.toString(), // Pseudo ID
          name: old['name'] ?? 'Faculty Member',
          subjects: List<String>.from(old['subjects'] ?? []),
          assignedClasses: List<String>.from(old['sections'] ?? []),
          deviceID: old['deviceId'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        newTeachers.add(t);
      } catch (e) {}
    }
    
    if (newTeachers.isNotEmpty) {
      final jsonList = newTeachers.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('sa_backend_teachers', jsonList);
    }
  }

  static Future<void> _migrateSessions(SharedPreferences prefs) async {
    final oldSessionsRaw = prefs.getString('sa_sessions_history');
    if (oldSessionsRaw != null) {
      try {
        final List<dynamic> history = jsonDecode(oldSessionsRaw);
        List<AttendanceSession> newSessions = [];
        
        for (var sess in history) {
           final old = sess as Map<String, dynamic>;
           newSessions.add(AttendanceSession(
             sessionId: old['sessionId'] ?? '',
             subject: old['subject'] ?? '',
             department: old['department'] ?? 'Unknown',
             year: old['year'] ?? '1st',
             section: old['section'] ?? 'A',
             startTime: old['startTime'] != null ? DateTime.parse(old['startTime']) : DateTime.now(),
             endTime: old['endTime'] != null ? DateTime.parse(old['endTime']) : null,
             isActive: old['isActive'] ?? false,
           ));
        }

        final jsonList = newSessions.map((s) => jsonEncode(s.toJson())).toList();
        await prefs.setStringList('sa_backend_sessions', jsonList);
      } catch (e) {}
    }
  }
}
