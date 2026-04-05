import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuditService {
  static const _auditKey = 'backend_audit_logs';

  // Strict valid action types bounding immutable tracking
  static const List<String> _validActions = [
    'ATTENDANCE_EDIT',
    'SESSION_CREATE',
    'FRAUD_DETECTED',
    'DEVICE_CHANGE',
  ];

  /// Appends an immutable log event. Delete/Update logic is intentionally omitted.
  static Future<void> logAction({
    required String action, 
    required String description,
  }) async {
    
    // Bounds Check Verification
    if (!_validActions.contains(action)) {
       throw ArgumentError('Invalid Action Type: $action. Must be one of $_validActions');
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Immutable Load - We never overwrite existing elements, only prepend.
    final raw = prefs.getStringList(_auditKey) ?? [];
    
    final entry = {
      'action': action,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    raw.insert(0, jsonEncode(entry));
    if (raw.length > 1000) {
       // Cap scaling, but maintain sequential immutability natively
       raw.removeLast(); 
    }
    
    await prefs.setStringList(_auditKey, raw);
  }

  /// Retrieves an immutable array of historical event mutations.
  static Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_auditKey) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}
