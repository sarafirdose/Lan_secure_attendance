
class TeacherProfile {
  final String name;
  final String teacherId;
  final String department;
  final List<String> subjects;
  final String year;
  final String semester;
  final List<String> sections;
  final String email;
  final String deviceId;
  final DateTime updatedAt;

  TeacherProfile({
    required this.name,
    required this.teacherId,
    required this.department,
    required this.subjects,
    required this.year,
    required this.semester,
    required this.sections,
    required this.email,
    required this.deviceId,
    required this.updatedAt,
  });

  // Unique labels for restricted actions: "Department-Year-Section"
  List<String> get allowedClasses {
    return sections.map((s) => '$department-$year-$s').toList();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'teacherId': teacherId,
        'department': department,
        'subjects': subjects,
        'year': year,
        'semester': semester,
        'sections': sections,
        'email': email,
        'deviceId': deviceId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      name: json['name'] ?? 'Unknown Faculty',
      teacherId: json['teacherId'] ?? '',
      department: json['department'],
      subjects: List<String>.from(json['subjects']),
      year: json['year'],
      semester: json['semester'],
      sections: List<String>.from(json['sections']),
      email: json['email'] ?? '',
      deviceId: json['deviceId'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class TimetableEntry {
  final String entryId;
  final String day; // Monday, Tuesday, etc.
  final String startTime; // "09:00"
  final String endTime; // "10:00"
  final String subject;
  final String department;
  final String year;
  final String section;
  final String semester;

  TimetableEntry({
    required this.entryId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.department,
    required this.year,
    required this.section,
    required this.semester,
  });

  String get classLabel => '$department-$year-$section';

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'department': department,
        'year': year,
        'section': section,
        'semester': semester,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      entryId: json['entryId'],
      day: json['day'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      subject: json['subject'],
      department: json['department'],
      year: json['year'],
      section: json['section'],
      semester: json['semester'] ?? '1st',
    );
  }
}

class TeacherModel {
  final String id;
  final String name;
  final List<String> subjects;
  final List<String> assignedClasses;
  final String? deviceID;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeacherModel({
    required this.id,
    required this.name,
    required this.subjects,
    required this.assignedClasses,
    this.deviceID,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subjects': subjects,
    'assignedClasses': assignedClasses,
    'deviceID': deviceID,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subjects: List<String>.from(json['subjects'] ?? []),
      assignedClasses: List<String>.from(json['assignedClasses'] ?? []),
      deviceID: json['deviceID'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}
