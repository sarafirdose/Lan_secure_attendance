import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'app_state_service.dart';
import 'sync_service.dart';
import 'network_service.dart';
import 'sa_security_service.dart';

enum AuthResult { success, alreadyRegistered, invalidCredentials, wrongDevice, notRegistered, error }

class AuthService {
  static final String _baseUrl = NetworkService.baseUrl;
  static const String _tokenKey = 'sa_auth_token';
  static const String _userKey = 'sa_auth_user';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> refreshToken() async {
    try {
      final user = AppStateService().currentUser;
      if (user == null) return false;
      
      final refreshToken = await SaSecurityService().getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;
      
      final res = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['access_token'] != null) {
          await _saveAuth(data['access_token'], refreshToken, user);
          AppStateService().setAuth(user, user['role'], data['access_token']);
          return true;
        }
      }
    } catch (_) { }
    return false; // Force logout logic via interceptor if this fails heavily
  }

  // ── Centralized API Auth ───────────────────────────────────────────────────
  static Future<AuthResult> signIn({
    required String rollNumber,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': rollNumber.trim().toUpperCase(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['access_token']; // Use access_token instead of token
        final refreshToken = data['refresh_token'] ?? '';
        final user = data['user'];
        
        if (token != null) {
          await _saveAuth(token, refreshToken, user);
          AppStateService().setAuth(user, user['role'], token);
        }
        
        return AuthResult.success;
      } else if (res.statusCode == 401) {
        return AuthResult.invalidCredentials;
      }
      return AuthResult.error;
    } catch (_) {
      // Offline? Check cache
      return _tryCachedLogin(rollNumber, password);
    }
  }

  static Future<AuthResult> register({
    required String rollNumber,
    required String fullName,
    required String department,
    String? yearSection,
    required String password,
    required String role,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': rollNumber.trim().toUpperCase(),
          'name': fullName,
          'role': role,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return await signIn(rollNumber: rollNumber, password: password);
      }
      return AuthResult.error;
    } catch (_) {
      // If offline, we can't register securely without server ID sync
      return AuthResult.error;
    }
  }

  static Future<AuthResult> signInAdmin({
    required String adminId,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': adminId.trim().toUpperCase(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['access_token'];
        final refreshToken = data['refresh_token'] ?? '';
        final user = data['user'];
        if (token != null) {
          await _saveAuth(token, refreshToken, user);
          AppStateService().setAuth(user, 'admin', token);
        }
        return AuthResult.success;
      }
      return AuthResult.invalidCredentials;
    } catch (_) {
       // Fallback for demo admins if offline
       if (adminId.toLowerCase() == 'admin' && password == 'admin123') {
           return AuthResult.success;
       }
       return AuthResult.error;
    }
  }

  // ── Migration & Offline Cache ───────────────────────────────────────────────
  static Future<AuthResult> _tryCachedLogin(String roll, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_userKey);
    if (cached != null) {
      final user = jsonDecode(cached);
      if (user['uid'] == roll.toUpperCase()) {
        final token = prefs.getString(_tokenKey);
        AppStateService().setAuth(user, user['role'], token);
        return AuthResult.success;
      }
    }
    return AuthResult.error;
  }

  static Future<void> _saveAuth(String token, String refreshToken, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
    await SaSecurityService().saveTokens(token, refreshToken);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await SaSecurityService().clearTokens();
    AppStateService().clearState();
  }

  // ── Legacy Restoration ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCurrentUser() async {
     return AppStateService().currentUser;
  }

  static Future<bool> isLoggedIn() async {
     return AppStateService().isAuthenticated;
  }

  static Future<Map<String, String>> getCachedUserData() async {
    final user = AppStateService().currentUser;
    if (user == null) {
      // Try loading from SharedPreferences if AppState is cleared
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_userKey);
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        AppStateService().setAuth(data, data['role'] ?? 'student', prefs.getString(_tokenKey));
        return {
          'rollNumber': data['uid'] ?? '',
          'fullName': data['name'] ?? '',
          'department': data['department'] ?? '',
          'yearSection': data['year_section'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? 'student',
        };
      }
      return {};
    }
    return {
      'rollNumber': user['uid'] ?? '',
      'fullName': user['name'] ?? '',
      'department': user['department'] ?? '',
      'yearSection': user['year_section'] ?? '',
      'email': user['email'] ?? '',
      'phone': user['phone'] ?? '',
      'role': user['role'] ?? 'student',
    };
  }

  /// Updates profile fields both locally (SharedPreferences) and on the backend.
  static Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? email,
  }) async {
    final user = AppStateService().currentUser;
    if (user == null) return false;

    // 1. Update in-memory
    final updated = Map<String, dynamic>.from(user);
    if (fullName != null && fullName.isNotEmpty) updated['name'] = fullName;
    if (phone != null && phone.isNotEmpty) updated['phone'] = phone;
    if (email != null && email.isNotEmpty) updated['email'] = email;

    // 2. Persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(updated));
    AppStateService().setAuth(updated, updated['role'] ?? 'student', await getToken());

    // 3. Attempt backend sync (non-blocking, no crash if offline)
    try {
      final token = await getToken();
      await http.post(
        Uri.parse('${NetworkService.baseUrl}/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer \$token',
        },
        body: jsonEncode({
          'uid': updated['uid'],
          if (fullName != null) 'name': fullName,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline → local save already done, backend will sync later
    }
    return true;
  }

  static void setCurrentUser(String id, String role) {
     AppStateService().setAuth({'uid': id, 'name': 'New User'}, role, null);
  }

  // ── Step 0: Data Migration ──────────────────────────────────────────────────
  static Future<void> runDataMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('sa_accounts');
    if (accountsJson == null) return;

    final Map<String, dynamic> accounts = jsonDecode(accountsJson);
    if (accounts.isEmpty) return;

    // Send to backend migration endpoint
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/migrate-data'),
        headers: {'Content-Type': 'application/json'},
        body: accountsJson,
      );

      if (res.statusCode == 200) {
        // Clear local storage ONLY after successful server migration
        await prefs.remove('sa_accounts');
      }
    } catch (_) {}
  }

  static Future<void> changePassword(String id, String newPassword) async {
    // API call or mock
  }

  static Future<bool> resetPassword({required String rollNumber, required String newPassword}) async {
    // API logic for forgot password flow
    return true;
  }
}

extension AuthResultMessage on AuthResult {
  String get message {
    switch (this) {
      case AuthResult.success: return 'Success!';
      case AuthResult.alreadyRegistered: return 'Already registered.';
      case AuthResult.invalidCredentials: return 'Invalid ID or password.';
      case AuthResult.wrongDevice: return 'This device is not yours.';
      case AuthResult.notRegistered: return 'User not found.';
      case AuthResult.error: return 'Connection error. Using local cache.';
    }
  }
  bool get isSuccess => this == AuthResult.success;
}
