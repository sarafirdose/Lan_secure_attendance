import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_service.dart';

class StudentService {
  
  static double calculateAttendancePercentage(int present, int total) {
    if (total == 0) return 0.0;
    return (present / total) * 100;
  }

  static String calculateRisk(double percentage) {
    if (percentage >= 75) return 'Safe';
    if (percentage >= 65) return 'Warning';
    return 'Critical';
  }

  // ── AI Engine Enhancement ────────────────────────────────────────────────
  
  static Map<String, dynamic> generateAIAnalysis(List<String> recentStatuses, {double? currentOverallPct}) {
    final int total = recentStatuses.length;
    if (total == 0) {
      return {
        'riskLevel': 'Unknown',
        'confidencePct': 0,
        'explanation': 'Insufficient data for analysis.',
        'patternTag': 'no_data',
        'recoveryTip': 'Attend next classes to build data score.',
      };
    }

    final presentCount = recentStatuses.where((s) => s != 'absent').length;
    final percentage = calculateAttendancePercentage(presentCount, total);
    final riskLevel = calculateRisk(percentage);

    // Confidence Score Calculation
    int confidencePct = (total * 8).clamp(0, 85);
    
    String explanation = "Stable attendance pattern.";
    String patternTag = "stable";
    String recoveryTip = "Maintain current momentum.";

    if (total >= 5) {
      final last5 = recentStatuses.sublist(total - 5);
      final last5Present = last5.where((s) => s != 'absent').length;

      if (last5Present <= 2) {
         explanation = "High absence rate in recent sessions.";
         patternTag = "declining";
         recoveryTip = "Attend next 3 classes for recovery.";
      } else if (last5Present >= 4) {
         explanation = "Strong recent attendance streak.";
         patternTag = "improving";
         recoveryTip = "Perfect streak will boost score by ~5%.";
      }
    }

    // Predictive Insight Logic (If below 75% or near it)
    if (currentOverallPct != null) {
      if (currentOverallPct < 75) {
          explanation = "Risk: Below mandatory 75% threshold.";
          recoveryTip = "Must attend upcoming sessions without fail.";
      } else if (currentOverallPct < 80) {
          explanation = "Caution: Near boundary. Miss 1-2 classes and you'll fall below 75%.";
          recoveryTip = "Avoid any non-essential skips next week.";
      }
    }

    confidencePct = confidencePct.clamp(0, 100);

    return {
      'riskLevel': riskLevel,
      'confidencePct': confidencePct,
      'explanation': explanation,
      'patternTag': patternTag,
      'recoveryTip': recoveryTip,
    };
  }

  static Future<Map<String, dynamic>> getPredictiveAnalysis(String uid) async {
    try {
      final res = await http.get(Uri.parse('${NetworkService.baseUrl}/ai-predict?uid=$uid'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {
      'risk': 'Unknown',
      'explanation': 'Unable to reach AI engine.',
      'confidence': 0
    };
  }
}
