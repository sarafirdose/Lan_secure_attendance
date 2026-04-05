import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'analytics_ai_service.dart';
import 'notification_service.dart';
import 'network_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (kDebugMode) {
        NetworkService.logger.i('Running background task: $task');
      }

      if (task == 'ai_risk_assessment_sync') {
        // Init needed services
        final notifications = NotificationService();
        await notifications.init();

        // Check if user is logged in
        final user = await AuthService.getCurrentUser();
        if (user != null && user['role'] == 'student') {
          final uid = user['uid'] ?? user['rollNumber'];
          
          NetworkService.logger.i('[Background] Checking AI risk for $uid');
          final riskData = await AnalyticsAIService.getStudentAIPrediction(uid);
          
          if (riskData.isNotEmpty && riskData.containsKey('risk')) {
            final riskLevel = riskData['risk'].toString().toUpperCase();
            
            // Only alert if Critical or Warning to avoid spam
            if (riskLevel == 'CRITICAL' || riskLevel == 'WARNING') {
              final exp = riskData['explanation'] ?? 'Urgent attention required';
              
              notifications.showNotification(
                title: '⚡ Attendance Alert: $riskLevel Risk',
                body: exp,
                priority: riskLevel == 'CRITICAL' ? 'CRITICAL' : 'HIGH',
              );
            }
          }
        }
      }
      return Future.value(true);
    } catch (err) {
      NetworkService.logger.e('[Background] Sync failed: $err');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  static void registerPeriodicRiskAssessment() {
    Workmanager().registerPeriodicTask(
      "org.secureattend.ai.sync",
      "ai_risk_assessment_sync",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: const Duration(minutes: 5), // Don't fire immediately on app start
    );
  }
}
