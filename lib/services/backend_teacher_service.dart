import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teacher_model.dart';

class BackendTeacherService {
  static const _teachersKey = 'sa_backend_teachers';

  static Future<TeacherModel?> getTeacherProfile(String deviceID) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_teachersKey) ?? [];
    
    for (String t in raw) {
      final teacher = TeacherModel.fromJson(jsonDecode(t));
      if (teacher.deviceID == deviceID) {
        return teacher;
      }
    }
    return null;
  }

  static Future<List<String>> getAssignedSubjects(String deviceID) async {
    final profile = await getTeacherProfile(deviceID);
    return profile?.subjects ?? [];
  }

  static Future<List<String>> getAssignedClasses(String deviceID) async {
    final profile = await getTeacherProfile(deviceID);
    return profile?.assignedClasses ?? [];
  }

  static Future<String?> getSmartSuggestion(String deviceID) async {
    final assigned = await getAssignedClasses(deviceID);
    if (assigned.isNotEmpty) {
      return "Start attendance session for ${assigned.first}";
    }
    return null;
  }
}
