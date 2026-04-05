import 'dart:convert';
import 'package:crypto/crypto.dart';

enum SessionStatus { conducted, notConducted, cancelled }

/// Attendance session created when teacher starts taking attendance
class AttendanceSession {
  final String sessionId;
  final String department;
  final String year;
  final String section;
  final String subject;
  final String? semester;
  final DateTime startTime;
  DateTime? endTime;
  bool isActive;
  SessionStatus status;
  final List<StudentAttendanceEntry> students;
  
  // Smart Session Fields
  Duration maxDuration;
  bool isExtended;
  int extensionMinutes;
  
  // Production Security & Sync Fields (Step 1, 2)
  SyncStatus syncStatus;
  String? hashSignature;
  String? currentQrToken;
  DateTime? tokenExpiry;
  int? _totalMarkedOverride;
  set totalMarked(int value) => _totalMarkedOverride = value;
  
  bool isAuditModified;

  AttendanceSession({
    required this.sessionId,
    required this.department,
    required this.year,
    required this.section,
    required this.subject,
    this.semester,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    this.status = SessionStatus.conducted,
    List<StudentAttendanceEntry>? students,
    this.maxDuration = const Duration(minutes: 60),
    this.isExtended = false,
    this.extensionMinutes = 0,
    this.syncStatus = SyncStatus.pending,
    this.hashSignature,
    this.currentQrToken,
    this.tokenExpiry,
    this.isAuditModified = false,
  }) : students = students ?? [];

  bool get active => isActive;

  String get classLabel => '$department-$year-$section';

  int get presentCount =>
      students.where((s) => s.status == StudentStatus.present).length;
  int get absentCount =>
      students.where((s) => s.status == StudentStatus.absent).length;
  int get lateCount =>
      students.where((s) => s.status == StudentStatus.late).length;
  int get specialCount =>
      students.where((s) => s.status == StudentStatus.sports ||
          s.status == StudentStatus.medical ||
          s.status == StudentStatus.placement).length;
  int get totalMarked => _totalMarkedOverride ?? students.where((s) => s.status != StudentStatus.absent).length;

  double get presentPercentage =>
      students.isEmpty ? 0 : (presentCount / students.length) * 100;

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  DateTime get scheduledEndTime => startTime.add(maxDuration);
  
  Duration get timeLeft => scheduledEndTime.difference(DateTime.now());
  
  bool get hasExpired => DateTime.now().isAfter(scheduledEndTime);

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'department': department,
        'year': year,
        'section': section,
        'subject': subject,
        'semester': semester,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isActive': isActive,
        'status': status.name,
        'students': students.map((e) => e.toJson()).toList(),
        'maxDuration': maxDuration.inMinutes,
        'isExtended': isExtended,
        'extensionMinutes': extensionMinutes,
        'syncStatus': syncStatus.name,
        'hashSignature': hashSignature,
        'isAuditModified': isAuditModified,
      };

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    final students = (json['students'] as List<dynamic>?)
              ?.map((s) => StudentAttendanceEntry.fromJson(s))
              .toList() ?? [];
    return AttendanceSession(
      sessionId: json['sessionId'] ?? '',
      department: json['department'] ?? '',
      year: json['year'] ?? '',
      section: json['section'] ?? '',
      subject: json['subject'] ?? '',
      semester: json['semester'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isActive: json['isActive'] ?? false,
      status: SessionStatus.values.firstWhere((e) => e.name == (json['status'] ?? 'conducted'), orElse: () => SessionStatus.conducted),
      students: students,
      maxDuration: Duration(minutes: json['maxDuration'] ?? 60),
      isExtended: json['isExtended'] ?? false,
      extensionMinutes: json['extensionMinutes'] ?? 0,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      hashSignature: json['hashSignature'],
      isAuditModified: json['isAuditModified'] ?? false,
    );
  }

  String generateComputedHash() {
    final coreData = '$sessionId|$subject|$classLabel|${startTime.toIso8601String()}|$syncStatus';
    return sha256.convert(utf8.encode(coreData)).toString();
  }
}

enum SyncStatus {
  pending,
  synced,
  failed,
}

/// Audit Log entry for system modifications (Step 5)
class AuditEntry {
  final String id;
  final String userId;
  final String action;
  final String previousValue;
  final String newValue;
  final DateTime timestamp;

  AuditEntry({
    required this.id,
    required this.userId,
    required this.action,
    required this.previousValue,
    required this.newValue,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'action': action,
    'previousValue': previousValue,
    'newValue': newValue,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      action: json['action'] ?? '',
      previousValue: json['previousValue'] ?? '',
      newValue: json['newValue'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Individual student's attendance record within a session
class StudentAttendanceEntry {
  final String rollNumber;
  final String name;
  StudentStatus status;
  DateTime? scanTime;
  String? specialReason;

  StudentAttendanceEntry({
    required this.rollNumber,
    required this.name,
    this.status = StudentStatus.absent,
    this.scanTime,
    this.specialReason,
  });

  bool get isPresent =>
      status == StudentStatus.present || status == StudentStatus.late;

  Map<String, dynamic> toJson() => {
        'rollNumber': rollNumber,
        'name': name,
        'status': status.name,
        'scanTime': scanTime?.toIso8601String(),
        'specialReason': specialReason,
      };

  factory StudentAttendanceEntry.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceEntry(
      rollNumber: json['rollNumber'] ?? '',
      name: json['name'] ?? '',
      status: StudentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StudentStatus.absent,
      ),
      scanTime:
          json['scanTime'] != null ? DateTime.parse(json['scanTime']) : null,
      specialReason: json['specialReason'],
    );
  }

  String generateComputedHash() {
    final coreData = '$rollNumber|${status.name}|${scanTime?.toIso8601String()}';
    return sha256.convert(utf8.encode(coreData)).toString();
  }
}

enum StudentStatus {
  present,
  absent,
  late,
  sports,
  medical,
  placement,
}

extension StudentStatusLabel on StudentStatus {
  String get label {
    switch (this) {
      case StudentStatus.present:
        return 'Present';
      case StudentStatus.absent:
        return 'Absent';
      case StudentStatus.late:
        return 'Late';
      case StudentStatus.sports:
        return 'Sports';
      case StudentStatus.medical:
        return 'Medical';
      case StudentStatus.placement:
        return 'Placement';
    }
  }

  bool get countsAsPresent =>
      this == StudentStatus.present ||
      this == StudentStatus.late ||
      this == StudentStatus.sports ||
      this == StudentStatus.medical ||
      this == StudentStatus.placement;
}
