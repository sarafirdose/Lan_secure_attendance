class StudentModel {
  final String id;
  final String name;
  final String department;
  final String year;
  final String semester;
  final String section;
  final String? deviceID;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.department,
    required this.year,
    required this.semester,
    required this.section,
    this.deviceID,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'department': department,
    'year': year,
    'semester': semester,
    'section': section,
    'deviceID': deviceID,
    'isBlocked': isBlocked,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      year: json['year'] ?? '',
      semester: json['semester'] ?? '',
      section: json['section'] ?? '',
      deviceID: json['deviceID'],
      isBlocked: json['isBlocked'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}
