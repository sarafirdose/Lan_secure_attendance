import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'network_service.dart';
import 'app_state_service.dart';

enum SyncState { pending, syncing, synced, failed }

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static final String _baseUrl = NetworkService.baseUrl;
  static const String _pendingKey = 'sa_pending_sync';

  Timer? _syncTimer;

  void startAutoSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncAll();
    });
  }

  Future<void> _syncAll() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingKey) ?? [];
    if (pending.isEmpty) return;

    final reachable = await AppStateService().pingServer();
    if (!reachable) return;

    AppStateService().updateStatus(SystemStatus.warning);
    
    List<String> remaining = [];
    bool allSuccess = true;

    for (var item in pending) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final endpoint = map['endpoint'];
      final body = map['body'];
      final token = map['token'];

      try {
        final res = await http.post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          // Success
        } else {
          remaining.add(item);
          allSuccess = false;
        }
      } catch (_) {
        remaining.add(item);
        allSuccess = false;
      }
    }

    await prefs.setStringList(_pendingKey, remaining);
    
    if (allSuccess && remaining.isEmpty) {
      AppStateService().updateStatus(SystemStatus.normal);
    }
  }

  static Future<void> queueForSync({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingKey) ?? [];
    
    final item = jsonEncode({
      'endpoint': endpoint,
      'body': body,
      'token': token,
      'timestamp': DateTime.now().toIso8601String(),
    });

    pending.add(item);
    await prefs.setStringList(_pendingKey, pending);
    AppStateService().updateStatus(SystemStatus.warning);
  }
}
