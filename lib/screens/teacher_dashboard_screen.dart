import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/demo_state_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/network_service.dart';
import 'package:intl/intl.dart';
import '../services/app_state_service.dart';
import '../models/session_model.dart';
import '../models/teacher_model.dart';
import '../services/session_service.dart';
import '../services/fraud_detection_service.dart';
import '../services/teacher_service.dart';
import 'teacher_select_class_screen.dart';
import 'teacher_analytics_screen.dart';
import 'fraud_detection_screen.dart';
import 'session_summary_screen.dart';
import 'teacher_profile_setup_screen.dart';
import 'timetable_manager_screen.dart';
import 'smart_attendance_edit_screen.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../services/ai_observer_service.dart';
import '../services/app_state_service.dart';
import '../widgets/system_status_badge.dart';
import '../services/teacher_intelligence_service.dart';
import '../services/notification_service.dart';
import 'teacher_qr_screen.dart';
import 'chat_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
        backgroundColor: const Color(0xFF0056B3),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        label: const Text('Ask Secure AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TeacherHomeTab(onTabChange: (i) => setState(() => _currentIndex = i)),
          const _TeacherHistoryTab(),
          const _TeacherProfileTab(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _navItem(
                  1, Icons.history_rounded, Icons.history_outlined, 'Sessions'),
              _navItem(2, Icons.person_rounded, Icons.person_outline_rounded,
                  'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0056B3).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? active : inactive,
              color: isSelected
                  ? const Color(0xFF0056B3)
                  : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF0056B3)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ——————————————————————————————————————————————————————————————————————————————————————————————————
// HOME TAB
// ——————————————————————————————————————————————————————————————————————————————————————————————————

class _TeacherHomeTab extends StatefulWidget {
  final void Function(int) onTabChange;
  const _TeacherHomeTab({required this.onTabChange});

  @override
  State<_TeacherHomeTab> createState() => _TeacherHomeTabState();
}

class _TeacherHomeTabState extends State<_TeacherHomeTab> {
  List<AttendanceSession> _recentSessions = [];
  int _todaySessions = 0;
  int _avgAttendance = 0;
  AttendanceSession? _activeSession;
  Timer? _refreshTimer;
  Map<String, dynamic>? _aiRecData;
  TimetableEntry? _currentSlot;
  TimetableEntry? _confirmationSlot;
  DateTime? _confirmationStartTime;
  Map<String, dynamic> _confidenceData = {};
  TeacherProfile? _profile;
  List<TimetableEntry> _todaySchedule = [];
  bool _showGlobalRisk = true;
  bool _reminderSent = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProfile();
    _loadData();
    _startTimer();
    DemoStateService().addListener(_onDemoUpdate);
  }

  @override
  void dispose() {
    DemoStateService().removeListener(_onDemoUpdate);
    _refreshTimer?.cancel();
    AIObserverService().stopWatching();
    super.dispose();
  }

  void _onDemoUpdate() {
    if (mounted) {
      setState(() {
        if (_activeSession != null) {
          _activeSession!.totalMarked = DemoStateService().demoAttendees.length;
        }
      });
    }
  }

  Future<void> _checkProfile() async {
    final profile = await TeacherService.getProfile();
    if (profile == null && mounted) {
      // Small delay to let the screen build
      Future.delayed(Duration.zero, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherProfileSetupScreen()),
        ).then((_) => _loadData());
      });
    }
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _loadSmartContext();
      _checkConfirmationTimeout();
      
      final active = AppStateService().activeSession;
      if (active != null && active.isActive) {
        // Smart Polling: Every 5 ticks (5 seconds), sync with backend
        if (t.tick % 5 == 0) {
          SessionService.syncActiveSession(active.sessionId).then((records) {
             if (records.isNotEmpty && mounted) {
                setState(() {
                  // Records synced via centralized model
                });
             }
          });
        }
      }

      // Connectivity Ping: Every 30 seconds
      if (t.tick % 30 == 0) {
        AppStateService().pingServer();
      }
    });
    _loadSmartContext();
    AIObserverService().startWatching(); // Background AI Loop Hook
  }

  void _checkConfirmationTimeout() {
    if (_confirmationSlot != null && _confirmationStartTime != null) {
      final elapsed = DateTime.now().difference(_confirmationStartTime!).inMinutes;
      
      // Step 1: Send Reminder at 5 minutes
      if (elapsed >= 5 && !_reminderSent) {
        setState(() => _reminderSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder: Please confirm your upcoming class soon.'), 
            backgroundColor: Color(0xFFF59E0B), 
            behavior: SnackBarBehavior.floating
          ),
        );
      }
      
      // Step 2: Auto-decline at 10 minutes (Class Time)
      if (elapsed >= 10) {
        _handleConfirmation(false, isTimeout: true);
      }
    }
  }

  Future<void> _loadSmartContext() async {
    final current = await TeacherService.getCurrentSlot();
    final timetable = await TeacherService.getTimetable();
    final confidence = await TeacherIntelligenceService.getConfidenceStats();
    
    final now = DateTime.now();
    for (final entry in timetable) {
      final dayCode = DateFormat('EEEE').format(now);
      if (entry.day != dayCode) continue;

      final startParts = entry.startTime.split(':');
      final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      final diff = start.difference(now).inMinutes;
      
      if (diff > 0 && diff <= 10 && _confirmationSlot == null && _activeSession == null) {
        _confirmationSlot = entry;
        _confirmationStartTime = now;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _currentSlot = current;
        _confidenceData = confidence;
      });
    }
  }


  Future<void> _loadData() async {
    final profile = await TeacherService.getProfile();
    final sessions = await SessionService.getPastSessions();
    final today = DateTime.now();
    _todaySessions = sessions.where((AttendanceSession s) =>
        s.startTime.year == today.year &&
        s.startTime.month == today.month &&
        s.startTime.day == today.day).length;

    int totalPresent = 0, totalStudents = 0;
    for (final s in sessions) {
      totalPresent += (s.presentCount + s.lateCount);
      totalStudents += s.students.length;
    }

    final active = await SessionService.getActiveSession();

    if (mounted) {
      setState(() {
        _profile = profile;
        _recentSessions = sessions.take(5).toList();
        _activeSession = active;
        _avgAttendance =
            totalStudents > 0 ? (totalPresent / totalStudents * 100).round() : 0;
        _isLoading = false;
      });
    }
    _fetchAIRecommendation();
  }

  Future<void> _fetchAIRecommendation() async {
    final uid = AppStateService().currentUser?['uid'];
    if (uid == null) return;
    
    try {
      final res = await http.get(Uri.parse('${NetworkService.baseUrl}/ai-smart-recommend?uid=$uid'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['recommendation'] != null) {
          setState(() {
            _aiRecData = data['recommendation'];
          });
        }
      }
    } catch (_) {}
  }


  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No sessions created today',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the button below to start tracking attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF424242), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildActiveSessionCard() {
    final sess = _activeSession!;
    final timeLeft = sess.timeLeft;
    final isCritical = timeLeft.inMinutes < 5;
    final progress = sess.totalMarked / (sess.students.isEmpty ? 1 : sess.students.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCritical ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFF6366F1).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCritical ? Colors.red : Colors.indigo).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE SESSION', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0056B3), letterSpacing: 1)),
                    Text('${sess.subject} (${sess.classLabel})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF000000), letterSpacing: -0.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_rounded, 
                            size: 16, 
                            color: isCritical ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9)),
                        const SizedBox(width: 8),
                        Text(
                          '${timeLeft.inMinutes.abs()}:${(timeLeft.inSeconds.abs() % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w900,
                            color: isCritical ? const Color(0xFFB91C1C) : const Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progress < 0.3 && sess.startTime.difference(DateTime.now()).inMinutes.abs() > 10) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                      child: const Text('LOW ATTENDANCE AI ALERT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Attendance Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${sess.totalMarked} / ${sess.students.length} Scanned',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF424242))),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF000000))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFFFFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(isCritical ? const Color(0xFFEF4444) : const Color(0xFF0056B3)),
            ),
          ),
          
          if (_aiRecData != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                children: [
                   const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF7C3AED)),
                   const SizedBox(width: 10),
                   Expanded(
                     child: Text("AI Suggests: Ensure students are ready for '${_aiRecData!['subject']}' next.",
                         style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B21B6))),
                   ),
                ],
              ),
            ).animate().shake(duration: 500.ms),
          ],
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _sessionButton(
                  'Extend +5m', 
                  () => _handleExtend(5),
                  Icons.more_time_rounded,
                  const Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(width: 12),
               Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _handleSubmitToAdmin,
                    icon: Icon(_activeSession!.syncStatus == SyncStatus.synced ? Icons.verified_user_rounded : Icons.cloud_upload_rounded, size: 16),
                    label: Text(_activeSession!.syncStatus == SyncStatus.synced ? 'Submitted' : 'Send to Admin', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeSession!.syncStatus == SyncStatus.synced ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                      foregroundColor: _activeSession!.syncStatus == SyncStatus.synced ? const Color(0xFF166534) : const Color(0xFF2C2C2C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
           SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleStop,
              icon: const Icon(Icons.stop_circle_rounded, size: 20),
              label: const Text('End Session Now', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.1).fadeIn();
  }

  Widget _buildAIRecommendationCard() {
    final rec = _aiRecData!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SMART SUGGESTION', 
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text("Start '${rec['subject']}' for ${rec['class_label']}?", 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _aiRecData = null),
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleAIStart(rec['subject'], rec['class_label']),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: const Text('START SESSION NOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2C2C2C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${(rec['confidence'] * 100).toInt()}% Match', 
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: 500.ms).fadeIn();
  }

  Future<void> _handleAIStart(String subject, String classLabel) async {
    final parts = classLabel.split('-');
    if (parts.length < 3) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherQRScreen(
          department: parts[0],
          year: parts[1],
          section: parts[2],
          subject: subject,
        ),
      ),
    );
    
    setState(() { _aiRecData = null; });
    _loadData();
  }

   Future<void> _handleSubmitToAdmin() async {
      if (_activeSession == null) return;
      
      setState(() { _activeSession!.syncStatus = SyncStatus.pending; });
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Finalizing & Submitting to Admin...'), backgroundColor: Color(0xFF2C2C2C), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
      );
 
      final success = await SessionService.finalizeAndSubmitSession(_activeSession!);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance Data Submitted Successfully!'), backgroundColor: Color(0xFF059669), behavior: SnackBarBehavior.floating),
          );
          // Auto-clear active session after successful submission to Admin
          await SessionService.endSession(_activeSession!);
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission Failed. Will try background retry.'), backgroundColor: Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
          );
        }
        setState(() {});
      }
   }

  Widget _sessionButton(String label, VoidCallback onTap, IconData icon, Color color, {bool isOutline = false}) {
    return SizedBox(
      height: 48,
      child: isOutline
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
    );
  }

  Future<void> _handleExtend(int mins) async {
    if (_activeSession == null) return;
    await SessionService.extendSession(_activeSession!, mins);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Session extended by $mins minutes'), backgroundColor: const Color(0xFF059669), behavior: SnackBarBehavior.floating),
    );
  }

  // ——————————————————————————————————————————————————————————————————————————————————————————————————
  Widget _buildAIConfirmationBanner() {
    if (_confirmationSlot == null) return const SizedBox.shrink();
    
    final slot = _confirmationSlot!;
    final score = (_confidenceData['score'] as double? ?? 0.0);
    final trend = _confidenceData['trend'] ?? 'neutral';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2C2C2C).withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2C2C).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 18),
              ),
              const SizedBox(width: 12),
              const Text('PRE-CLASS AI CONFIRMATION', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), letterSpacing: 1)),
              const Spacer(),
              _buildConfidenceBadge(score, trend),
            ],
          ),
          const SizedBox(height: 16),
          Text('${slot.subject} class at ${slot.startTime}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const Text('Will you conduct this session?',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          if (_confidenceData['explanation'] != null) ...[
            const SizedBox(height: 12),
            Text('Intelligence Link: ${_confidenceData['explanation']}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1), fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleConfirmation(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('YES, CONDUCTING', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ),
              if (_reminderSent) ...[
                const SizedBox(width: 8),
                const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 16),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleConfirmation(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2), // Light Red
                    foregroundColor: const Color(0xFFB91C1C), // Deep Red
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('NO, CANCEL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().shake(duration: 800.ms).fadeIn();
  }

  Widget _buildConfidenceBadge(double score, String trend) {
    Color color = score >= 0.7 ? const Color(0xFF059669) : (score >= 0.4 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend == 'up' ? Icons.trending_up_rounded : (trend == 'down' ? Icons.trending_down_rounded : Icons.trending_flat_rounded),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text('${(score * 100).toStringAsFixed(0)}% Confidence', 
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Future<void> _handleConfirmation(bool confirmed, {bool isTimeout = false}) async {
    if (_confirmationSlot == null) return;
    
    final subject = _confirmationSlot!.subject;
    final slot = '${_confirmationSlot!.department}-${_confirmationSlot!.year}-${_confirmationSlot!.section}';

    if (confirmed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherQRScreen(
            department: _confirmationSlot!.department,
            year: _confirmationSlot!.year,
            section: _confirmationSlot!.section,
            subject: _confirmationSlot!.subject,
          ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session Scheduled & Live Now ✓'), backgroundColor: Color(0xFF059669), behavior: SnackBarBehavior.floating),
      );
    } else {
      await SessionService.markNotConducted(_confirmationSlot!.subject, '${_confirmationSlot!.department}-${_confirmationSlot!.year}-${_confirmationSlot!.section}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session Marked: NOT CONDUCTED'), backgroundColor: Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
      );
    }

    setState(() {
      _confirmationSlot = null;
      _confirmationStartTime = null;
    });
    _loadData();
  }

  // ——————————————————————————————————————————————————————————————————————————————————————————————————
  Widget _buildSmartSuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2C2C2C).withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2C2C2C), size: 18),
              ),
              const SizedBox(width: 12),
              const Text('SMART SUGGESTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF2C2C2C), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Text('You have ${_currentSlot!.subject} (${_currentSlot!.section}) now.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
          const Text('Would you like to start the attendance session?',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleSmartStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Start Session Now', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Future<void> _handleSmartStart() async {
    if (_currentSlot == null) return;
    
    // Auto-fill and start
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherQRScreen(
          department: _currentSlot!.department,
          year: _currentSlot!.year,
          section: _currentSlot!.section,
          subject: _currentSlot!.subject,
        ),
      ),
    );
    
    _loadData(); // refresh
  }

  Future<void> _handleStop() async {
    if (_activeSession == null) return;
    await SessionService.endSession(_activeSession!);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session closed successfully'), backgroundColor: Color(0xFFFFFFFF), behavior: SnackBarBehavior.floating),
    );
  }

  // ——————————————————————————————————————————————————————————————————————————————————————————————————
  // ——————————————————————————————————————————————————————————————————————————————————————————————————
  Widget _buildSystemIntelligencePanel() {
    final atRisk = _recentSessions.where((s) => s.presentPercentage < 75).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // Dark Slate for premium look
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Intelligence', 
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('AI Insight Engine Active', 
                        style: TextStyle(fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ),
              Switch(
                value: _showGlobalRisk,
                activeThumbColor: const Color(0xFF059669),
                onChanged: (v) => setState(() => _showGlobalRisk = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _intelligenceMetric('At-Risk', '$atRisk Students', const Color(0xFFFB7185)),
              _intelligenceMetric('Integrity', '100%', const Color(0xFF34D399)),
              _intelligenceMetric('Alerts', '${FraudDetectionService.activeCount}', const Color(0xFFFBBF24)),
            ],
          ),
          if (atRisk > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFFB7185), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_rounded, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI PREDICTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFFB7185), letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('$atRisk students may fall below 75% threshold in ${_recentSessions.first.subject}.', 
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  // ——————————————————————————————————————————————————————————————————————————————————————————————————
  Widget _buildTodayScheduleStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TODAY\'S SCHEDULE', 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6B7280), letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _todaySchedule.length,
            itemBuilder: (context, index) {
              final slot = _todaySchedule[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.startTime,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2C))),
                    const SizedBox(height: 4),
                    Text(slot.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF000000))),
                    const Spacer(),
                    Text('Section ${slot.section}',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF6B7280))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _secondaryButton(
      {required String label,
      required IconData icon,
      required VoidCallback onTap,
      int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF2C2C2C)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937), // FIXED: Was White
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecentSessions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text(
            'No recent activity',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your attendance history will appear here.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security_rounded,
                        color: Color(0xFF2C2C2C), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Teacher Portal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFFFFF),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SystemStatusBadge(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeSession != null) _buildActiveSessionCard(),
                  if (_activeSession == null && _aiRecData != null) _buildAIRecommendationCard(),
                  const SizedBox(height: 20),

                  if (_confirmationSlot != null) ...[
                    _buildAIConfirmationBanner(),
                    const SizedBox(height: 24),
                  ],

                  if (_currentSlot != null && _activeSession == null && _confirmationSlot == null) ...[
                    _buildSmartSuggestionCard(),
                    const SizedBox(height: 24),
                  ],

                  _buildSystemIntelligencePanel(),
                  const SizedBox(height: 24),

                  if (_todaySchedule.isNotEmpty) ...[
                    _buildTodayScheduleStrip(),
                    const SizedBox(height: 24),
                  ] else if (_activeSession == null && _currentSlot == null) ...[
                    _buildEmptyState(),
                    const SizedBox(height: 24),
                  ],

                  // Welcome card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${_profile?.name.split(' ').first ?? 'Teacher'}! 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2937), // FIXED: Was White on White
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You have $_todaySessions sessions scheduled for today.',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),


                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.today_rounded,
                          label: "Sessions",
                          value: '$_todaySessions',
                          color: const Color(0xFF2C2C2C),
                          bgColor: const Color(0xFFF5F5F5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.people_rounded,
                          label: 'Students',
                          value: '60',
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFF0FDF4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.analytics_rounded,
                          label: 'Attendance',
                          value: '$_avgAttendance%',
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFFFBEB),
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // Start Attendance Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeacherSelectClassScreen(),
                          ),
                        );
                        _loadData();
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                      label: const Text('START ATTENDANCE SESSION', 
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056B3), // Premium Blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: const Color(0xFF0056B3).withOpacity(0.3),
                      ),
                    ),
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 12),

                  // Secondary Actions
                  Row(
                    children: [
                      Expanded(
                        child: _secondaryButton(
                          label: 'Analytics',
                          icon: Icons.insert_chart_outlined_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAnalyticsScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _secondaryButton(
                          label: 'Fraud Alerts',
                          icon: Icons.gpp_maybe_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FraudDetectionScreen())),
                          badge: FraudDetectionService.activeCount,
                        ),
                      ),
                    ],
                  ).animate(delay: 350.ms).fadeIn(),

                  const SizedBox(height: 28),

                  // Recent sessions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2937), // FIXED: Was White
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_recentSessions.isNotEmpty)
                        TextButton(
                          onPressed: () => widget.onTabChange(1),
                          child: const Text('View history',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2C2C2C),
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 8),

                  if (_recentSessions.isEmpty)
                    _buildEmptyRecentSessions()
                  else
                    ..._recentSessions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionSummaryScreen(session: s))),
                          child: _sessionCard(session: s),
                        ).animate(delay: (500 + i * 100).ms).fadeIn().slideY(begin: 0.1),
                      );
                    }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intelligenceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sessionCard({required AttendanceSession session}) {
    final present = session.presentCount + session.lateCount;
    final total = session.students.length;
    final percentage = total > 0 ? (present / total * 100).round() : 0;
    final timeStr = DateFormat('MMM d, hh:mm a').format(session.startTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    size: 20, color: Color(0xFFFFFFFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.subject,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF000000))),
                    Text(session.classLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percentage >= 75
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$percentage%',
                    style: TextStyle(
                        color: percentage >= 75
                            ? const Color(0xFF059669)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(timeStr,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              const Spacer(),
              Text('$present/$total present',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? present / total : 0,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                      percentage >= 75
                          ? const Color(0xFF059669)
                          : const Color(0xFFEF4444)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ——————————————————————————————————————————————————————————————————————————————————————————————————
// SESSIONS HISTORY TAB
// ——————————————————————————————————————————————————————————————————————————————————————————————————

class _TeacherHistoryTab extends StatefulWidget {
  const _TeacherHistoryTab();

  @override
  State<_TeacherHistoryTab> createState() => _TeacherHistoryTabState();
}

class _TeacherHistoryTabState extends State<_TeacherHistoryTab> {
  List<AttendanceSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await SessionService.getPastSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Session History',
            style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w800, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No past sessions yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280))),
                      const SizedBox(height: 8),
                      const Text('Complete an attendance session to see it here',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = _sessions[i];
                      final present = s.presentCount + s.lateCount;
                      final total = s.students.length;
                      final pct =
                          total > 0 ? (present / total * 100).round() : 0;
                      final timeStr =
                          DateFormat('MMM d, hh:mm a').format(s.startTime);

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SessionSummaryScreen(session: s),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.book_rounded,
                                    size: 20, color: Color(0xFF2C2C2C)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.subject,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: Color(0xFF000000))),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${s.classLabel} · ${DateFormat('MMM d').format(s.startTime)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF6B7280))),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Present: ${s.presentCount} · Late: ${s.lateCount} · Absent: ${s.absentCount}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: pct >= 75
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: pct >= 75 ? const Color(0xFFBBF7D0) : const Color(0xFFFECDD3)),
                                ),
                                child: Text('$pct%',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: pct >= 75
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFBE123C))),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: (i * 100).ms).fadeIn().slideX(begin: 0.1);
                    },
                  ),
                ),
    );
  }
}

// ——————————————————————————————————————————————————————————————————————————————————————————————————
// PROFILE TAB
// ——————————————————————————————————————————————————————————————————————————————————————————————————

class _TeacherProfileTab extends StatefulWidget {
  const _TeacherProfileTab();

  @override
  State<_TeacherProfileTab> createState() => _TeacherProfileTabState();
}

class _TeacherProfileTabState extends State<_TeacherProfileTab> {
  TeacherProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await TeacherService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Faculty Profile',
            style: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w900, fontSize: 20)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2C2C2C).withValues(alpha: 0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFFFFFFF),
                  child: Text(_profile?.name.substring(0, 1).toUpperCase() ?? 'T',
                      style: const TextStyle(color: Color(0xFF0056B3), fontSize: 32, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _profile?.name ?? 'Faculty member',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF000000),
                    letterSpacing: -1.0),
              ),
              const SizedBox(height: 32),
              _profileItem(Icons.badge_outlined, 'Employee ID', _profile?.teacherId ?? 'N/A'),
              _profileItem(
                  Icons.school_outlined, 'Department', _profile?.department ?? 'N/A'),
              _profileItem(
                  Icons.email_outlined, 'Email', _profile?.email ?? 'N/A'),
              
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('MANAGEMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              
              _profileAction(Icons.edit_note_rounded, 'Edit Profile Assignments', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherProfileSetupScreen(isEdit: true)));
              }),
              _profileAction(Icons.calendar_month_rounded, 'Manage Timetable', () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableManagerScreen()));
              }),
              _profileAction(Icons.history_edu_rounded, 'Smart Attendance Editor', () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartAttendanceEditScreen()));
              }),
              _profileAction(Icons.lock_reset_rounded, 'Change Account Password', () => _showChangePasswordDialog()),
              
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('DEVELOPER / DEBUG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEF4444), letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              _profileAction(Icons.bug_report_rounded, 'Test AI Notification (Instant)', () {
                NotificationService().showNotification(
                  title: "🚨 AI DEBUG: Threat Detected",
                  body: "This is a real-time high-priority test notification from the AI Action Engine.",
                  priority: 'CRITICAL',
                  bypassSpamFilter: true,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test AI Notification Sent! Check your status bar.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }),
  
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Sign Out',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter new password for your account:', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFFFFF), foregroundColor: Colors.white),
            child: const Text('Update Password'),
          ),
        ],
      )
    );

    if (result == true && controller.text.isNotEmpty) {
      final user = await AuthService.getCurrentUser();
    if (user != null) {
      final id = user['uid'] ?? user['rollNumber'] ?? ''; // Centralized uses 'uid'
      await AuthService.changePassword(id, controller.text);
    }
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Updated Successfully'), backgroundColor: Colors.green));
        }
      }
    }

  Widget _profileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0056B3)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000))),
        ],
      ),
    );
  }

  Widget _profileAction(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0056B3)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF000000))),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

