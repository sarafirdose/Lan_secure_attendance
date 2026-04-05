import 'package:flutter/material.dart';
import 'student_service.dart';
import 'notification_service.dart';
import 'app_state_service.dart';

class AutomatedNotificationService {
  static final NotificationService _notifications = NotificationService();
  
  /// Checks for AI-driven attendance risks and alerts the user
  static Future<void> checkAndNotifyRisk() async {
    final user = AppStateService().currentUser;
    if (user == null || user['role'] != 'student') return;

    final uid = user['uid'];
    final analysis = await StudentService.getPredictiveAnalysis(uid);

    final risk = analysis['risk'] ?? 'Safe';
    final prediction = analysis['prediction'] ?? 100.0;
    
    if (risk == 'Critical' || risk == 'Warning') {
      await _notifications.showLocalNotification(
        id: 999,
        title: '⚠️ Attendance Risk Alert',
        body: 'AI predicts your attendance will drop to $prediction%. Attend upcoming classes to stay safe!',
      );
    }
  }

  /// Can be scheduled to run every morning
  static void scheduleDailyChecks() {
    // In a real app, use WorkManager or a background fetch plugin
    // For this demo, we can trigger it on App Start or Dashboard Load
    checkAndNotifyRisk();
  }
}
