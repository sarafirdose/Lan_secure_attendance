import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';

class SaAuditService {
  static const _auditKey = 'sa_audit_logs';

  // ── Step 5: Log Action ─────────────────────────────────────────────────────
  static Future<void> logAction({
    required String userId,
    required String action,
    String? previousValue,
    String? newValue,
  }) async {
    final entry = AuditEntry(
      id: const Uuid().v4(),
      userId: userId,
      action: action,
      previousValue: previousValue ?? 'N/A',
      newValue: newValue ?? 'N/A',
      timestamp: DateTime.now(),
    );

    final logs = await getLogs();
    logs.insert(0, entry); // Newest first
    await _persistLogs(logs);
  }

  static Future<List<AuditEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_auditKey);
    if (raw == null) return [];
    return raw.map((e) => AuditEntry.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> _persistLogs(List<AuditEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_auditKey, raw);
  }
}
