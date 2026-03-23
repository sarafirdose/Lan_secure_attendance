import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'security_verification_screen.dart';
import 'attendance_history_screen.dart';
import 'student_portal_screen.dart';
import 'dashboard_screen_profile_tab.dart';
import '../services/auth_service.dart';
import '../services/attendance_data_service.dart';

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
      backgroundColor: const Color(0xFFF8FAFF),
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
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2347D4).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? active : inactive,
              color: isSelected
                  ? const Color(0xFF2347D4)
                  : const Color(0xFF9CA3AF),
              size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF2347D4)
                      : const Color(0xFF9CA3AF))),
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
    if (mounted)
      setState(() {
        final name = data['fullName'] ?? 'Student';
        _userName = name.split(' ').first;
        _rollNumber = data['rollNumber'] ?? '';
        _department = data['department'] ?? '';
      });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),
                  _buildNetworkCard(),
                  const SizedBox(height: 16),
                  _buildScanButton(),
                  const SizedBox(height: 20),
                  _buildQuickStats(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Quick Access'),
                  const SizedBox(height: 12),
                  _buildQuickAccessGrid(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Today\'s Schedule'),
                  const SizedBox(height: 12),
                  _buildTodaySchedule(),
                  const SizedBox(height: 20),
                  _buildAttendanceRulesBanner(),
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
      backgroundColor: const Color(0xFF2347D4),
      automaticallyImplyLeading: false,
      title: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(
            _userName.isNotEmpty ? _userName[0] : 'S',
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Student Dashboard',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (_rollNumber.isNotEmpty)
              Text(_rollNumber,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11)),
          ],
        )),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 20),
        ),
      ]),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1530A6), Color(0xFF2347D4), Color(0xFF3558E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2347D4).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_greeting,',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
            const SizedBox(height: 2),
            Text(_userName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            if (_department.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_department,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12)),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('Ready to mark attendance',
                    style: TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
        )),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              const Icon(Icons.security_rounded, color: Colors.white, size: 30),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildNetworkCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        _networkRow(
          icon: Icons.wifi_rounded,
          iconColor: const Color(0xFF2347D4),
          title: 'Campus_WiFi',
          subtitle: 'Signal: Strong',
          subtitleColor: const Color(0xFF16A34A),
          badge: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 12, color: Colors.white)),
          isFirst: true,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _networkRow(
          icon: Icons.router_rounded,
          iconColor: const Color(0xFF2347D4),
          title: 'Subnet: 192.168.1.0/24',
          subtitle: 'Valid campus range',
          badge: const Icon(Icons.check_circle_rounded,
              size: 20, color: Color(0xFF2347D4)),
          isFirst: false,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _networkRow(
          icon: Icons.phone_android_rounded,
          iconColor: const Color(0xFF2347D4),
          title: 'Device registered',
          subtitle: 'Fingerprint verified',
          badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Locked',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2347D4)))),
          isFirst: false,
        ),
      ]),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _networkRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    required Widget badge,
    required bool isFirst,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1729))),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor ?? const Color(0xFF6B7280))),
          ],
        )),
        badge,
      ]),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2347D4), Color(0xFF3A5DE8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2347D4).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                size: 28, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Scan Attendance QR',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('Tap to verify & scan',
                    style: TextStyle(fontSize: 11, color: Color(0xFFBFDBFE))),
              ]),
        ]),
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildQuickStats() {
    return Row(children: [
      _statCard('80%', 'Attendance', const Color(0xFF2347D4),
          const Color(0xFFEFF6FF), Icons.bar_chart_rounded),
      const SizedBox(width: 10),
      _statCard('3', 'Absent', const Color(0xFFDC2626), const Color(0xFFFEF2F2),
          Icons.cancel_outlined),
      const SizedBox(width: 10),
      _statCard('6', 'Subjects', const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF), Icons.menu_book_rounded),
    ]);
  }

  Widget _statCard(
      String value, String label, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF6B7280), height: 1.2)),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: const Color(0xFF2347D4),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F1729))),
    ]);
  }

  Widget _buildQuickAccessGrid() {
    final items = [
      _QuickItem(Icons.history_rounded, 'Scan\nHistory',
          const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
      _QuickItem(Icons.grid_view_rounded, 'Portal\nView',
          const Color(0xFF0891B2), const Color(0xFFECFEFF)),
      _QuickItem(Icons.bar_chart_rounded, 'Subject\nStats',
          const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      _QuickItem(Icons.person_rounded, 'My\nProfile', const Color(0xFFD97706),
          const Color(0xFFFFFBEB)),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: items
          .map((item) => GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: item.bg,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: item.color.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 24, color: item.color),
                      const SizedBox(height: 6),
                      Text(item.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: item.color,
                              height: 1.2)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTodaySchedule() {
    final rawClasses = AttendanceDataService.getTodayClasses();
    if (rawClasses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(children: [
          Icon(Icons.weekend_rounded, color: Color(0xFF9CA3AF), size: 20),
          SizedBox(width: 10),
          Text('No classes today — enjoy your weekend!',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ]),
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
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isCurrent ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF2347D4)
                    : const Color(0xFF2347D4).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(
                e.value.subject.split(' ').map((w) => w[0]).take(2).join(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? Colors.white : const Color(0xFF2347D4)),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.value.subject,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1729))),
                Text('${e.value.code} • ${e.value.room}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(e.value.time,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2347D4))),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF2347D4)
                      : isUpcoming
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCurrent
                      ? 'Now'
                      : isUpcoming
                          ? 'Upcoming'
                          : 'Done',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? Colors.white
                          : isUpcoming
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF9CA3AF)),
                ),
              ),
            ]),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceRulesBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded,
            size: 18, color: Color(0xFFD97706)),
        const SizedBox(width: 10),
        const Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Reminder',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E))),
            SizedBox(height: 3),
            Text(
                'Maintain 75% attendance per subject to be eligible for end-semester exams.',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFF92400E), height: 1.4)),
          ],
        )),
      ]),
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
