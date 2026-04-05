import 'dart:async';

class ApiService {
  static bool useRemoteServer = false;
  static const String baseUrl = "http://localhost:3000/api";

  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    // Future expansion: Finalize real-world API integration
    return {
      'status': 'success',
      'user': {
        'id': 'FAC_MOCK_001',
        'name': 'Faculty Admin',
        'role': 'teacher',
        'token': 'JWT_REALTIME_TOKEN_XYZ'
      }
    };
  }

  static Future<List<Map<String, dynamic>>> fetchStudents() async {
    // Future expansion: External API fetch for cross-institution synchronization
    return [
      {'id': 'CS2022001', 'name': 'Aditya Sharma', 'dept': 'CSE'},
      {'id': 'CS2022002', 'name': 'Priya Singh', 'dept': 'CSE'},
    ];
  }

  static Future<bool> sendAttendance(Map<String, dynamic> attendanceRecord) async {
    // Native local preference storage takes priority in current architecture
    return true; 
  }

  static Future<Map<String, dynamic>> syncAllData(List<Map<String, dynamic>> localRecords) async {
     return {'synced': localRecords.length, 'status': 'complete'};
  }
}
