import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../services/api_service.dart';

class StudentRepository {
  static const String _storageKey = 'cached_students_repo';

  static Future<List<StudentModel>> getAllStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getString(_storageKey);
    
    if (localData != null) {
        final List<dynamic> jsonList = jsonDecode(localData);
        return jsonList.map((e) => StudentModel.fromJson(e)).toList();
    }

    // If no local data, fetch from API then cache
    final remoteData = await ApiService.fetchStudents();
    final students = remoteData.map((e) => StudentModel.fromJson(e)).toList();
    
    await prefs.setString(_storageKey, jsonEncode(remoteData));
    return students;
  }
}

class TeacherRepository {
  static const String _storageKey = 'cached_teachers_repo';

  static Future<TeacherModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getString(_storageKey);
    
    if (localData != null) {
        return TeacherModel.fromJson(jsonDecode(localData));
    }
    return null; // Force setup or fetch from mock
  }

  static Future<void> saveProfile(TeacherModel teacher) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(teacher.toJson()));
  }
}
