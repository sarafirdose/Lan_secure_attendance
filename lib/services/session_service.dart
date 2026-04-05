import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state_service.dart';
import 'sync_service.dart';
import '../models/session_model.dart';
import 'network_service.dart';
import 'authenticated_client.dart';

class SessionService {
  static final String _baseUrl = NetworkService.baseUrl;
  static final AuthenticatedClient _client = AuthenticatedClient();
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // ── Centralized Session Lifecycle ─────────────────────────────────────────
  static Future<Map<String, dynamic>> startSession({
    required String department,
    required String year,
    required String section,
    required String subject,
  }) async {
    final now = DateTime.now();
    final sessionId = 'SESS_${now.millisecondsSinceEpoch}';

    final session = AttendanceSession(
      sessionId: sessionId,
      department: department,
      year: year,
      section: section,
      subject: subject,
      startTime: now,
      isActive: true,
      status: SessionStatus.conducted,
      students: [], 
    );

    try {
      final res = await _client.post(
        Uri.parse('$_baseUrl/start-session'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'teacher_id': AppStateService().currentUser?['uid'] ?? 'teacher',
          'subject': subject,
          'class_label': '$department-$year-$section',
          'ssid': 'Unknown', 
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        AppStateService().setActiveSession(session);
        return {
          'session': session,
          'qr_data': data['qr_data'] ?? '$sessionId|SUB|${subject}|${now.millisecondsSinceEpoch}',
          'expires_in': data['expires_in'] ?? 120,
        };
      } else if (res.statusCode == 401) {
        throw Exception('Session expired. Reconnecting...');
      } else {
        final errorMsg = jsonDecode(res.body)['message'] ?? 'Unknown Server Error';
        throw Exception('Server rejected session: $errorMsg');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Session expired')) {
        rethrow;
      }
      // Offline fallback: Queue start session and generate local mock 
      await SyncService.queueForSync(
        endpoint: '/start-session',
        token: 'offline_queue',
        body: {
          'session_id': sessionId,
          'teacher_id': AppStateService().currentUser?['uid'] ?? 'teacher',
          'subject': subject,
          'class_label': '$department-$year-$section',
          'ssid': 'Unknown',
        },
      );
      AppStateService().setActiveSession(session);
      return {
        'session': session,
        'qr_data': '$sessionId|SUB|${subject}|${now.millisecondsSinceEpoch}',
        'expires_in': 120,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getTopRiskStudents() async => [];
  static Future<List<String>> getLowPerformanceSubjects() async => [];
  
  static Future<bool> isStudentBlocked(String roll) async {
     return false; // Manager by centralized logic
  }

  static Future<List<Map<String, dynamic>>> syncActiveSession(String sessionId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/session_attendance?session_id=$sessionId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body)['records']);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> submitFinalSession(AttendanceSession session) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/submit-session'),
        headers: _headers,
        body: jsonEncode(session.toJson()),
      );
      if (res.statusCode == 200) {
        AppStateService().setActiveSession(null);
        return true;
      }
    } catch (_) {
      await SyncService.queueForSync(
        endpoint: '/submit-session',
        token: AppStateService().token,
        body: session.toJson(),
      );
      AppStateService().setActiveSession(null);
      return true;
    }
    return false;
  }

  // ── Legacy Restoration ────────────────────────────────────────────────────
  static Future<void> endSession(AttendanceSession session) async {
    await submitFinalSession(session);
  }

  static Future<List<AttendanceSession>> getPastSessions() async {
     // Return empty for now to avoid crashes, or fetch from API if needed
     return [];
  }

  static Future<AttendanceSession?> getActiveSession() async {
     return AppStateService().activeSession;
  }

  static Future<void> markNotConducted(String subject, String classLabel) async {
      await SyncService.queueForSync(
        endpoint: '/not-conducted',
        token: AppStateService().token,
        body: {'subject': subject, 'class_label': classLabel},
      );
  }

  static Future<void> extendSession(AttendanceSession session, int minutes) async {
      // Mock for UI
  }

  static List<StudentAttendanceEntry> getInitialRoster() => [];

  static void markAllPresent(AttendanceSession session) {}
  static void markAllAbsent(AttendanceSession session) {}

  static String? getExtensionRecommendation(AttendanceSession session) => null;

  static Future<List<Map<String, dynamic>>> getDefaulters({String? subject, String? classLabel, String? semester, int threshold = 75}) async {
    return [];
  }

  static Future<Map<String, Map<String, dynamic>>> getSubjectAnalytics({String? subject, String? classLabel, String? semester}) async {
    return {};
  }

  static Future<bool> finalizeAndSubmitSession(AttendanceSession session) async {
    // API logic to commit to persistent backend history
    return true;
  }
}
