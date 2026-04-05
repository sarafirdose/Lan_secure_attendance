import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teacher_model.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class TeacherService {
  static const _profileKey = 'sa_teacher_profile';
  static const _timetableKey = 'sa_teacher_timetable';

  // ── Teacher Profile ───────────────────────────────────────────────────────────
  static Future<TeacherProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return TeacherProfile.fromJson(jsonDecode(raw));
  }

  static Future<void> saveProfile(TeacherProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // ── Timetable ────────────────────────────────────────────────────────────────
  static Future<List<TimetableEntry>> getTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_timetableKey);
    if (raw == null) return [];
    return raw.map((e) => TimetableEntry.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> saveTimetable(List<TimetableEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_timetableKey, raw);
  }

  // ── Smart Context Detection (Step 2 & 4) ──────────────────────────────────
  static Future<TimetableEntry?> getCurrentSlot() async {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now); // e.g., "Monday"
    final timetable = await getTimetable();
    
    for (final entry in timetable) {
      if (entry.day != currentDay) continue;

      final startParts = entry.startTime.split(':');
      final endParts = entry.endTime.split(':');
      
      final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));

      // Use time tolerance: (startTime - 10 mins) to (endTime + 5 mins)
      final toleranceStart = start.subtract(const Duration(minutes: 10));
      final toleranceEnd = end.add(const Duration(minutes: 5));

      if (now.isAfter(toleranceStart) && now.isBefore(toleranceEnd)) {
        return entry;
      }
    }
    return null;
  }

  static Future<List<TimetableEntry>> getUpcomingClasses() async {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    final timetable = await getTimetable();
    
    final dayClasses = timetable.where((e) => e.day == currentDay).toList();
    
    // Simple filter: return all classes that haven't ended yet
    return dayClasses.where((e) {
      final endParts = e.endTime.split(':');
      final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
      return now.isBefore(end);
    }).toList();
  }

  // ── Security & Authorization (Step 7) ─────────────────────────────────────────
  static Future<bool> isAuthorized(String subject, String classLabel) async {
    final profile = await getProfile();
    if (profile == null) return false;

    // Check if subject is assigned
    final hasSubject = profile.subjects.contains(subject);
    
    // Check if class is assigned
    final classParts = classLabel.split('-'); // "DEP-YEAR-SEC"
    if (classParts.length < 3) return false;
    
    final hasClass = profile.sections.contains(classParts[2]) && 
                    profile.year == classParts[1] &&
                    profile.department == classParts[0];

    return hasSubject && hasClass;
  }

  static Future<String> generateDeviceId() async {
    // Generate a 6-character random alphanumeric string for simulation
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String id = '';
    for (int i = 0; i < 6; i++) {
        id += chars[(random + i) % chars.length];
    }
    return id;
  }

  // ── Notification Sync (Rule 4) ───────────────────────────────────────────
  static Future<void> syncNotificationReminders() async {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    final timetable = await getTimetable();
    
    final dayClasses = timetable.where((e) => e.day == currentDay).toList();
    final notificationService = NotificationService();

    // Reset current reminders to prevent orphans and duplicates
    await notificationService.cancelAll();
    
    for (int i = 0; i < dayClasses.length; i++) {
        final entry = dayClasses[i];
        final startParts = entry.startTime.split(':');
        final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));

        await notificationService.scheduleClassReminder(
           id: i * 100 + 200,
           subject: entry.subject,
           classTime: start,
        );
    }
  }
}
