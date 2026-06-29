import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../services/attendance_data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/student_service.dart';
import '../services/ai_action_engine.dart';
import '../widgets/system_status_badge.dart';
import '../services/app_state_service.dart';
import '../services/automated_notification_service.dart';
import '../services/demo_state_service.dart';
import '../services/network_service.dart';

class StudentPortalScreen extends StatefulWidget {
  const StudentPortalScreen({super.key});

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  final List<SubjectAttendance> _subjects = AttendanceDataService.getMockAttendance();
  String _filter = 'all';
  final Set<int> _expandedIndexes = {};
  Map<String, dynamic>? _backendAIResult;
  bool _isAILoading = true;
  String _userName = 'Student';
  String _initials = 'S';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchBackendAI();
    AutomatedNotificationService.checkAndNotifyRisk();
    DemoStateService().addListener(_onDemoUpdate);
  }

  @override
  void dispose() {
    DemoStateService().removeListener(_onDemoUpdate);
    super.dispose();
  }

  void _onDemoUpdate() {
    if (mounted) {
      _loadData();
    }
  }

  void _loadData() {
     setState(() {
       // Refresh UI and data
     });
  }

  void _loadUser() {
    final user = AppStateService().currentUser;
    if (user != null) {
      final String full = user['fullName'] ?? 'Student';
      setState(() {
        _userName = full;
        _initials = full.isNotEmpty ? full[0].toUpperCase() : 'S';
      });
    }
  }

  Future<void> _fetchBackendAI() async {
    final user = AppStateService().currentUser;
    if (user != null) {
      try {
        final res = await StudentService.getPredictiveAnalysis(user['uid'])
            .timeout(const Duration(seconds: 5));
        if (mounted) {
          setState(() {
            _backendAIResult = res;
            _isAILoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _backendAIResult = {'risk': 'Safe', 'insight': 'Operating in offline mode.'};
            _isAILoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isAILoading = false;
      });
    }
  }

  // ── Totals ──────────────────────────────────────────────────────────────────
  int get _totalPresent => _subjects.fold<int>(0, (s, e) => s + e.attendedClasses);
  int get _totalAbsent => _subjects.fold<int>(0, (s, e) => s + e.absentClasses);
  int get _totalClasses => _subjects.fold<int>(0, (s, e) => s + e.totalClasses);
  double get _overallPct =>
      _totalClasses == 0 ? 0 : (_totalPresent / _totalClasses) * 100;

  List<SubjectAttendance> get _filtered {
    if (_filter == 'danger') {
      return _subjects.where((s) => s.percentage < 75).toList();
    }
    if (_filter == 'safe') {
      return _subjects.where((s) => s.percentage >= 75).toList();
    }
    return _subjects;
  }

  List<SubjectAttendance> get _dangerSubjects =>
      _subjects.where((s) => s.percentage < 75).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'student_scan_attendance_fab',
        onPressed: _showDemoScanner,
        backgroundColor: const Color(0xFF1F2937),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text('SCAN ATTENDANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ).animate().scale(delay: 500.ms, duration: 600.ms, curve: Curves.elasticOut).shimmer(delay: 2000.ms, duration: 1500.ms),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildAIEngineCard(),
                const SizedBox(height: 20),
                _buildOverallProgressRow(),
                if (_dangerSubjects.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildWarningBanner(),
                ],
                const SizedBox(height: 24),
                const Text('Subject Attendance',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                _buildFilterRow(),
                const SizedBox(height: 16),
                ..._filtered.asMap().entries.map((e) {
                  return _buildSubjectCard(e.value, e.key);
                }),
                if (_subjects.isEmpty) _buildEmptyState(),
                const SizedBox(height: 80), // More space for FAB
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0056B3).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFF0056B3)),
            ),
            const SizedBox(height: 16),
            const Text('No attendance records yet.',
                style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0056B3).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_initials,
                      style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STUDENT PORTAL 🛡️',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(_userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIEngineCard() {
    if (_isAILoading) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0056B3)),
      );
    }

    final risk = _backendAIResult?['risk'] ?? 'Safe';
    final isCritical = risk == 'Critical';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isCritical ? const Color(0xFFFECDD3) : const Color(0xFFBBF7D0),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isCritical ? Colors.red : Colors.green).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCritical ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.psychology_rounded,
                color: isCritical ? const Color(0xFFDC2626) : const Color(0xFF059669),
                size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SECURE PREDICTION 🤖',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isCritical
                            ? const Color(0xFF9F1239)
                            : const Color(0xFF15803D))),
                const SizedBox(height: 6),
                Text(
                  isCritical 
                    ? 'ACTION REQUIRED: Your eligibility is at risk. Attend the next 3 sessions!'
                    : 'Looking Good! You are meeting all institutional requirements. Keep it up!',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: isCritical
                          ? const Color(0xFF881337)
                          : const Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildOverallProgressRow() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Progress',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937))),
              Text('${_overallPct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0056B3))),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: _overallPct / 100,
              minHeight: 14,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0056B3)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _statItem('Attended', '$_totalPresent', const Color(0xFF059669)),
              const SizedBox(width: 12),
              _statItem('Missed', '$_totalAbsent', const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ── Warning banner ───────────────────────────────────────────────────────────
  Widget _buildWarningBanner() {
    final count = _dangerSubjects.length;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = 'danger');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count subject${count > 1 ? 's' : ''} below 75%. Tap to view.',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9F1239)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter row ───────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All', 'all'),
          const SizedBox(width: 8),
          _filterChip('Below 75%', 'danger'),
          const SizedBox(width: 8),
          _filterChip('Above 75%', 'safe'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0056B3) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? const Color(0xFF003366) : const Color(0xFFE2E8F0)),
          boxShadow: active ? [
            BoxShadow(color: const Color(0xFF0056B3).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF4B5563))),
      ),
    );
  }

  // ── Subject card ─────────────────────────────────────────────────────────────
  Widget _buildSubjectCard(SubjectAttendance subject, int index) {
    final expanded = _expandedIndexes.contains(index);
    final bool isDanger = subject.percentage < 75;

    final Color primaryColor = isDanger ? const Color(0xFFDC2626) : const Color(0xFF0056B3);
    final Color bgColor = isDanger ? const Color(0xFFFFE4E6) : const Color(0xFFEFF6FF);

    final initials = subject.name
        .split(' ')
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() {
              expanded
                  ? _expandedIndexes.remove(index)
                  : _expandedIndexes.add(index);
            }),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16)),
                        child: Center(
                          child: Text(initials,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subject.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1F2937))),
                            const SizedBox(height: 4),
                            Text(subject.code,
                                style: const TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      Text('${subject.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: primaryColor)),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: subject.percentage / 100,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetails(subject, primaryColor, bgColor, isDanger),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, curve: Curves.easeOut).fadeIn();
  }

  Widget _buildDetails(SubjectAttendance subject, Color primaryColor, Color bgColor, bool isDanger) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _detailStat('Present', '${subject.attendedClasses}', const Color(0xFF059669)),
              _detailStat('Absent', '${subject.absentClasses}', const Color(0xFFDC2626)),
              _detailStat('Total', '${subject.totalClasses}', const Color(0xFF1F2937)),
            ],
          ),
          if (isDanger) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attend the next ${subject.classesNeededFor(75)} classes to reach 75%.',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailStat(String label, String value, [Color color = const Color(0xFF1E293B)]) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280))),
      ],
    );
  }

  void _showDemoScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('QR SCANNER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6B7280), letterSpacing: 1.5)),
            const SizedBox(height: 12),
            const Text('Scan Class Attendance QR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 40),
            
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0056B3), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 100, color: Color(0xFFE5E7EB)),
                  Container(
                    width: 220,
                    height: 2,
                    color: const Color(0xFF0056B3),
                  ).animate(onPlay: (c) => c.repeat()).moveY(begin: -100, end: 100, duration: 2000.ms),
                ],
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Point your camera at the QR code generated on the teacher\'s screen to mark your attendance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _markDemoAttendance(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('SIMULATE SUCCESSFUL SCAN', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDemoAttendance(BuildContext context) async {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF0056B3))),
    );

    final roll = AppStateService().currentUser?['rollNumber'];
    if (roll != null) {
       try {
         await http.post(
          Uri.parse('${NetworkService.baseUrl}/mark-attendance'),
          body: jsonEncode({
            'rollNumber': roll,
            'subject': 'Artificial Intelligence',
            'token': 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'Content-Type': 'application/json'},
        );
       } catch (_) {}
       DemoStateService().markAttended(roll, 'Artificial Intelligence');
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Attendance Marked Successfully! ✓'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    _loadData();
  }
}