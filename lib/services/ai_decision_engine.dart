import '../models/ai_decision_model.dart';
import '../models/session_model.dart';

class AIDecisionEngine {

  /// Core logic defining strict AI confirmation prompts 10 minutes before class.
  static AIDecisionModel? evaluateSessionConfirmation(String subject, DateTime startTime, double confidenceScore) {
    // Check if the diff is within 10 minutes of now
    final diff = startTime.difference(DateTime.now()).inMinutes;
    if (diff > 0 && diff <= 10) {
       return AIDecisionModel(
         actionType: 'CONFIRM_SESSION',
         priority: confidenceScore > 0.9 ? 'LOW' : 'MEDIUM',
         reason: 'Upcoming class tracking matched.',
         confidence: confidenceScore * 100,
         patternTag: 'pre_flight_check',
         timestamp: DateTime.now(),
         metadata: {
           'subject': subject, 
           'startTime': startTime.toIso8601String(),
           'autoSuggest': confidenceScore > 0.9,
         },
       );
    }
    return null;
  }

  static AIDecisionModel? evaluateSessionEndWarning(AttendanceSession session) {
    if (!session.active) return null;
    
    // Fallback: 45 min class defaults
    const maxDur = Duration(minutes: 45);
    final endTime = session.endTime ?? session.startTime.add(maxDur);
    final diff = endTime.difference(DateTime.now()).inMinutes;
    if (diff > 0 && diff <= 5) {
       return AIDecisionModel(
         actionType: 'CLOSE_SESSION_WARNING',
         priority: 'MEDIUM',
         reason: 'Session ${session.subject} ending strictly in $diff mins.',
         confidence: 99.0, // Math certainty
         patternTag: 'timer_ending',
         timestamp: DateTime.now(),
         metadata: {'sessionID': session.sessionId},
       );
    } else if (diff <= 0) {
       return AIDecisionModel(
         actionType: 'CLOSE_SESSION',
         priority: 'HIGH', // Forces closure over overlapping prompts
         reason: 'Session Timer Expired.',
         confidence: 100.0,
         patternTag: 'timer_expired',
         timestamp: DateTime.now(),
         metadata: {'sessionID': session.sessionId},
       );
    }
    return null;
  }

  static AIDecisionModel evaluateStudentRisk(List<String> recentStatuses) {
     final int total = recentStatuses.length;
     if (total == 0) {
       return AIDecisionModel(
         actionType: 'SUGGESTION',
         priority: 'LOW',
         reason: 'Insufficient attendance data to track pattern.',
         confidence: 0,
         patternTag: 'irregular',
         timestamp: DateTime.now(),
       );
     }

     final presentCount = recentStatuses.where((s) => s != 'absent').length;
     final percentage = (presentCount / total) * 100;
     
     int confidencePct = (total * 10).clamp(0, 80); 
     String patternTag = "irregular";
     String reason = "Analyzing pattern structure.";

     if (total >= 6) {
       final last3Present = recentStatuses.sublist(total - 3).where((s) => s != 'absent').length;
       final prev3Present = recentStatuses.sublist(total - 6, total - 3).where((s) => s != 'absent').length;

       if (last3Present < prev3Present && last3Present <= 1) {
          patternTag = "declining";
          reason = "Attendance declining drastically comparing [-3:] block vs previous block.";
          confidencePct += 20; 
       } else if (last3Present > prev3Present && last3Present >= 2) {
          patternTag = "improving";
          reason = "Attendance improving strictly.";
          confidencePct += 20;
       }
     } else if (total >= 3) {
       final last3Present = recentStatuses.sublist(total - 3).where((s) => s != 'absent').length;
       if (last3Present == 0) {
          patternTag = "declining";
          reason = "Consistent absent blocks tracked.";
          confidencePct += 15;
       }
     }
     
     if (percentage < 75 && patternTag == 'declining') {
        return AIDecisionModel(
          actionType: 'ALERT_RISK',
          priority: 'HIGH',
          reason: 'Attendance extremely critical at ${percentage.toStringAsFixed(1)}% and strictly declining.',
          confidence: confidencePct.toDouble().clamp(0.0, 100.0),
          patternTag: patternTag,
          timestamp: DateTime.now(),
        );
     }
     
     return AIDecisionModel(
       actionType: 'SUGGESTION',
       priority: percentage >= 75 ? 'LOW' : 'MEDIUM',
       reason: percentage >= 75 ? 'Safe percentage mapping matched.' : reason,
       confidence: confidencePct.toDouble().clamp(0.0, 100.0),
       patternTag: patternTag,
       timestamp: DateTime.now(),
     );
  }
}
