import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teacher_model.dart';
import 'sa_admin_service.dart';

class OnboardingAIService {
  static const _statsKey = 'sa_ai_onboarding_stats';

  // ── Step 1: ID & Password Generation ───────────────────────────────────────
  static Future<String> generateTeacherId(String dept) async {
    final teachers = await SaAdminService.getTeachers();
    const year = "2026"; // Current Academic Year
    final deptCode = (dept.length >= 2) ? dept.substring(0, 2).toUpperCase() : dept.toUpperCase();
    
    int count = teachers.where((t) => t.department == dept).length + 1;
    String suggestedID = 'TCH-$deptCode-$year-${count.toString().padLeft(3, '0')}';

    // Collision Check
    while (teachers.any((t) => t.teacherId == suggestedID)) {
      count++;
      suggestedID = 'TCH-$deptCode-$year-${count.toString().padLeft(3, '0')}';
    }

    return suggestedID;
  }

  static String generatePassword() {
    const chars = 'AaBbCcDdEeFf1234567890@#\$%';
    final rnd = Random();
    return List.generate(8, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  static String suggestEmail(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().toLowerCase().split(' ');
    if (parts.length > 1) {
      return '${parts.first}.${parts.last}@college.edu';
    }
    return '${parts.first}@college.edu';
  }

  // ── Subject Intelligence (Frequency + Load Balancing) ──────────────────────
  static Future<List<Map<String, dynamic>>> suggestSubjects(String dept) async {
    final teachers = await SaAdminService.getTeachers();
    final stats = await _getStats();
    
    // 1. Get pool of subjects for this department
    final structure = await SaAdminService.getStructure();
    final List<String> allDeptSubs = List<String>.from(structure['subjects'] ?? ['DBMS', 'OS', 'SE', 'Networks', 'AI', 'ML', 'Cyber', 'Web']);

    // 2. Calculate Load (Teachers per subject)
    Map<String, int> subjectLoad = {};
    for (var s in allDeptSubs) {
      subjectLoad[s] = 0;
    }
    
    for (var t in teachers) {
      if (t.department == dept) {
        for (var s in t.subjects) {
          if (subjectLoad.containsKey(s)) {
            subjectLoad[s] = (subjectLoad[s] ?? 0) + 1;
          }
        }
      }
    }

    // 3. Calculate Global Popularity (Frequency of selection)
    Map<String, dynamic> freq = stats['frequency']?[dept] ?? {};

    // 4. Scoring Logic (Confidence)
    List<Map<String, dynamic>> scored = [];
    for (var s in allDeptSubs) {
      double popularityScore = (freq[s] ?? 0) / 10.0; // Normalized
      double balanceScore = subjectLoad[s] == 0 ? 1.0 : (1.0 / (subjectLoad[s]! + 1));
      
      double totalScore = (popularityScore * 0.4) + (balanceScore * 0.6);
      String reason = balanceScore > 0.5 ? "Prioritized for load balancing" : "Suggested based on department trends";
      
      scored.add({
        'subject': s,
        'score': totalScore.clamp(0.1, 0.95),
        'reason': reason,
      });
    }

    scored.sort((a, b) => b['score'].compareTo(a['score']));
    return scored.take(3).toList();
  }

  // ── Duplicate Detection ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> detectDuplicate(String name, String dept, String email) async {
    final teachers = await SaAdminService.getTeachers();
    for (var t in teachers) {
      if (t.name.toLowerCase() == name.toLowerCase() && t.department == dept) {
        return {'type': 'Existing Name', 'match': t.name};
      }
    }
    return null;
  }

  // ── Self Learning Loop ─────────────────────────────────────────────────────
  static Future<void> updateLearningStats(TeacherProfile teacher) async {
    final stats = await _getStats();
    final dept = teacher.department;
    
    if (stats['frequency'] == null) stats['frequency'] = {};
    if (stats['frequency'][dept] == null) stats['frequency'][dept] = {};
    
    for (var s in teacher.subjects) {
      stats['frequency'][dept][s] = (stats['frequency'][dept][s] ?? 0) + 1;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats));
  }

  static Future<Map<String, dynamic>> _getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null) return {};
    return jsonDecode(raw);
  }
}
