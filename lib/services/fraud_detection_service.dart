import 'dart:math';

enum FraudSeverity { critical, warning, suspicious }

enum FraudRule {
  duplicateQr,
  deviceMismatch,
  rapidReScan,
  unauthorizedNetwork,
  expiredToken,
}

class FraudLog {
  final String id;
  final String studentName;
  final String rollNumber;
  final String deviceId;
  final String ipAddress;
  final DateTime timestamp;
  final FraudRule rule;
  final FraudSeverity severity;
  bool isDismissed;
  bool isBlocked;

  FraudLog({
    required this.id,
    required this.studentName,
    required this.rollNumber,
    required this.deviceId,
    required this.ipAddress,
    required this.timestamp,
    required this.rule,
    required this.severity,
    this.isDismissed = false,
    this.isBlocked = false,
  });

  String get ruleLabel {
    switch (rule) {
      case FraudRule.duplicateQr:
        return 'Duplicate QR Scan';
      case FraudRule.deviceMismatch:
        return 'Device Mismatch';
      case FraudRule.rapidReScan:
        return 'Rapid Re-Scan';
      case FraudRule.unauthorizedNetwork:
        return 'Unauthorized Network';
      case FraudRule.expiredToken:
        return 'Expired QR Token';
    }
  }

  String get ruleDescription {
    switch (rule) {
      case FraudRule.duplicateQr:
        return 'The same QR code was scanned more than once by this student.';
      case FraudRule.deviceMismatch:
        return 'Student ID was used from a different device than registered.';
      case FraudRule.rapidReScan:
        return 'Two scan attempts detected within 15 seconds — possible proxy.';
      case FraudRule.unauthorizedNetwork:
        return 'Scan attempted from outside the campus network subnet.';
      case FraudRule.expiredToken:
        return 'QR token was expired (older than 5 minutes) when scanned.';
    }
  }
}

class ScanEvent {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String deviceId;
  final String qrToken;
  final String ipAddress;
  final DateTime scannedAt;
  final DateTime tokenGeneratedAt;

  ScanEvent({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.deviceId,
    required this.qrToken,
    required this.ipAddress,
    required this.scannedAt,
    required this.tokenGeneratedAt,
  });
}

class FraudDetectionService {
  // In-memory store of recent scans and fraud logs
  static final List<FraudLog> logs = [];
  static final Map<String, DateTime> _lastScanTime = {};
  static final Map<String, String> _studentDeviceMap = {};
  static final Set<String> _usedTokens = {};

  static final List<String> _validSubnets = [
    '192.168.1',
    '192.168.0',
    '10.0.0',
    '10.10.',
  ];

  /// Evaluate a scan event against all fraud rules
  static List<FraudLog> evaluate(ScanEvent event) {
    final detected = <FraudLog>[];

    // Rule 1: Duplicate QR token
    if (_usedTokens.contains(event.qrToken)) {
      detected.add(FraudLog(
        id: _uid(),
        studentName: event.studentName,
        rollNumber: event.rollNumber,
        deviceId: event.deviceId,
        ipAddress: event.ipAddress,
        timestamp: event.scannedAt,
        rule: FraudRule.duplicateQr,
        severity: FraudSeverity.critical,
      ));
    }

    // Rule 2: Device mismatch
    final registeredDevice = _studentDeviceMap[event.studentId];
    if (registeredDevice != null && registeredDevice != event.deviceId) {
      detected.add(FraudLog(
        id: _uid(),
        studentName: event.studentName,
        rollNumber: event.rollNumber,
        deviceId: event.deviceId,
        ipAddress: event.ipAddress,
        timestamp: event.scannedAt,
        rule: FraudRule.deviceMismatch,
        severity: FraudSeverity.critical,
      ));
    } else {
      _studentDeviceMap[event.studentId] = event.deviceId;
    }

    // Rule 3: Rapid re-scan (< 15 seconds)
    final lastScan = _lastScanTime[event.studentId];
    if (lastScan != null) {
      final diff = event.scannedAt.difference(lastScan).inSeconds.abs();
      if (diff < 15) {
        detected.add(FraudLog(
          id: _uid(),
          studentName: event.studentName,
          rollNumber: event.rollNumber,
          deviceId: event.deviceId,
          ipAddress: event.ipAddress,
          timestamp: event.scannedAt,
          rule: FraudRule.rapidReScan,
          severity: FraudSeverity.warning,
        ));
      }
    }
    _lastScanTime[event.studentId] = event.scannedAt;

    // Rule 4: Unauthorized network
    final isValidIp = _validSubnets.any((s) => event.ipAddress.startsWith(s));
    if (!isValidIp) {
      detected.add(FraudLog(
        id: _uid(),
        studentName: event.studentName,
        rollNumber: event.rollNumber,
        deviceId: event.deviceId,
        ipAddress: event.ipAddress,
        timestamp: event.scannedAt,
        rule: FraudRule.unauthorizedNetwork,
        severity: FraudSeverity.critical,
      ));
    }

    // Rule 5: Expired QR token (> 5 min)
    final tokenAge =
        event.scannedAt.difference(event.tokenGeneratedAt).inMinutes.abs();
    if (tokenAge > 5) {
      detected.add(FraudLog(
        id: _uid(),
        studentName: event.studentName,
        rollNumber: event.rollNumber,
        deviceId: event.deviceId,
        ipAddress: event.ipAddress,
        timestamp: event.scannedAt,
        rule: FraudRule.expiredToken,
        severity: FraudSeverity.suspicious,
      ));
    }

    // Mark token as used
    _usedTokens.add(event.qrToken);

    // Store detected logs
    logs.insertAll(0, detected);
    return detected;
  }

  static void dismissLog(String id) {
    final idx = logs.indexWhere((l) => l.id == id);
    if (idx >= 0) logs[idx].isDismissed = true;
  }

  static void blockStudent(String id) {
    final idx = logs.indexWhere((l) => l.id == id);
    if (idx >= 0) logs[idx].isBlocked = true;
  }

  static void clearAll() => logs.clear();

  static int get criticalCount =>
      logs.where((l) => l.severity == FraudSeverity.critical && !l.isDismissed).length;

  static int get activeCount => logs.where((l) => !l.isDismissed).length;

  static String _uid() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();
}
