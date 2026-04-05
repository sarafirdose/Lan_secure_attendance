class AIDecisionModel {
  final String actionType; // START_SESSION, CLOSE_SESSION, BLOCK_STUDENT, ALERT_RISK
  final String priority; // HIGH, MEDIUM, LOW
  final String reason;
  final double confidence; // 0.0 - 100.0
  final String patternTag; // declining, improving, irregular
  final DateTime timestamp;
  final String? pendingActionId;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  AIDecisionModel({
    required this.actionType,
    required this.priority,
    required this.reason,
    required this.confidence,
    required this.patternTag,
    required this.timestamp,
    this.pendingActionId,
    this.expiresAt,
    this.metadata,
  });

  bool get canAutoExecute => confidence >= 70.0;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType,
      'priority': priority,
      'reason': reason,
      'confidence': confidence,
      'patternTag': patternTag,
      'timestamp': timestamp.toIso8601String(),
      'pendingActionId': pendingActionId,
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}
