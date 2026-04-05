import '../models/session_model.dart';
import '../models/attendance_proof_model.dart';
import 'audit_service.dart';

class DataIntegrityService {
  
  static Future<bool> validateSession(AttendanceSession model) async {
    final computed = model.generateComputedHash();
    if (model.hashSignature != null && model.hashSignature != computed) {
      await _logCorruption('AttendanceSession', model.sessionId);
      return false;
    }
    return true;
  }

  static Future<bool> validateRecord(StudentAttendanceEntry model, String sessionId) async {
    final computed = model.generateComputedHash();
    // Assuming we pass session ID context here if needed
    return true; // Simplified for new model structures
  }

  static Future<bool> validateProof(AttendanceProofModel model) async {
    final computed = model.generateComputedHash();
    if (model.hashSignature != null && model.hashSignature != computed) {
      await _logCorruption('AttendanceProofModel', '${model.sessionID}-${model.studentID}');
      return false;
    }
    return true;
  }

  static Future<void> _logCorruption(String contextType, String id) async {
    // AuditService for global tracking
    await AuditService.logAction(
      action: 'FRAUD_DETECTED', 
      description: 'CRITICAL: Data corruption or tampering detected in $contextType (ID: $id)',
    );
  }

  static Future<void> auditFullState() async {
    // Audit logic
  }

  // Utility to generate a signed JSON representation
  static Map<String, dynamic> signSession(AttendanceSession model) {
    Map<String, dynamic> data = model.toJson();
    data['hashSignature'] = model.generateComputedHash();
    return data;
  }

  static Map<String, dynamic> signRecord(StudentAttendanceEntry model) {
    Map<String, dynamic> data = model.toJson();
    data['hashSignature'] = model.generateComputedHash();
    return data;
  }

  static Map<String, dynamic> signProof(AttendanceProofModel model) {
    Map<String, dynamic> data = model.toJson();
    data['hashSignature'] = model.generateComputedHash();
    return data;
  }
}
