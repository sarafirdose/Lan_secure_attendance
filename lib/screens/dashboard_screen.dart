import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/attendance_model.dart';
import 'security_verification_screen.dart';
import 'attendance_history_screen.dart';
import 'student_portal_screen.dart';
import 'dashboard_screen_profile_tab.dart';
import '../services/auth_service.dart';
import '../services/attendance_data_service.dart';
import 'demo_qr_scanner_screen.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
        backgroundColor: const Color(0xFF0056B3),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        label: const Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _HistoryTab(),
          _PortalTab(),
          _ProfileTab(),
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _navItem(
                  1, Icons.history_rounded, Icons.history_outlined, 'History'),
              _navItem(2, Icons.grid_view_rounded, Icons.grid_view_outlined,
                  'Portal'),
              _navItem(3, Icons.person_rounded, Icons.person_outline_rounded,
                  'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = const Color(0xFF0056B3);
    final inactiveColor = const Color(0xFF94A3B8);
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? active : inactive,
              color: isSelected ? activeColor : inactiveColor,
              size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _userName = 'Student';
  String _rollNumber = '';
  String _department = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await AuthService.getCachedUserData();
    if (mounted) {
      setState(() {
        final name = data['fullName'] ?? 'Student';
        _userName = name.split(' ').first;
        _rollNumber = data['rollNumber'] ?? '';
        _department = data['department'] ?? '';
      });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Stats Calculation ───────────────────────────────────────────────────────
  List<SubjectAttendance> get _subjects => AttendanceDataService.getMockAttendance();
  int get _totalPresent => _subjects.fold<int>(0, (int s, e) => s + e.attendedClasses);
  int get _totalAbsent => _subjects.fold<int>(0, (int s, e) => s + e.absentClasses);
  int get _totalClasses => _subjects.fold<int>(0, (int s, e) => s + e.totalClasses);
  double get _overallPct => _totalClasses == 0 ? 0 : (_totalPresent / _totalClasses) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 16),
                  _buildSecurityIndicators(),
                  const SizedBox(height: 24),
                  _buildScanButton(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Today\'s Schedule'),
                  const SizedBox(height: 12),
                  _buildTodaySchedule(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quick Stats'),
                  const SizedBox(height: 12),
                  _buildQuickStats(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('SecureAttend',
              style: TextStyle(
                  color: Color(0xFF0056B3),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Color(0xFF1E293B), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting,
            style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(_userName,
                style: const TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Text('Ready',
                      style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ).animate().slideX(begin: 0.2).fadeIn(),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityIndicators() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _securityPill(Icons.wifi_rounded, 'LAN Verified'),
          const SizedBox(width: 10),
          _securityPill(Icons.shield_outlined, 'Anti-Proxy'),
          const SizedBox(width: 10),
          _securityPill(Icons.lock_outline_rounded, 'Secured'),
        ],
      ),
    );
  }

  Widget _securityPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const SecurityVerificationScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  size: 44, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            const Text('Scan Attendance',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            const Text('Tap to open secure verified scanner',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF000000)));
  }

  Widget _buildTodaySchedule() {
    final rawClasses = AttendanceDataService.getTodayClasses();
    if (rawClasses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text('No classes today — rest up!',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ),
      );
    }

    final classes = rawClasses
        .map((c) => _ClassItem(c['name'] as String, c['code'] as String,
            c['slot'] as String, 'Room No. 4'))
        .toList();

    return Column(
      children: classes.asMap().entries.map((e) {
        final now = TimeOfDay.now();
        final classHour = int.parse(e.value.time.split(':')[0]);
        final isPM = e.value.time.contains('PM');
        final hour24 = isPM && classHour != 12 ? classHour + 12 : classHour;
        final isUpcoming = hour24 > now.hour;
        final isCurrent = hour24 == now.hour;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFFFFFFFF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent ? const Color(0xFF0056B3) : const Color(0xFFEEEEEE),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: [
              if (isCurrent)
                BoxShadow(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              else
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.value.time,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? const Color(0xFF0056B3)
                                : const Color(0xFF757575))),
                    const SizedBox(height: 6),
                    Text(e.value.subject,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF000000))),
                    const SizedBox(height: 4),
                    Text('${e.value.code} • ${e.value.room}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF616161),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.white.withValues(alpha: 0.2)
                      : isUpcoming
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCurrent ? 'Now' : isUpcoming ? 'Next' : 'Done',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? Colors.white
                          : isUpcoming
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statSquare('Attendance', '${_overallPct.toStringAsFixed(0)}%', const Color(0xFFFFFFFF), const Color(0xFFEFF6FF)),
        const SizedBox(width: 12),
        _statSquare('Absent', '$_totalAbsent', const Color(0xFFDC2626), const Color(0xFFFFE4E6)),
        const SizedBox(width: 12),
        _statSquare('Subjects', '${_subjects.length}', const Color(0xFF9333EA), const Color(0xFFF3E8FF)),
      ],
    );
  }

  Widget _statSquare(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _QuickItem(this.icon, this.label, this.color, this.bg);
}

class _ClassItem {
  final String subject, code, time, room;
  const _ClassItem(this.subject, this.code, this.time, this.room);
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return const AttendanceHistoryScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PORTAL TAB
// ─────────────────────────────────────────────────────────────────────────────
class _PortalTab extends StatelessWidget {
  const _PortalTab();
  @override
  Widget build(BuildContext context) {
    return const StudentPortalScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return const ProfileTab();
  }
}
