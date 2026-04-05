import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';

class AttendanceRepository {
  static const String _storageKey = 'cached_sessions_repo';
  static const String _queueKey = 'sync_queue_repo';

  // 1. GET ALL SESSIONS
  static Future<List<AttendanceSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getString(_storageKey);
    
    List<AttendanceSession> sessions = [];
    if (localData != null) {
      final List<dynamic> jsonList = jsonDecode(localData);
      sessions = jsonList.map((e) => AttendanceSession.fromJson(e)).toList();
    }

    if (ApiService.useRemoteServer) {
        // In a real app: sessions = await ApiService.fetchRemoteSessions();
        // For now, we mix in local for offline-first
    }
    
    return sessions;
  }

  // 2. SAVE SESSION (Local + Queue for Backend)
  static Future<void> saveSession(AttendanceSession session) async {
    final sessions = await getAllSessions();
    
    // Update or Insert
    final index = sessions.indexWhere((s) => s.sessionId == session.sessionId);
    if (index != -1) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(sessions.map((e) => e.toJson()).toList()));

    // Add to Sync Queue
    await _addToSyncQueue(session);
  }

  // 3. SYNC QUEUE HANDLER
  static Future<void> _addToSyncQueue(AttendanceSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final queueData = prefs.getStringList(_queueKey) ?? [];
    
    final sessionJson = jsonEncode(session.toJson());
    if (!queueData.contains(sessionJson)) {
        queueData.add(sessionJson);
        await prefs.setStringList(_queueKey, queueData);
    }

    // Trigger background sync if online
    if (ApiService.useRemoteServer) {
        _processSyncQueue();
    }
  }

  static Future<void> _processSyncQueue() async {
     final prefs = await SharedPreferences.getInstance();
     final queueData = prefs.getStringList(_queueKey) ?? [];
     if (queueData.isEmpty) return;

     List<String> remaining = [];
     for (final item in queueData) {
        final success = await ApiService.sendAttendance(jsonDecode(item));
        if (!success) remaining.add(item);
     }
     
     await prefs.setStringList(_queueKey, remaining);
  }
}
