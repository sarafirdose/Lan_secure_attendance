import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import 'network_service.dart';
import 'auth_service.dart';

class AttendanceDataService {
  static final String _baseUrl = NetworkService.baseUrl;

  static const List<Map<String, dynamic>> timetable = [
    // MONDAY
    {'day': 'MON', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {'day': 'MON', 'slot': '11:00 - 12:00', 'code': 'IoT', 'name': 'Internet of Things'},
    {'day': 'MON', 'slot': '12:15 - 1:15', 'code': 'BDA', 'name': 'Big Data Analytics'},
    {'day': 'MON', 'slot': '2:15 - 3:15', 'code': 'FCD', 'name': 'Full Stack Cloud Dev'},
    {'day': 'MON', 'slot': '4:15 - 5:00', 'code': 'E-III', 'name': 'Deep Learning (SS)'},
    // TUESDAY
    {'day': 'TUE', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {'day': 'TUE', 'slot': '11:00 - 12:00', 'code': 'IoT', 'name': 'Internet of Things'},
    {'day': 'TUE', 'slot': '12:15 - 1:15', 'code': 'BDA', 'name': 'Big Data Analytics'},
    {'day': 'TUE', 'slot': '2:15 - 3:15', 'code': 'BDA', 'name': 'BDA Lab'},
    {'day': 'TUE', 'slot': '3:15 - 4:15', 'code': 'BDA', 'name': 'BDA Lab'},
    {'day': 'TUE', 'slot': '4:15 - 5:00', 'code': 'E-III', 'name': 'Deep Learning (SS)'},
    // WEDNESDAY
    {'day': 'WED', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {'day': 'WED', 'slot': '11:00 - 12:00', 'code': 'IoT', 'name': 'Internet of Things'},
    {'day': 'WED', 'slot': '12:15 - 1:15', 'code': 'BDA', 'name': 'Big Data Analytics'},
    {'day': 'WED', 'slot': '2:15 - 3:15', 'code': 'FCD', 'name': 'Full Stack Cloud Dev'},
    // THURSDAY
    {'day': 'THU', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {'day': 'THU', 'slot': '11:00 - 12:00', 'code': 'IoT', 'name': 'Internet of Things'},
    {'day': 'THU', 'slot': '12:15 - 1:15', 'code': 'FCD', 'name': 'FCD Lab'},
    {'day': 'THU', 'slot': '2:15 - 3:15', 'code': 'FCD', 'name': 'FCD Lab'},
    {'day': 'THU', 'slot': '3:15 - 4:15', 'code': 'IoT', 'name': 'Internet of Things'},
    // FRIDAY
    {'day': 'FRI', 'slot': '10:00 - 11:00', 'code': 'E-III', 'name': 'Deep Learning'},
    {'day': 'FRI', 'slot': '11:00 - 12:00', 'code': 'FCD', 'name': 'Full Stack Cloud Dev'},
    {'day': 'FRI', 'slot': '12:15 - 1:15', 'code': 'BDA', 'name': 'Big Data Analytics'},
    {'day': 'FRI', 'slot': '2:15 - 3:15', 'code': 'AppDev', 'name': 'App Dev (SS)'},
  ];

  static List<Map<String, dynamic>> getTodayClasses() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final todayIdx = DateTime.now().weekday - 1;
    if (todayIdx < 0 || todayIdx >= 5) return [];
    final today = days[todayIdx];
    return timetable.where((t) => t['day'] == today).toList();
  }

  static List<SubjectAttendance>? _cachedData;

  /// Sync attendance data from backend. If offline or error, use fallback mock data.
  static Future<List<SubjectAttendance>> syncAttendanceData() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return getMockAttendance();

    try {
      final token = await AuthService.getToken();
      final res = await http.get(
        Uri.parse('$_baseUrl/attendance-summary?rollNumber=${user['uid']}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        if (data['success'] == true) {
          final List<dynamic> report = data['subjects'] ?? [];
          final synced = report.map((item) {
            return SubjectAttendance(
              subjectCode: item['subject'] ?? 'UNK',
              subjectName: _getSubjectName(item['subject']),
              totalClasses: item['total'] ?? 0,
              attendedClasses: item['attended'] ?? 0,
              lateClasses: 0, // Backend logic can be expanded
              recentRecords: [], // Optional: Fetch full history if needed
            );
          }).toList();
          
          _cachedData = synced;
          return synced;
        }
      }
    } catch (e) {
      NetworkService.logger.e("Sync Error: $e");
    }

    return _cachedData ?? getMockAttendance();
  }

  static String _getSubjectName(String code) {
    try {
      return timetable.firstWhere((t) => t['code'] == code)['name'];
    } catch (_) {
      return code;
    }
  }

  static List<SubjectAttendance> getMockAttendance() {
    _cachedData ??= [
      SubjectAttendance(
        subjectCode: 'E-IV',
        subjectName: 'NLP',
        totalClasses: 38,
        attendedClasses: 32,
        recentRecords: [],
      ),
      SubjectAttendance(
        subjectCode: 'IoT',
        subjectName: 'Internet of Things',
        totalClasses: 40,
        attendedClasses: 35,
        recentRecords: [],
      ),
      SubjectAttendance(
        subjectCode: 'BDA',
        subjectName: 'Big Data Analytics',
        totalClasses: 45,
        attendedClasses: 33,
        recentRecords: [],
      ),
      SubjectAttendance(
        subjectCode: 'FCD',
        subjectName: 'Full Stack Cloud Dev',
        totalClasses: 42,
        attendedClasses: 38,
        recentRecords: [],
      ),
    ];
    return _cachedData!;
  }

  static Future<void> markAttendance(String subjectCodeOrName) async {
    // For demo/mock mode, update the cache
    getMockAttendance(); // Ensures _cachedData is initialized
    
    for (int i = 0; i < _cachedData!.length; i++) {
      if (_cachedData![i].subjectCode == subjectCodeOrName || _cachedData![i].subjectName == subjectCodeOrName) {
        _cachedData![i] = SubjectAttendance(
          subjectCode: _cachedData![i].subjectCode,
          subjectName: _cachedData![i].subjectName,
          totalClasses: _cachedData![i].totalClasses,
          attendedClasses: _cachedData![i].attendedClasses + 1,
          recentRecords: _cachedData![i].recentRecords,
        );
      }
    }
  }
}

