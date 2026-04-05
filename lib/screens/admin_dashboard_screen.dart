import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/sa_admin_service.dart';
import '../services/sa_report_service.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'admin_audit_logs_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_settings_screen.dart';
import 'chat_screen.dart';
import 'class_structure_screen.dart';
import 'fraud_monitoring_screen.dart';
import 'landing_screen.dart';
import 'student_management_screen.dart';
import 'teacher_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await AuthService.getCachedUserData();
      final results = await Future.wait([
        AdminService.recalculateAndCacheStats(),
        SaAdminService.getGlobalStats(),
        SaAdminService.getLatestFraudAlerts(),
      ]).timeout(const Duration(seconds: 6));

      if (!mounted) return;
      setState(() {
        _adminName = (userData['fullName'] ?? 'Admin').toString().split(' ').first;
        _stats = results[1] as Map<String, dynamic>;
        _alerts = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stats = {};
        _alerts = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
        backgroundColor: const Color(0xFF0056B3),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        label: const Text('Ask Secure AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0056B3)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF0056B3),
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Stats Row ──
                        _buildStatsRow(),
                        const SizedBox(height: 28),

                        // ── Management ──
                        _sectionLabel('Manage'),
                        const SizedBox(height: 12),
                        _buildManagementGrid(),
                        const SizedBox(height: 28),

                        // ── Security Alerts ──
                        _sectionLabel('Security Alerts'),
                        const SizedBox(height: 12),
                        _buildAlertsList(),
                        const SizedBox(height: 28),

                        // ── Tools ──
                        _sectionLabel('Tools'),
                        const SizedBox(height: 12),
                        _buildToolsRow(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  SliverAppBar _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF2C2C2C),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $_adminName',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Admin Console',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Row(
                children: [
                  _headerBadge(
                    Icons.check_circle_rounded,
                    'Online',
                    const Color(0xFF059669),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      await AuthService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LandingScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ─── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('Students', '${_stats['totalStudents'] ?? 0}',
            Icons.people_alt_rounded, const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        _statCard('Faculty', '${_stats['totalTeachers'] ?? 0}',
            Icons.badge_rounded, const Color(0xFF8B5CF6)),
        const SizedBox(width: 10),
        _statCard('Alerts', '${_alerts.length}',
            Icons.warning_amber_rounded, const Color(0xFFEF4444)),
      ],
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFFFFF)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ─── Section Label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF000000), // Solid Black Section Header
            letterSpacing: 0.5));
  }

  // ─── Management Grid (2 columns) ───────────────────────────────────────────
  Widget _buildManagementGrid() {
    final items = [
      _MgmtItem('Teachers', Icons.person_search_rounded, const Color(0xFF3B82F6),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherManagementScreen()))),
      _MgmtItem('Students', Icons.school_rounded, const Color(0xFF8B5CF6),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen()))),
      _MgmtItem('Classes', Icons.account_tree_rounded, const Color(0xFF0EA5E9),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassStructureScreen()))),
      _MgmtItem('Reports', Icons.assessment_rounded, const Color(0xFFF59E0B),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()))),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFFFFF)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(item.label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 80 * i)).fadeIn().slideY(begin: 0.08);
      },
    );
  }

  // ─── Security Alerts ────────────────────────────────────────────────────────
  Widget _buildAlertsList() {
    if (_alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 22),
            SizedBox(width: 12),
            Text('All clear — No security alerts',
                style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFFFFF)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ..._alerts.asMap().entries.map((e) {
            final a = e.value;
            final severity = a['severity'] ?? a['level'] ?? 'Low';
            final color = severity == 'High'
                ? const Color(0xFFEF4444)
                : severity == 'Medium'
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF6B7280);

            return Column(
              children: [
                if (e.key > 0)
                  const Divider(height: 1, color: Color(0xFFFFFFFF)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a['title'] ?? a['type'] ?? 'Alert',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(severity,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          // View all button
          InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FraudMonitoringScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: const Center(
                child: Text('View All Alerts →',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6))),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  // ─── Tools Row ──────────────────────────────────────────────────────────────
  Widget _buildToolsRow() {
    return Row(
      children: [
        _toolChip('Audit Logs', Icons.history_edu_rounded, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminAuditLogsScreen()));
        }),
        const SizedBox(width: 10),
        _toolChip('Export', Icons.ios_share_rounded, _handleExport),
        const SizedBox(width: 10),
        _toolChip('Settings', Icons.tune_rounded, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminSettingsScreen()));
        }),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _toolChip(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF6B7280)),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Export handler ─────────────────────────────────────────────────────────
  Future<void> _handleExport() async {
    try {
      final data = await SaReportService.generateExportData(type: ExportType.faculty)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
              SizedBox(width: 10),
              Text('Export Ready',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          content: Text(
            'Faculty report generated with ${data['metadata']?['entityType'] ?? 'all'} records.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed. Try again later.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _MgmtItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _MgmtItem(this.label, this.icon, this.color, this.onTap);
}
