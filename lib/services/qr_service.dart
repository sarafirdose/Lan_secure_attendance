import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class QRService {
  static const int _tokenExpirySeconds = 15;
  static final Set<String> _usedTokens = {}; 

  // Token Format: sessionID | timestamp | hashSignature
  static String generateSecureToken(String sessionId, String deviceId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final salt = const Uuid().v4(); // Unique per tick
    
    // Core bound properties
    final raw = '$sessionId|$timestamp|$deviceId|$salt';
    
    final bytes = utf8.encode(raw);
    final hash = sha256.convert(bytes);
    
    return '$sessionId|$timestamp|${hash.toString()}';
  }

  static Future<Map<String, dynamic>> verifyScan({
    required String qrData,
    required String expectedSessionId,
    required String deviceId,
    required String registeredDeviceId,
  }) async {
    final parts = qrData.split('|');
    if (parts.length != 3) {
      return {'valid': false, 'error': 'Invalid QR Format'};
    }

    final scannedSessionId = parts[0];
    final timestamp = int.tryParse(parts[1]) ?? 0;
    final tokenHash = parts[2];
    
    // 1. Session Binding Check
    if (scannedSessionId != expectedSessionId) {
       return {'valid': false, 'error': 'Session mismatch: QR code belongs to a different session'};
    }

    // 2. Token Expiry Check
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now - timestamp > _tokenExpirySeconds) {
      return {'valid': false, 'error': 'QR Token Expired (15s limit)'};
    }

    // 3. Anti-Replay Check
    if (_usedTokens.contains(tokenHash)) {
      return {'valid': false, 'error': 'Reused/Duplicate QR detected'};
    }

    // 4. Integrity Check
    if (deviceId != registeredDeviceId) {
      return {'valid': false, 'error': 'Device Mismatch: Unauthorized Hardware'};
    }

    _usedTokens.add(tokenHash);
    return {'valid': true};
  }
}
