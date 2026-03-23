import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'network_service.dart';

/// Auth service — uses local SharedPreferences only.
/// Login and Register work on ANY network.
/// Only attendance marking requires campus WiFi (handled in security_verification_screen).
class AuthService {
  static const _accountsKey = 'sa_accounts';
  static const _currentUserKey = 'sa_current_user';

  // ── Register ────────────────────────────────────────────────────────────────
  static Future<AuthResult> register({
    required String rollNumber,
    required String fullName,
    required String department,
    required String yearSection,
    required String password,
    String email = '',
    String phone = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roll = rollNumber.trim().toUpperCase();
      final raw = prefs.getString(_accountsKey);
      final Map<String, dynamic> accounts = raw != null ? jsonDecode(raw) : {};

      if (accounts.containsKey(roll)) {
        return AuthResult.alreadyRegistered;
      }

      final fingerprint = await NetworkService.getDeviceFingerprint();

      accounts[roll] = {
        'rollNumber': roll,
        'fullName': fullName.trim(),
        'department': department,
        'yearSection': yearSection,
        'email': email.trim(),
        'phone': phone.trim(),
        'passwordHash': _hashPassword(password),
        'deviceFingerprint': fingerprint,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_accountsKey, jsonEncode(accounts));
      await _setCurrentUser(accounts[roll]);
      return AuthResult.success;
    } catch (_) {
      return AuthResult.error;
    }
  }

  // ── Sign in ──────────────────────────────────────────────────────────────────
  static Future<AuthResult> signIn({
    required String rollNumber,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roll = rollNumber.trim().toUpperCase();
      final raw = prefs.getString(_accountsKey);
      if (raw == null) return AuthResult.notRegistered;

      final Map<String, dynamic> accounts = jsonDecode(raw);
      if (!accounts.containsKey(roll)) return AuthResult.notRegistered;

      final account = accounts[roll] as Map<String, dynamic>;

      if (account['passwordHash'] != _hashPassword(password)) {
        return AuthResult.invalidCredentials;
      }

      // Device check
      final fingerprint = await NetworkService.getDeviceFingerprint();
      if (account['deviceFingerprint'] != null &&
          account['deviceFingerprint'] != fingerprint) {
        return AuthResult.wrongDevice;
      }

      await _setCurrentUser(account);
      return AuthResult.success;
    } catch (_) {
      return AuthResult.error;
    }
  }

  // ── Reset password ────────────────────────────────────────────────────────────
  static Future<bool> resetPassword({
    required String rollNumber,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roll = rollNumber.trim().toUpperCase();
      final raw = prefs.getString(_accountsKey);
      if (raw == null) return false;
      final Map<String, dynamic> accounts = jsonDecode(raw);
      if (!accounts.containsKey(roll)) return false;
      accounts[roll]['passwordHash'] = _hashPassword(newPassword);
      await prefs.setString(_accountsKey, jsonEncode(accounts));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // ── Get current user ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentUserKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  static Future<Map<String, String>> getCachedUserData() async {
    final user = await getCurrentUser();
    if (user == null) return {};
    return {
      'rollNumber': user['rollNumber'] ?? '',
      'fullName': user['fullName'] ?? '',
      'department': user['department'] ?? '',
      'yearSection': user['yearSection'] ?? '',
      'email': user['email'] ?? '',
      'phone': user['phone'] ?? '',
    };
  }

  static Future<void> _setCurrentUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user));
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'secure_attend_salt');
    return sha256.convert(bytes).toString();
  }
}

enum AuthResult {
  success,
  alreadyRegistered,
  weakPassword,
  invalidCredentials,
  wrongDevice,
  notRegistered,
  error,
}

extension AuthResultMessage on AuthResult {
  String get message {
    switch (this) {
      case AuthResult.success:
        return 'Success!';
      case AuthResult.alreadyRegistered:
        return 'Already registered. Please sign in.';
      case AuthResult.weakPassword:
        return 'Password must be at least 6 characters.';
      case AuthResult.invalidCredentials:
        return 'Incorrect roll number or password.';
      case AuthResult.wrongDevice:
        return 'This device is not registered to your account.';
      case AuthResult.notRegistered:
        return 'Account not found. Please register first.';
      case AuthResult.error:
        return 'Something went wrong. Please try again.';
    }
  }

  bool get isSuccess => this == AuthResult.success;
}
