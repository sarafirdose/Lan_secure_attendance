import 'package:flutter/foundation.dart';

/// In-memory demo attendance state shared between teacher QR screen
/// and student demo scanner. No backend required.
class DemoStateService extends ChangeNotifier {
  static final DemoStateService _instance = DemoStateService._internal();
  factory DemoStateService() => _instance;
  DemoStateService._internal();

  String? _demoSessionId;
  String? _demoSubject;
  String? _demoClass;
  final List<Map<String, String>> _demoAttendees = [];

  String? get demoSessionId => _demoSessionId;
  String? get demoSubject => _demoSubject;
  String? get demoClass => _demoClass;
  List<Map<String, String>> get demoAttendees => List.unmodifiable(_demoAttendees);

  bool get hasActiveSession => _demoSessionId != null;

  /// Called by TeacherQRScreen when the QR is displayed
  void startDemoSession({
    required String sessionId,
    required String subject,
    required String classLabel,
  }) {
    _demoSessionId = sessionId;
    _demoSubject = subject;
    _demoClass = classLabel;
    _demoAttendees.clear();
    notifyListeners();
  }

  /// Simple marking for demo purposes
  void markAttended(String roll, String subject) {
    if (_demoAttendees.any((a) => a['roll'] == roll)) return;
    _demoAttendees.add({
      'name': 'Demo Student',
      'roll': roll,
      'time': _formatTime(DateTime.now()),
      'status': 'present',
      'subject': subject,
    });
    notifyListeners();
  }

  /// Called by DemoQrScannerScreen when a student successfully scans
  void markAttendance({
    required String studentName,
    required String rollNumber,
    required String scannedSessionId,
  }) {
    // Only mark if the session ID matches the active demo session
    if (_demoSessionId == null) return;
    // Prevent duplicate entries for same roll number
    final existing = _demoAttendees.any((a) => a['roll'] == rollNumber);
    if (existing) return;

    _demoAttendees.add({
      'name': studentName,
      'roll': rollNumber,
      'time': _formatTime(DateTime.now()),
      'status': 'present',
    });
    notifyListeners();
  }

  /// Called when teacher ends the session
  void endDemoSession() {
    _demoSessionId = null;
    _demoSubject = null;
    _demoClass = null;
    _demoAttendees.clear();
    notifyListeners();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
