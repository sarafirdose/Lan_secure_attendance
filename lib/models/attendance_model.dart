class AttendanceRecord {
  final DateTime date;
  final AttendanceStatus status;
  final String subjectCode;
  final String topic;
  final String day;
  final String time;

  AttendanceRecord({
    required this.date,
    required this.status,
    required this.subjectCode,
    this.topic = '',
    this.day = '',
    this.time = '',
  });
}

enum AttendanceStatus { present, absent, late }

enum AttendanceHealth { safe, warning, danger }

class SubjectAttendance {
  final String subjectCode;
  final String subjectName;
  final int totalClasses;
  final int attendedClasses;
  final int lateClasses;
  final List<AttendanceRecord> recentRecords;

  const SubjectAttendance({
    required this.subjectCode,
    required this.subjectName,
    required this.totalClasses,
    required this.attendedClasses,
    this.lateClasses = 0,
    this.recentRecords = const [],
  });

  // Aliases so portal screen works with both .name and .subjectName
  String get name => subjectName;
  String get code => subjectCode;

  int get lateCount => lateClasses;
  int get absentClasses => totalClasses - attendedClasses - lateClasses;
  int get missedClasses => totalClasses - attendedClasses;

  double get percentage =>
      totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;

  AttendanceHealth get health {
    if (percentage >= 75) return AttendanceHealth.safe;
    if (percentage >= 65) return AttendanceHealth.warning;
    return AttendanceHealth.danger;
  }

  int classesNeededFor(double target) {
    if (percentage >= target) return 0;
    int needed = 0;
    int attended = attendedClasses;
    int total = totalClasses;
    while (total > 0 && (attended / total) * 100 < target) {
      attended++;
      total++;
      needed++;
    }
    return needed;
  }

  int howManyCanMiss(double target) {
    if (percentage < target) return 0;
    int canMiss = 0;
    int attended = attendedClasses;
    int total = totalClasses;
    while (total > 0 && ((attended / (total + 1)) * 100 >= target)) {
      total++;
      canMiss++;
    }
    return canMiss;
  }

  // Keep old method name for compatibility
  int classesNeededFor75() => classesNeededFor(75);

  SubjectAttendance copyWith({
    String? subjectCode,
    String? subjectName,
    int? totalClasses,
    int? attendedClasses,
    int? lateClasses,
    List<AttendanceRecord>? recentRecords,
  }) {
    return SubjectAttendance(
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      totalClasses: totalClasses ?? this.totalClasses,
      attendedClasses: attendedClasses ?? this.attendedClasses,
      lateClasses: lateClasses ?? this.lateClasses,
      recentRecords: recentRecords ?? this.recentRecords,
    );
  }
}
