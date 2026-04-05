import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session_model.dart';
import 'network_service.dart';

class AnalyticsAIService {
  /// Detects students below the 75% threshold in the filtered data.
  static List<Map<String, dynamic>> detectRisks(List<Map<String, dynamic>> studentStats) {
    return studentStats.where((s) => (s['percentage'] as double) < 75.0).toList();
  }

  /// Analyzes the attendance trend for a specific subject/semester.
  /// Compares the last 3 sessions with the 3 sessions before them.
  static String analyzeTrend(List<AttendanceSession> sessions) {
    if (sessions.length < 4) return 'Irregular (Not enough segments)';

    final recent = sessions.take(3).toList();
    final older = sessions.skip(3).take(3).toList();

    double getAvg(List<AttendanceSession> sessList) {
      int total = 0, present = 0;
      for (var s in sessList) {
        present += s.presentCount + s.lateCount;
        total += s.students.length;
      }
      return total > 0 ? (present / total) : 0.0;
    }

    final recentAvg = getAvg(recent);
    final olderAvg = getAvg(older);
    final diff = recentAvg - olderAvg;

    if (diff > 0.05) return 'Improving ↑';
    if (diff < -0.05) return 'Declining ↓';
    return 'Stable';
  }

  /// Calculates how many consecutive classes a student needs to reach 75%.
  static int classesToReach75(int attended, int total) {
    if (total == 0) return 3; // Default suggestion
    double target = 0.75;
    if (attended / total >= target) return 0;

    // Formula: (A + X) / (T + X) >= 0.75  =>  X >= 3T - 4A
    int needed = (3 * total) - (4 * attended);
    return needed > 0 ? needed : 0;
  }

  /// Generates a list of intelligent insights based on the filtered data.
  static List<Map<String, dynamic>> generateInsights({
    required List<AttendanceSession> sessions,
    required List<Map<String, dynamic>> studentStats,
    String? subject,
    String? semester,
  }) {
    final insights = <Map<String, dynamic>>[];
    final risks = detectRisks(studentStats);
    
    // Insight 1: Risk Volume
    if (risks.isNotEmpty) {
      insights.add({
        'type': 'risk',
        'title': '${risks.length} students at risk',
        'message': 'They are currently below 75% in ${subject ?? "this view"}.',
        'isCritical': true,
      });
    }

    // Insight 2: Trend
    final trend = analyzeTrend(sessions);
    insights.add({
      'type': 'trend',
      'title': 'Attendance is $trend',
      'message': _getTrendMessage(trend),
      'isCritical': trend.contains('Declining'),
    });

    // Insight 3: Subject Consistency
    if (subject != null && sessions.isNotEmpty) {
      final stdDev = _calculateConsistency(sessions);
      if (stdDev < 5.0) {
        insights.add({
          'type': 'consistency',
          'title': 'High Consistency',
          'message': '$subject has very stable attendance patterns.',
          'isCritical': false,
        });
      }
    }

    return insights;
  }

  static String _getTrendMessage(String trend) {
    if (trend.contains('Improving')) return 'Participation is increasing compared to last month.';
    if (trend.contains('Declining')) return 'Participation is dropping. Consider sending reminders.';
    return 'Attendance remains steady across sessions.';
  }

  static double _calculateConsistency(List<AttendanceSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    final rates = sessions.map((s) => s.students.isEmpty ? 0.0 : ((s.presentCount + s.lateCount) / s.students.length) * 100).toList();
    final avg = rates.reduce((a, b) => a + b) / rates.length;
    final variance = rates.map((r) => (r - avg) * (r - avg)).reduce((a, b) => a + b) / rates.length;
    return List.from(rates).isEmpty ? 0.0 : variance / rates.length; // Placeholder for simplified SD
  }

  /// Fetches AI prediction for a specific student (used by BackgroundSyncService).
  /// Delegates to the backend /ai-predict endpoint via StudentService.
  static Future<Map<String, dynamic>> getStudentAIPrediction(String uid) async {
    try {
      final res = await http.get(
        Uri.parse('${NetworkService.baseUrl}/ai-predict?uid=$uid'),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'risk': 'Unknown',
      'explanation': 'Unable to reach AI engine.',
      'confidence': 0,
    };
  }
}
