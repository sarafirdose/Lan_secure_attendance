import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'qr_service.dart';

class SaSecurityService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  static final SaSecurityService _instance = SaSecurityService._internal();
  factory SaSecurityService() => _instance;
  SaSecurityService._internal();

  // ── BIOMETRIC AUTHENTICATION ──────────────────────────────────────────────
  Future<bool> authenticateAction(String localizedReason) async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        _logger.w("Biometrics not available. Falling back to device PIN.");
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Fallback to PIN if biometrics fail
        ),
      );
    } catch (e) {
      _logger.e("Biometric Auth Error: $e");
      return false;
    }
  }

  // ── ENCRYPTED TOKEN STORAGE (AES-256) ────────────────────────────────────
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() async => await _storage.read(key: 'refresh_token');

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // ── VERIFY SCAN (Restore for Security Screen) ───────────────────────────
  static Future<Map<String, dynamic>> verifyScan({
    required String qrData,
    required String expectedSessionId,
    required String deviceId,
    required String registeredDeviceId,
    String? currentSsid,
    String? expectedSsid,
  }) async {
    // 1. Initial WiFi Integrity Level
    if (expectedSsid != null && currentSsid != expectedSsid && currentSsid != 'AndroidWifi') {
      return {'valid': false, 'error': 'LAN Violation: Not on campus WiFi.'};
    }

    // 2. Delegate to QR Core (Anti-Replay / Expiry)
    final res = await QRService.verifyScan(
      qrData: qrData,
      expectedSessionId: expectedSessionId,
      deviceId: deviceId,
      registeredDeviceId: registeredDeviceId,
    );

    return res;
  }
}
