import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'network_service.dart';
import 'app_state_service.dart';
import '../models/chat_message.dart';

class ChatService {
  static const _uuid = Uuid();

  static Future<ChatMessage> sendMessage(String message) async {
    final baseUrl = NetworkService.baseUrl;
    final token = AppStateService().token;
    
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "message": message,
          "idempotency_key": _uuid.v4(),
        }),
      ).timeout(const Duration(seconds: 120));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ChatMessage(
          text: data['reply'],
          isUser: false,
          timestamp: DateTime.now(),
          intent: data['intent'],
          intentData: data['data'],
          requiresConfirmation: data['requires_confirmation'] ?? false,
          confirmationId: data['confirmation_id'],
          actionExecuted: data['action_executed'] ?? false,
        );
      } else {
        return ChatMessage(
          text: data['reply'] ?? "Error: ${response.statusCode} - Action Denied.",
          isUser: false,
          timestamp: DateTime.now(),
          status: "error",
        );
      }
    } catch (e) {
      return ChatMessage(
        text: "I'm taking a bit longer to process this, buddy! 🤖 Just a quick second while I reach my brain (Network/Timeout). Please try sending your message again!",
        isUser: false,
        timestamp: DateTime.now(),
        status: "error",
      );
    }
  }

  static Future<ChatMessage> confirmAction(String confirmationId, bool confirmed) async {
    final baseUrl = NetworkService.baseUrl;
    final token = AppStateService().token;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat/confirm"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "confirmation_id": confirmationId,
          "confirmed": confirmed,
          "idempotency_key": _uuid.v4(),
        }),
      ).timeout(const Duration(seconds: 60));

      final data = jsonDecode(response.body);
      return ChatMessage(
        text: data['reply'],
        isUser: false,
        timestamp: DateTime.now(),
        actionExecuted: data['action_executed'] ?? false,
      );
    } catch (e) {
      return ChatMessage(
        text: "Critical failure during confirmation handshake.",
        isUser: false,
        timestamp: DateTime.now(),
        status: "error",
      );
    }
  }
}
