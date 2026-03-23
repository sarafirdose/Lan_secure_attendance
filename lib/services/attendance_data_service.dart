import '../models/attendance_model.dart';

class AttendanceDataService {
  static const List<Map<String, dynamic>> timetable = [
    // MONDAY
    {'day': 'MON', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {
      'day': 'MON',
      'slot': '11:00 - 12:00',
      'code': 'IoT',
      'name': 'Internet of Things'
    },
    {
      'day': 'MON',
      'slot': '12:15 - 1:15',
      'code': 'BDA',
      'name': 'Big Data Analytics'
    },
    {
      'day': 'MON',
      'slot': '2:15 - 3:15',
      'code': 'FCD',
      'name': 'Full Stack Cloud Dev'
    },
    {
      'day': 'MON',
      'slot': '4:15 - 5:00',
      'code': 'E-III',
      'name': 'Deep Learning (SS)'
    },
    // TUESDAY
    {'day': 'TUE', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {
      'day': 'TUE',
      'slot': '11:00 - 12:00',
      'code': 'IoT',
      'name': 'Internet of Things'
    },
    {
      'day': 'TUE',
      'slot': '12:15 - 1:15',
      'code': 'BDA',
      'name': 'Big Data Analytics'
    },
    {'day': 'TUE', 'slot': '2:15 - 3:15', 'code': 'BDA', 'name': 'BDA Lab'},
    {'day': 'TUE', 'slot': '3:15 - 4:15', 'code': 'BDA', 'name': 'BDA Lab'},
    {
      'day': 'TUE',
      'slot': '4:15 - 5:00',
      'code': 'E-III',
      'name': 'Deep Learning (SS)'
    },
    // WEDNESDAY
    {'day': 'WED', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {
      'day': 'WED',
      'slot': '11:00 - 12:00',
      'code': 'IoT',
      'name': 'Internet of Things'
    },
    {
      'day': 'WED',
      'slot': '12:15 - 1:15',
      'code': 'BDA',
      'name': 'Big Data Analytics'
    },
    {
      'day': 'WED',
      'slot': '2:15 - 3:15',
      'code': 'FCD',
      'name': 'Full Stack Cloud Dev'
    },
    // THURSDAY
    {'day': 'THU', 'slot': '10:00 - 11:00', 'code': 'E-IV', 'name': 'NLP'},
    {
      'day': 'THU',
      'slot': '11:00 - 12:00',
      'code': 'IoT',
      'name': 'Internet of Things'
    },
    {'day': 'THU', 'slot': '12:15 - 1:15', 'code': 'FCD', 'name': 'FCD Lab'},
    {'day': 'THU', 'slot': '2:15 - 3:15', 'code': 'FCD', 'name': 'FCD Lab'},
    {
      'day': 'THU',
      'slot': '3:15 - 4:15',
      'code': 'IoT',
      'name': 'Internet of Things'
    },
    // FRIDAY
    {
      'day': 'FRI',
      'slot': '10:00 - 11:00',
      'code': 'E-III',
      'name': 'Deep Learning'
    },
    {
      'day': 'FRI',
      'slot': '11:00 - 12:00',
      'code': 'FCD',
      'name': 'Full Stack Cloud Dev'
    },
    {
      'day': 'FRI',
      'slot': '12:15 - 1:15',
      'code': 'BDA',
      'name': 'Big Data Analytics'
    },
    {
      'day': 'FRI',
      'slot': '2:15 - 3:15',
      'code': 'AppDev',
      'name': 'App Dev (SS)'
    },
  ];

  static List<Map<String, dynamic>> getTodayClasses() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final todayIdx = DateTime.now().weekday - 1;
    if (todayIdx >= 5) return [];
    final today = days[todayIdx];
    return timetable.where((t) => t['day'] == today).toList();
  }

  static List<SubjectAttendance> getMockAttendance() {
    return [
      SubjectAttendance(
        subjectCode: 'E-IV',
        subjectName: 'NLP',
        totalClasses: 38,
        attendedClasses: 32,
        lateClasses: 1,
        recentRecords: [
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 1)),
              status: AttendanceStatus.present,
              subjectCode: 'E-IV',
              topic: 'Word Embeddings',
              day: 'MON',
              time: '10:00 AM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 8)),
              status: AttendanceStatus.absent,
              subjectCode: 'E-IV',
              topic: 'BERT Architecture',
              day: 'MON',
              time: '10:00 AM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 15)),
              status: AttendanceStatus.late,
              subjectCode: 'E-IV',
              topic: 'Tokenization',
              day: 'MON',
              time: '10:00 AM'),
        ],
      ),
      SubjectAttendance(
        subjectCode: 'IoT',
        subjectName: 'Internet of Things',
        totalClasses: 40,
        attendedClasses: 35,
        lateClasses: 2,
        recentRecords: [
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 1)),
              status: AttendanceStatus.present,
              subjectCode: 'IoT',
              topic: 'MQTT Protocol',
              day: 'MON',
              time: '11:00 AM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 3)),
              status: AttendanceStatus.late,
              subjectCode: 'IoT',
              topic: 'Sensor Networks',
              day: 'WED',
              time: '11:00 AM'),
        ],
      ),
      SubjectAttendance(
        subjectCode: 'BDA',
        subjectName: 'Big Data Analytics',
        totalClasses: 45,
        attendedClasses: 33,
        lateClasses: 0,
        recentRecords: [
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 2)),
              status: AttendanceStatus.absent,
              subjectCode: 'BDA',
              topic: 'Hadoop MapReduce',
              day: 'TUE',
              time: '12:15 PM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 5)),
              status: AttendanceStatus.present,
              subjectCode: 'BDA',
              topic: 'Spark Streaming',
              day: 'FRI',
              time: '12:15 PM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 9)),
              status: AttendanceStatus.absent,
              subjectCode: 'BDA',
              topic: 'Kafka',
              day: 'TUE',
              time: '2:15 PM'),
        ],
      ),
      SubjectAttendance(
        subjectCode: 'FCD',
        subjectName: 'Full Stack Cloud Dev',
        totalClasses: 42,
        attendedClasses: 38,
        lateClasses: 1,
        recentRecords: [
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 1)),
              status: AttendanceStatus.present,
              subjectCode: 'FCD',
              topic: 'Docker & Kubernetes',
              day: 'MON',
              time: '2:15 PM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 4)),
              status: AttendanceStatus.present,
              subjectCode: 'FCD',
              topic: 'React Hooks',
              day: 'THU',
              time: '12:15 PM'),
        ],
      ),
      SubjectAttendance(
        subjectCode: 'AppDev',
        subjectName: 'App Dev (SS)',
        totalClasses: 20,
        attendedClasses: 17,
        lateClasses: 0,
        recentRecords: [
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 3)),
              status: AttendanceStatus.present,
              subjectCode: 'AppDev',
              topic: 'Flutter State Management',
              day: 'FRI',
              time: '2:15 PM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 10)),
              status: AttendanceStatus.absent,
              subjectCode: 'AppDev',
              topic: 'Firebase Integration',
              day: 'FRI',
              time: '2:15 PM'),
        ],
      ),
      SubjectAttendance(
        subjectCode: 'E-III',
        subjectName: 'Deep Learning',
        totalClasses: 35,
        attendedClasses: 28,
        lateClasses: 1,
        recentRecords: [
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 2)),
              status: AttendanceStatus.present,
              subjectCode: 'E-III',
              topic: 'CNN Architectures',
              day: 'FRI',
              time: '10:00 AM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 7)),
              status: AttendanceStatus.absent,
              subjectCode: 'E-III',
              topic: 'Backpropagation',
              day: 'MON',
              time: '4:15 PM'),
          AttendanceRecord(
              date: DateTime.now().subtract(const Duration(days: 14)),
              status: AttendanceStatus.late,
              subjectCode: 'E-III',
              topic: 'RNN & LSTM',
              day: 'TUE',
              time: '4:15 PM'),
        ],
      ),
    ];
  }
}
