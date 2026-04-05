import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';
import 'qr_service.dart';
import 'audit_service.dart';

class AttendanceService {
  static const _activeSessionKey = 'sa_active_session_backend';
  static const _recordsKey = 'sa_attendance_records_backend';

  static Future<AttendanceSession> startSession({
    required String subject,
    required String classLabel,
    required String ssid,
  }) async {
    final now = DateTime.now();
    final sessionID = 'SESS_${now.millisecondsSinceEpoch}';

    final session = AttendanceSession(
      sessionId: sessionID,
      subject: subject,
      department: classLabel.split('-')[0],
      year: classLabel.split('-')[1],
      section: classLabel.split('-')[2],
      startTime: now,
      isActive: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionKey, jsonEncode(session.toJson()));

    await AuditService.logAction(
      action: 'SESSION_CREATE',
      description: 'Started session for $subject ($classLabel)',
    );

    return session;
  }

  static Future<void> stopSession(AttendanceSession session) async {
    final prefs = await SharedPreferences.getInstance();
    // In production, move to history array, but here we just clear active
    await prefs.remove(_activeSessionKey);
  }

  static Future<Map<String, dynamic>> markAttendance({
    required String qrData,
    required String studentID,
    required String deviceID,
    required String registeredDeviceID,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawSession = prefs.getString(_activeSessionKey);
    
    if (rawSession == null) {
      return {'success': false, 'error': 'No active session found'};
    }

    final activeSession = AttendanceSession.fromJson(jsonDecode(rawSession));

    // Verify token (Anti-Replay & Expiry)
    final verification = await QRService.verifyScan(
      qrData: qrData,
      expectedSessionId: activeSession.sessionId,
      deviceId: deviceID,
      registeredDeviceId: registeredDeviceID,
    );

    if (verification['valid'] != true) {
      await AuditService.logAction(
        action: 'FRAUD_DETECTED', 
        description: 'Failed scan for $studentID: ${verification['error']}'
      );
      return {'success': false, 'error': verification['error']};
    }

    // Prevent duplicate records for the same session manually
    final rawRecords = prefs.getStringList(_recordsKey) ?? [];
    for (String r in rawRecords) {
      final rec = StudentAttendanceEntry.fromJson(jsonDecode(r));
      // In this logic, we just check if student ID exists in the list for this session
      // For simplicity, we assume session ID is stored in the record metadata
      if (jsonDecode(r)['sessionId'] == activeSession.sessionId && rec.rollNumber == studentID) {
        return {'success': false, 'error': 'You have already marked attendance for this session.'};
      }
    }

    // Record success
    final record = {
      'rollNumber': studentID,
      'sessionId': activeSession.sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'present',
    };

    rawRecords.add(jsonEncode(record));
    await prefs.setStringList(_recordsKey, rawRecords);

    return {'success': true};
  }
}
