import 'dart:async';
import 'ai_decision_engine.dart';
import 'ai_action_engine.dart';
import 'teacher_service.dart';
import 'app_state_service.dart';
import 'teacher_intelligence_service.dart';
import '../models/session_model.dart';

class AIObserverService {
  static final AIObserverService _instance = AIObserverService._internal();
  factory AIObserverService() => _instance;
  AIObserverService._internal();

  Timer? _scheduleWatcher;
  DateTime? _lastPromptTime;
  String? _lastActionType;
  final Duration _cooldown = const Duration(seconds: 30);

  // Context Flags
  bool hasSuggestedSessionStart = false;
  bool hasWarnedSessionEnd = false;
  bool hasAlertedRisk = false;

  bool _isWatching = false;
  
  bool get isWatching => _isWatching;

  void startWatching() {
     _isWatching = true;
     _scheduleWatcher?.cancel();
     _scheduleWatcher = Timer.periodic(const Duration(seconds: 10), (timer) {
        _evaluateContexts();
     });
  }

  void stopWatching() {
     _isWatching = false;
     _scheduleWatcher?.cancel();
  }

  void resetContext() {
     hasSuggestedSessionStart = false;
     hasWarnedSessionEnd = false;
     hasAlertedRisk = false;
     _lastPromptTime = null;
     _lastActionType = null;
  }

  Future<void> _evaluateContexts() async {
     // 1. Session Closing Guard Observer
      if (AppStateService().hasActiveSession) {
         final session = AppStateService().activeSession!;
         final decision = AIDecisionEngine.evaluateSessionEndWarning(session);
         if (decision != null) {
           if (decision.actionType == 'CLOSE_SESSION_WARNING' && !hasWarnedSessionEnd) {
              if (_enforceCooldown(decision.actionType)) {
                 AIActionEngine().executeDecision(decision, silent: false);
                 hasWarnedSessionEnd = true;
              }
           } else if (decision.actionType == 'CLOSE_SESSION') {
              AIActionEngine().executeDecision(decision, silent: true); // Auto-closes strictly ignoring UI
           }
        }
        return; // Prioritize running session checks before reading timetable loops
     }

      // 2. Schedule Confirmation Prompt (10 mins before)
      final todayClasses = await TeacherService.getUpcomingClasses();
      final stats = await TeacherIntelligenceService.getConfidenceStats();
      final confidence = stats['score'] as double? ?? 0.8;

      for (final cls in todayClasses) {
          final startStr = cls.startTime;
          final now = DateTime.now();
          
          final parts = startStr.split(':');
          int hour = int.tryParse(parts[0]) ?? 0;
          int min = int.tryParse(parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '') : '0') ?? 0;
          if (startStr.contains('PM') && hour != 12) hour += 12;
          if (startStr.contains('AM') && hour == 12) hour = 0;
          
          final targetStart = DateTime(now.year, now.month, now.day, hour, min);
          final decision = AIDecisionEngine.evaluateSessionConfirmation(cls.subject, targetStart, confidence);
          
          if (decision != null && !hasSuggestedSessionStart) {
             if (_enforceCooldown(decision.actionType)) {
                AIActionEngine().executeDecision(decision, silent: false);
                hasSuggestedSessionStart = true;
             }
             break;
          }
      }
  }

  bool _enforceCooldown(String actionType) {
     final now = DateTime.now();
     if (_lastPromptTime == null) {
        _lastPromptTime = now;
        _lastActionType = actionType;
        return true;
     }

     // If Priority == High -> override cooldown (fraud flags) -> the Decision engine natively sets High outside this observer block
     
     if (now.difference(_lastPromptTime!) > _cooldown || _lastActionType != actionType) {
        _lastPromptTime = now;
        _lastActionType = actionType;
        return true;
     }
     
     return false;
  }
}
