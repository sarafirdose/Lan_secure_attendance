import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Flask backend service — replaces local SharedPreferences storage.
/// All data now goes to http://10.31.122.147:5000
class FirestoreService {
  // ── Change this to your laptop's IP shown when you ran app.py ──────────────
  static const String _baseUrl = 'http://10.31.122.147:5000';

  static const Duration _timeout = Duration(seconds: 10);

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Cannot reach server: $e'};
    }
  }

  static Future<Map<String, dynamic>> _get(
      String endpoint, Map<String, String> params) async {
    try {
      final uri =
          Uri.parse('$_baseUrl$endpoint').replace(queryParameters: params);
      final res = await http.get(uri).timeout(_timeout);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Cannot reach server: $e'};
    }
  }

  // ── Student profile ──────────────────────────────────────────────────────────

  static Future<void> saveStudentProfile({
    required String uid,
    required String rollNumber,
    required String fullName,
    required String department,
    required String yearSection,
    required String deviceFingerprint,
  }) async {
    // Profile is saved via /register — nothing extra needed here
  }

  static Future<Map<String, dynamic>?> getStudentProfile(String uid) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;
    final res =
        await _get('/profile', {'rollNumber': user['rollNumber'] ?? ''});
    if (res['success'] == true) return res['student'];
    return user;
  }

  static Stream<Map<String, dynamic>?> studentProfileStream() async* {
    final user = await AuthService.getCurrentUser();
    yield user;
  }

  // ── Mark attendance ──────────────────────────────────────────────────────────

  static Future<AttendanceResult> markAttendance({
    required String subjectCode,
    required String subjectName,
    required String qrToken,
    required String deviceFingerprint,
    required String deviceIp,
    required String ssid,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return AttendanceResult.notLoggedIn;

      final res = await _post('/mark-attendance', {
        'rollNumber': user['rollNumber'],
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'qrToken': qrToken,
        'deviceFingerprint': deviceFingerprint,
        'deviceIp': deviceIp,
        'ssid': ssid,
      });

      if (res['success'] == true) return AttendanceResult.success;

      final msg = (res['message'] ?? '').toString().toLowerCase();
      if (msg.contains('already')) return AttendanceResult.alreadyMarked;
      if (msg.contains('expired')) return AttendanceResult.qrExpired;
      if (msg.contains('invalid')) return AttendanceResult.invalidQr;
      if (msg.contains('device')) return AttendanceResult.wrongDevice;
      return AttendanceResult.error;
    } catch (_) {
      return AttendanceResult.error;
    }
  }

  // ── Attendance history ────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> attendanceHistoryStream() async* {
    final records = await getAllAttendanceRecords();
    yield records;
  }

  static Future<List<Map<String, dynamic>>> getAllAttendanceRecords() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];

    final res = await _get(
        '/attendance-history', {'rollNumber': user['rollNumber'] ?? ''});

    if (res['success'] == true) {
      final list = res['records'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Generate QR (faculty) ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> generateQr({
    required String subjectCode,
    required String subjectName,
    String facultyId = 'faculty',
  }) async {
    final res = await _post('/generate-qr', {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'facultyId': facultyId,
    });
    if (res['success'] == true) return res;
    return null;
  }

  // ── Health check ─────────────────────────────────────────────────────────────

  static Future<bool> isServerReachable() async {
    try {
      final res = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ── Result enums (same as before — screens don't change) ─────────────────────

enum AttendanceResult {
  success,
  alreadyMarked,
  qrExpired,
  invalidQr,
  wrongDevice,
  notRegistered,
  notLoggedIn,
  error,
}

extension AttendanceResultMessage on AttendanceResult {
  String get message {
    switch (this) {
      case AttendanceResult.success:
        return 'Attendance marked successfully!';
      case AttendanceResult.alreadyMarked:
        return 'Attendance already marked for this class today.';
      case AttendanceResult.qrExpired:
        return 'This QR code has expired. Ask your faculty for a new one.';
      case AttendanceResult.invalidQr:
        return 'Invalid QR code. Please scan the correct attendance QR.';
      case AttendanceResult.wrongDevice:
        return 'This device is not registered to your account.';
      case AttendanceResult.notRegistered:
        return 'Student profile not found. Please register again.';
      case AttendanceResult.notLoggedIn:
        return 'Please sign in to mark attendance.';
      case AttendanceResult.error:
        return 'Cannot reach server. Make sure you are on campus WiFi.';
    }
  }

  bool get isSuccess => this == AttendanceResult.success;
}
