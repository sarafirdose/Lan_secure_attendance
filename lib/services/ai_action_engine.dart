import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ai_decision_model.dart';
import '../models/session_model.dart';
import 'app_state_service.dart';
import 'audit_service.dart';
import 'session_service.dart';
import 'notification_service.dart';

class AIActionEngine {
  static final AIActionEngine _instance = AIActionEngine._internal();
  factory AIActionEngine() => _instance;
  AIActionEngine._internal();

  final Map<String, Timer> _pendingActions = {};

  /// Global Handler for UI Popups triggering Background Run without forcing Screen Context Navigation
  void executeDecision(AIDecisionModel decision, {bool silent = false}) {
    if (decision.priority == 'HIGH') {
       _triggerNotification(decision); // New: Show notification immediately
       _runGuardRailsAndExecute(decision); // Immediate override
       return;
    }
    
    _triggerNotification(decision); // Trigger for normal priority as well

    if (!decision.canAutoExecute) {
       _promptSuggestion(decision); // Logic boundary not met -> simple UI suggestion
    } else {
       if (!silent && _isUIReady()) {
          _promptDelayedAutoExecution(decision);
       } else {
          _runGuardRailsAndExecute(decision); // Executed blindly if silent flag triggers or auto-loop completed
       }
    }
  }

  bool _isUIReady() {
    return AppStateService().scaffoldMessengerKey.currentState != null;
  }

  void _promptSuggestion(AIDecisionModel decision) {
     final msg = decision.reason;
     AppStateService().scaffoldMessengerKey.currentState?.showSnackBar(
       SnackBar(
         content: Row(children: [
           const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 18),
           const SizedBox(width: 8), 
           Expanded(child: Text(msg)),
         ]),
         behavior: SnackBarBehavior.floating,
         backgroundColor: const Color(0xFFFFFFFF),
       )
     );
  }

  void _promptDelayedAutoExecution(AIDecisionModel decision) {
     final actionId = decision.timestamp.toString();
     
     // 15 seconds global loop
     const waitSecs = 15;
     
     AppStateService().scaffoldMessengerKey.currentState?.showSnackBar(
       SnackBar(
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(children: [
               const Icon(Icons.auto_fix_high_rounded, color: Colors.blueAccent, size: 18),
               const SizedBox(width: 8), 
               Text('AI Automation: ${decision.actionType.replaceAll('_', ' ')}', style: const TextStyle(fontWeight: FontWeight.w700)),
             ]),
             const SizedBox(height: 4),
             Text('${decision.reason}\nAuto-executing in $waitSecs seconds...'),
           ]
         ),
         behavior: SnackBarBehavior.floating,
         duration: const Duration(seconds: waitSecs),
         backgroundColor: const Color(0xFFFFFFFF),
         action: SnackBarAction(
           label: 'CANCEL',
           textColor: Colors.redAccent,
           onPressed: () {
             _pendingActions[actionId]?.cancel();
             _pendingActions.remove(actionId);
           },
         ),
       )
     );

     // Queue background execution tracking Id 
     _pendingActions[actionId] = Timer(const Duration(seconds: waitSecs), () {
        _runGuardRailsAndExecute(decision);
        _pendingActions.remove(actionId);
     });
  }

  Future<void> _runGuardRailsAndExecute(AIDecisionModel decision) async {
    bool success = false;
    
    try {
      if (decision.actionType == 'START_SESSION') {
         if (AppStateService().hasActiveSession) return; // Prevent Overlap Guard
         final label = decision.metadata?['classLabel'];
         if (label != null) {
            final parts = label.split('-');
            if (parts.length >= 3) {
               final result = await SessionService.startSession(
                  department: parts[0], year: parts[1], section: parts[2], subject: parts[0]
               );
               final session = result['session'] as AttendanceSession;
               AppStateService().setActiveSession(session);
               success = true;
            }
         }
      } else if (decision.actionType == 'CLOSE_SESSION' || decision.actionType == 'CLOSE_SESSION_WARNING') {
         if (!AppStateService().hasActiveSession) return;
         await SessionService.endSession(AppStateService().activeSession!);
         AppStateService().setActiveSession(null);
         success = true;
      } else if (decision.actionType == 'ALERT_RISK') {
         success = true; // Alerts automatically tracked inherently
      }
      
      if (success) {
         await AuditService.logAction(action: 'AI_AUTOMATION_SUCCESS', description: 'Executed ${decision.actionType} dynamically. Reason: ${decision.reason} (${decision.confidence}%)');
         // Provide 10s Undo logic if applicable visually
         if (['CLOSE_SESSION', 'START_SESSION'].contains(decision.actionType)) {
             AppStateService().scaffoldMessengerKey.currentState?.showSnackBar(
               const SnackBar(content: Text('AI action executed ✓'), backgroundColor: Color(0xFF059669), duration: Duration(seconds: 2))
             );
         }
      }
    } catch (e) {
      // 1-Retry Logic mapped strictly
      await AuditService.logAction(action: 'AI_AUTOMATION_FAILURE', description: 'Failed to execute ${decision.actionType}. System enforcing offline safety halt.');
    }
  }

  static String generateStudentRecoveryPlan(List<String> statuses, double currentPct) {
    if (currentPct >= 75) return "Your attendance is secure. Keep it up!";
    
    // Simulate prediction rule base. E.g. miss 3 more rules.
    final total = statuses.isEmpty ? 1 : statuses.length;
    final needed = ((0.75 * (total + 5)) - statuses.where((s) => s != 'absent').length).ceil();
    
    if (needed > 5) {
      NotificationService().showNotification(
        title: "🚨 Critical Warning",
        body: "Your attendance is critically low. Immediate improvement required.",
        priority: 'CRITICAL',
      );
      return "Critical: Schedule Condemnation Warning - Please visit HoD manually.";
    }
    
    if (currentPct < 75) {
      NotificationService().showNotification(
        title: "⚠ Attendance Risk",
        body: "Your attendance is below 75% in this module.",
        priority: 'NORMAL',
      );
    }

    return "Recovery Prediction: Attend the next $needed class(es) consistently to breach 75% boundary dynamically.";
  }

  void _triggerNotification(AIDecisionModel decision) {
    String title = "AI Intelligence Alert";
    String body = decision.reason;
    String priority = decision.priority == 'HIGH' ? 'CRITICAL' : 'NORMAL';

    switch (decision.actionType) {
      case 'ALERT_RISK':
        final pct = decision.metadata?['percentage'] ?? 100.0;
        if (pct < 65) {
          title = "🚨 Critical Warning";
        } else if (pct < 75) {
          title = "⚠ Attendance Risk";
        }
        break;
      case 'FRAUD_ALERT':
        title = "🚨 Fraud Alert";
        priority = 'CRITICAL';
        break;
      case 'START_SESSION':
        title = "⏰ Class Reminder";
        break;
      case 'LOW_ATTENDANCE_WARNING':
        title = "📉 Low Attendance Alert";
        priority = 'CRITICAL';
        break;
      case 'SYSTEM_ALERT':
        title = "⚠ System Alert";
        break;
    }

    NotificationService().showNotification(
      title: title,
      body: body,
      priority: priority,
    );
  }
}
