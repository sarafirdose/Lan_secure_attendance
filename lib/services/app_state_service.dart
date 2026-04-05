import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';
import 'network_service.dart';

enum SystemStatus { normal, warning, error }

class AppStateService extends ChangeNotifier {
  // Singleton Pattern
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();

  String? _role;
  dynamic _currentUser;
  String? _token;
  AttendanceSession? _activeSession;
  SystemStatus _status = SystemStatus.normal;

  static final String _baseUrl = NetworkService.baseUrl;

  // Getters
  String? get role => _role;
  dynamic get currentUser => _currentUser;
  String? get token => _token;
  AttendanceSession? get activeSession => _activeSession;
  SystemStatus get status => _status;

  /// Returns the UID of the currently logged-in user.
  String? get userId {
    if (_currentUser == null) return null;
    if (_currentUser is Map) return _currentUser['uid']?.toString();
    return null;
  }

  Future<bool> pingServer() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        _status = SystemStatus.normal;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    _status = SystemStatus.error;
    notifyListeners();
    return false;
  }

  // Global Messenger Key for AI Action Engine
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void setAuth(dynamic user, String userRole, String? userToken) {
    _currentUser = user;
    _role = userRole;
    _token = userToken;
    notifyListeners();
  }

  void setCurrentUser(String id, String role) {
    setAuth({'uid': id, 'name': 'User $id'}, role, null);
  }

  void setActiveSession(AttendanceSession? session) {
    _activeSession = session;
    notifyListeners();
  }

  void updateStatus(SystemStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void clearState() {
    _currentUser = null;
    _role = null;
    _activeSession = null;
    _status = SystemStatus.normal;
    notifyListeners();
  }

  bool get isAuthenticated => _currentUser != null && _role != null;
  bool get hasActiveSession => _activeSession != null && _activeSession!.active;
}
