import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherIntelligenceService {
  static const _historyKey = 'sa_teacher_behavior_history';

  static Future<void> logOutcome(bool conducted, {String? subject, String? decisionType}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    
    // Add new outcome with metadata
    history.add(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'conducted': conducted,
      'subject': subject,
      'decisionType': decisionType ?? 'manual',
    }));

    // Keep only last 20 entries for rolling confidence
    if (history.length > 20) {
      history = history.sublist(history.length - 20);
    }

    await prefs.setStringList(_historyKey, history);
  }

  static Future<Map<String, dynamic>> getConfidenceStats() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];

    if (history.isEmpty) {
      return {
        'score': 0.8, // Default starting confidence
        'label': 'Initializing...',
        'explanation': 'System is gathering behavior patterns.',
        'trend': 'neutral',
      };
    }

    int conductedCount = 0;
    for (var entry in history) {
      final data = jsonDecode(entry);
      if (data['conducted'] == true) conductedCount++;
    }

    double score = conductedCount / history.length;
    
    String label;
    String explanation;
    String trend = 'neutral';

    if (score >= 0.9) {
      label = 'High Reliability';
      explanation = 'Based on past trends, you almost always conduct this session at this time.';
      trend = 'up';
    } else if (score >= 0.7) {
      label = 'Stable';
      explanation = 'You usually conduct your sessions as scheduled.';
      trend = 'neutral';
    } else if (score >= 0.4) {
      label = 'Variable';
      explanation = 'Some recent sessions were missed/cancelled. AI is monitoring pattern shift.';
      trend = 'down';
    } else {
      label = 'Low Confidence';
      explanation = 'Multiple recent sessions were not conducted. Admin oversight may be triggered.';
      trend = 'down';
    }

    return {
      'score': score,
      'label': label,
      'explanation': explanation,
      'trend': trend,
    };
  }
}
