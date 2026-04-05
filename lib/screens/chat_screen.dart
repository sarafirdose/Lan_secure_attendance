import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/app_state_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  bool _isConfirmationPending = false; // Locks input during confirmation
  String? _lastIntent; // For contextual suggestions

  @override
  void initState() {
    super.initState();
    final role = AppStateService().role ?? 'student';
    _messages.add(ChatMessage(
      text: _getGreeting(role),
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  String _getGreeting(String role) {
    if (role == 'teacher') return "Hey Professor! I'm here to handle the boring stuff—scheduling, attendance, and spotting defaulters. What are we doing today? 🎓";
    if (role == 'admin')   return "System Check: Operational. Hello Admin! Want to see some analytics or check system security? 🛡️";
    return "Hey buddy! I'm your University AI Assistant. Want to know your attendance percentage or see how many classes you can skip? Just ask me! 🚀";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? predefinedMsg]) async {
    final text = predefinedMsg ?? _msgCtrl.text.trim();
    if (text.isEmpty) return;

    // Elite: Allow "Explain Action" even if a real action is pending
    if (_isConfirmationPending && text != "Explain Action") return;

    _msgCtrl.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();

    final reply = await ChatService.sendMessage(text);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(reply);
      _lastIntent = reply.intent;
      if (reply.requiresConfirmation && !reply.actionExecuted) {
        _isConfirmationPending = true;
      }
    });
    _scrollToBottom();
  }

  Future<void> _handleConfirm(String confirmationId, bool confirmed) async {
    // Mark the message's confirmation as "processing" so buttons disappear
    final idx = _messages.lastIndexWhere((m) => m.confirmationId == confirmationId);
    if (idx != -1) {
      final old = _messages[idx];
      setState(() {
        _messages[idx] = ChatMessage(
          text: old.text, isUser: false, timestamp: old.timestamp,
          intent: old.intent, intentData: old.intentData,
          requiresConfirmation: true, confirmationId: old.confirmationId,
          actionExecuted: true, // Hides buttons immediately
        );
        _isTyping = true;
        _isConfirmationPending = false;
      });
    }
    _scrollToBottom();

    final result = await ChatService.confirmAction(confirmationId, confirmed);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(result);
      // Update contextual suggestions after executions
      if (result.actionExecuted) {
        _lastIntent = 'completed_${_lastIntent ?? ''}';
      }
    });
    _scrollToBottom();
  }

  // ── Role Headers & Suggestions ────────────────────────────────────────────
  String get _headerTitle {
    final role = AppStateService().role ?? 'student';
    if (role == 'teacher') return 'Teacher Assistant';
    if (role == 'admin')   return 'Admin Control AI';
    return 'Student AI Assistant';
  }

  List<String> get _contextualSuggestions {
    final role = AppStateService().role ?? 'student';
    final List<String> suggestions = [];

    // 1. Logic for Proposing (Explain)
    if (_isConfirmationPending) {
      suggestions.add('Explain Action');
    }

    // 2. Logic for Completed Actions (Undo)
    if (_lastIntent != null && _lastIntent!.startsWith('completed_')) {
      suggestions.add('Undo Last Action');
    }

    // 3. Dynamic Suggestions based on intent (Filtered by Role)
    if (role == 'teacher') {
      suggestions.addAll(['Class Defaulters', 'Next Session Stats', 'Security Check']);
    } else if (role == 'student') {
      suggestions.addAll(['How many more classes?', 'Can I skip today?', 'Exam Prep Info']);
    } else if (role == 'admin') {
      suggestions.addAll(['System Security', 'Analytics Overview', 'Blocked Users']);
    }

    // 4. Fill with defaults if empty
    if (suggestions.isEmpty) {
      suggestions.addAll(_defaultSuggestions(role));
    }

    return suggestions.take(4).toList(); // Keep it clean
  }

  List<String> _defaultSuggestions(String role) {
    if (role == 'teacher') return ['Mark Attendance', 'Schedule Class', 'Defaulter List'];
    if (role == 'admin') return ['System Reports', 'Active Users', 'Generate Analytics'];
    return ['My Attendance %', 'Exam Schedule', 'Apply Leave'];
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) return _buildTypingIndicator();
                final msg = _messages[index];
                return ChatBubble(
                  message: msg,
                  onConfirm: _handleConfirm,
                );
              },
            ),
          ),
          _buildQuickSuggestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(_headerTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0056B3))),
        ],
      ),
      actions: [
        if (_isConfirmationPending)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Row(
              children: [
                Icon(Icons.pending_actions_rounded, size: 14, color: Color(0xFFF59E0B)),
                SizedBox(width: 4),
                Text("Action Pending", style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _contextualSuggestions.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF2C2C2C)),
                label: Text(s, style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2C))),
                backgroundColor: const Color(0xFFEEF2FF),
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                onPressed: () => _sendMessage(s),
              ).animate().fadeIn(delay: 300.ms),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  width: 6, height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle),
                ).animate(onPlay: (c) => c.repeat()).fade(
                  duration: 600.ms, delay: Duration(milliseconds: i * 200), curve: Curves.easeInOut,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isLocked = _isConfirmationPending || _isTyping;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        left: 12, right: 12, top: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mic icon (voice input UI placeholder)
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🎤 Voice input coming soon!"), duration: Duration(seconds: 2)),
            ),
            child: Container(
              width: 44, height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                border: Border.all(color: const Color(0xFFC7D2FE)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.mic_rounded, color: Color(0xFF2C2C2C), size: 20),
            ),
          ),
          // Text field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isLocked ? const Color(0xFFFFFFFF) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isLocked ? const Color(0xFFCBD5E1) : const Color(0xFFC7D2FE),
                ),
              ),
              child: TextField(
                controller: _msgCtrl,
                enabled: !isLocked,
                minLines: 1, maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: isLocked ? "Respond to confirmation above..." : "Type a message or command...",
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: isLocked ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48, width: 48,
              decoration: BoxDecoration(
                gradient: isLocked
                  ? null
                  : const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF7C3AED)]),
                color: isLocked ? const Color(0xFFCBD5E1) : null,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
