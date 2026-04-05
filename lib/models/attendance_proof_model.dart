import 'dart:convert';
import 'package:crypto/crypto.dart';

class AttendanceProof {
  final String id;
  final DateTime timestamp;
  final String sessionID;
  final String subjectCode;
  final String subjectName;
  final String token;
  final String deviceID;
  final String hashSignature;

  AttendanceProof({
    required this.id,
    required this.timestamp,
    required this.sessionID,
    required this.subjectCode,
    required this.subjectName,
    required this.token,
    required this.deviceID,
    required this.hashSignature,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'sessionID': sessionID,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'token': token,
        'deviceID': deviceID,
        'signature': hashSignature,
      };

  factory AttendanceProof.fromJson(Map<String, dynamic> json) {
    return AttendanceProof(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      sessionID: json['sessionID'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      token: json['token'] ?? '',
      deviceID: json['deviceID'] ?? '',
      hashSignature: json['signature'] ?? '',
    );
  }

  static String generateSignature(String session, String device, DateTime time) {
    final payload = '${session}_${device}_${time.millisecondsSinceEpoch}';
    final bytes = utf8.encode(payload);
    return sha256.convert(bytes).toString();
  }
}

class AttendanceProofModel {
  final String sessionID;
  final String studentID;
  final DateTime timestamp;
  final String deviceID;
  
  // Hardened Sync Metrics
  final String syncStatus; // pending, synced, failed, conflict
  final DateTime updatedAt;
  final int version;
  final String? hashSignature;

  AttendanceProofModel({
    required this.sessionID,
    required this.studentID,
    required this.timestamp,
    required this.deviceID,
    this.syncStatus = 'pending',
    DateTime? updatedAt,
    this.version = 1,
    this.hashSignature,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    final data = {
      'sessionID': sessionID,
      'studentID': studentID,
      'timestamp': timestamp.toIso8601String(),
      'deviceID': deviceID,
      'syncStatus': syncStatus,
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
    if (hashSignature != null) {
      data['hashSignature'] = hashSignature!;
    }
    return data;
  }

  factory AttendanceProofModel.fromJson(Map<String, dynamic> json) {
    return AttendanceProofModel(
      sessionID: json['sessionID'] ?? '',
      studentID: json['studentID'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      deviceID: json['deviceID'] ?? '',
      syncStatus: json['syncStatus'] ?? 'pending',
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      version: json['version'] ?? 1,
      hashSignature: json['hashSignature'],
    );
  }

  String generateComputedHash() {
    final coreData = '$sessionID|$studentID|${timestamp.toIso8601String()}|$deviceID|$version|${updatedAt.toIso8601String()}';
    return sha256.convert(utf8.encode(coreData)).toString();
  }
}
