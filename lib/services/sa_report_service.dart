import '../models/session_model.dart';
import 'session_service.dart';

class SaReportService {
  // ── Step 4: Cross-Sectional Export ──────────────────────────────────────────
  static Future<Map<String, dynamic>> generateExportData({
    required ExportType type,
    String? subject,
    String? classLabel,
    String? studentRoll,
  }) async {
    final allSessions = await SessionService.getPastSessions();
    List<AttendanceSession> filtered;

    switch (type) {
      case ExportType.subject:
        filtered = allSessions.where((AttendanceSession s) => s.subject == subject).toList();
        break;
      case ExportType.section:
        filtered = allSessions.where((AttendanceSession s) => s.classLabel == classLabel).toList();
        break;
      case ExportType.student:
        filtered = allSessions.where((AttendanceSession s) => s.students.any((e) => e.rollNumber == studentRoll)).toList();
        break;
      default:
        filtered = allSessions;
    }

    if (filtered.isEmpty) return {'error': 'No data found for selection'};

    // Simulated Export Logic
    final exportBlob = {
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'entityType': type.name,
        'aiSummary': _generateAiSummary(filtered),
      },
      'data': filtered.map((s) => s.toJson()).toList(),
    };

    return exportBlob;
  }

  static String _generateAiSummary(List<AttendanceSession> sessions) {
    if (sessions.isEmpty) return 'No context available.';
    
    // Simple heuristic summary
    final avg = sessions.map((s) => s.presentPercentage).reduce((a, b) => a + b) / sessions.length;
    if (avg < 75) return 'AI NOTICE: Average attendance is below 75%. Urgent intervention required.';
    if (avg > 90) return 'AI INSIGHT: High engagement detected. Peer-led sessions recommended.';
    
    return 'University compliance within normal levels.';
  }
}

enum ExportType {
  student,
  subject,
  section,
  faculty,
}
