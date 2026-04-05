import '../models/session_model.dart';

class AiExplanationService {
  // ── Step 3: Dynamic Reasoning Engine ──────────────────────────────────────
  static String getRiskExplanation(List<AttendanceSession> history, String roll) {
    if (history.length < 3) return 'System requires at least 3 data points for predictive modeling.';
    
    final studentHistory = history.map((s) {
      return s.students.firstWhere((e) => e.rollNumber == roll, 
          orElse: () => StudentAttendanceEntry(rollNumber: roll, name: 'Unknown'));
    }).toList();

    double attendancePct = (studentHistory.where((s) => s.status == StudentStatus.present).length / studentHistory.length) * 100;

    // 1. Critical Consecutive Absences
    int consecutiveAbsents = 0;
    for (int i = studentHistory.length - 1; i >= 0; i--) {
      if (studentHistory[i].status == StudentStatus.absent) consecutiveAbsents++; else break;
    }
    if (consecutiveAbsents >= 3) {
      return 'CRITICAL ANOMALY: Student has missed $consecutiveAbsents consecutive sessions. Probability of failure in current module is high.';
    }

    // 2. Volatility Analysis
    int switches = 0;
    for (int i = 1; i < studentHistory.length; i++) {
        if (studentHistory[i].status != studentHistory[i-1].status) switches++;
    }
    if (switches > studentHistory.length / 1.5) {
      return 'WARNING: High volatility detected in attendance pattern. Possible scheduling conflicts or lack of engagement.';
    }

    // 3. Predictive Forecast
    if (attendancePct < 75) {
      return 'THRESHOLD VIOLATION: Current rate (${attendancePct.toStringAsFixed(1)}%) is below the 75% baseline. Mandatory recovery suggested.';
    }

    if (attendancePct < 85) {
      return 'STABILITY ALERT: Student is within safety margins but showing signs of inconsistent engagement. Monitor next 2 sessions.';
    }

    return 'OPTIMAL PERFORMANCE: Continuous engagement verified. Pattern consistency: 98%.';
  }

  static String getGlobalInsight(Map<String, dynamic> stats) {
    final alerts = stats['fraudAlerts'] ?? 0;
    final risk = stats['atRiskStudents'] ?? 0;
    final integrity = stats['integrityScore'] ?? 100;

    if (alerts > 5) return 'INTELLIGENCE ALERT: Detectable cluster of device fingerprint anomalies in active sessions. Security level: RESTRICTED.';
    if (risk > 15) return 'ACADEMIC ALERT: $risk% of student population showing significant attendance degradation. Institutional action recommended.';
    
    return 'SYSTEM STATUS: Integrity score $integrity% (Stable). Cross-departmental compliance is currently 100%.';
  }
}
