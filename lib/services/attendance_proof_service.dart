import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_proof_model.dart';
import 'package:uuid/uuid.dart';

class AttendanceProofService {
  static const _proofsKey = 'sa_attendance_proofs';

  static Future<void> saveProof({
    required String sessionID,
    required String subjectCode,
    required String subjectName,
    required String token,
    required String deviceID,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final id = const Uuid().v4();
    final signature = AttendanceProof.generateSignature(sessionID, deviceID, now);

    final proof = AttendanceProof(
      id: id,
      timestamp: now,
      sessionID: sessionID,
      subjectCode: subjectCode,
      subjectName: subjectName,
      token: token,
      deviceID: deviceID,
      hashSignature: signature,
    );

    final String? raw = prefs.getString(_proofsKey);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];
    list.insert(0, proof.toJson());
    
    // Keep max 100 proofs
    if (list.length > 100) list.removeRange(100, list.length);
    
    await prefs.setString(_proofsKey, jsonEncode(list));
  }

  static Future<List<AttendanceProof>> getProofs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_proofsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((j) => AttendanceProof.fromJson(j)).toList();
  }

  static Future<void> clearProofs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proofsKey);
  }
}
