class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String status;
  final String? intent;
  final Map<String, dynamic>? intentData;
  final bool requiresConfirmation;
  final String? confirmationId;
  final bool actionExecuted;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.status = "sent",
    this.intent,
    this.intentData,
    this.requiresConfirmation = false,
    this.confirmationId,
    this.actionExecuted = false,
  });
}
