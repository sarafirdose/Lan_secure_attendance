class FraudLogModel {
  final String studentID;
  final String issueType;
  final DateTime timestamp;
  final String description;
  final String severity; // low, medium, high

  FraudLogModel({
    required this.studentID,
    required this.issueType,
    required this.timestamp,
    required this.description,
    this.severity = 'low', 
  });

  Map<String, dynamic> toJson() => {
    'studentID': studentID,
    'issueType': issueType,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
    'severity': severity,
  };

  factory FraudLogModel.fromJson(Map<String, dynamic> json) {
    return FraudLogModel(
      studentID: json['studentID'] ?? '',
      issueType: json['issueType'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'low',
    );
  }
}
