import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, String> _userData = {};
  bool _loading = true;
  bool _showSignOutConfirm = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await AuthService.getCachedUserData();
    if (mounted)
      setState(() {
        _userData = data;
        _loading = false;
      });
  }

  String get _initials {
    final name = _userData['fullName'] ?? '';
    if (name.isEmpty) return 'ST';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get _rollNumber => _userData['rollNumber'] ?? 'Not set';
  String get _fullName => _userData['fullName'] ?? 'Student';
  String get _department => _userData['department'] ?? 'Not set';
  String get _yearSection => _userData['yearSection'] ?? 'Not set';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFF),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF2347D4))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAcademicCard(),
                  const SizedBox(height: 14),
                  const SizedBox(height: 28),
                  _buildSignOutSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2347D4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            children: [
              const Text('My Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 28),
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2.5),
                    ),
                    child: Center(
                      child: Text(_initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  // Verified badge
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Color(0xFF22C55E), shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_fullName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_rollNumber,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.school_outlined,
                    size: 13, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(_department,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('·',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4))),
                ),
                Icon(Icons.class_outlined,
                    size: 13, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(_yearSection,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12)),
              ]),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ── Academic info card ───────────────────────────────────────────────────────
  Widget _buildAcademicCard() {
    return _card(
      title: 'Academic Information',
      icon: Icons.school_rounded,
      iconColor: const Color(0xFF2347D4),
      children: [
        _infoRow(Icons.badge_outlined, 'Roll Number', _rollNumber),
        _divider(),
        _infoRow(Icons.school_outlined, 'Department', _department),
        _divider(),
        _infoRow(Icons.class_outlined, 'Year & Section', _yearSection),
        _divider(),
        _infoRow(
            Icons.email_outlined, 'Email', _userData['email'] ?? 'Not set'),
        _divider(),
        _infoRow(
            Icons.phone_outlined, 'Mobile', _userData['phone'] ?? 'Not set'),
      ],
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1);
  }

  // ── Sign out section ─────────────────────────────────────────────────────────
  Widget _buildSignOutSection() {
    return Column(children: [
      if (!_showSignOutConfirm) ...[
        // Info about sign out restriction
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device-locked account',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B))),
                  SizedBox(height: 3),
                  Text(
                    'Signing out will keep your device registered. You can sign back in only on this device. Frequent sign-outs are logged.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFB91C1C), height: 1.5),
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showSignOutConfirm = true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ] else ...[
        // Confirmation card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEF4444)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFDC2626), size: 26),
            ),
            const SizedBox(height: 14),
            const Text('Sign out?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1729))),
            const SizedBox(height: 6),
            const Text(
              'You can only sign back in on this device.\nYour attendance data will be preserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showSignOutConfirm = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LandingScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Yes, Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.95, 0.95)),
      ],
      const SizedBox(height: 8),
      Text('SecureAttend v1.0.0 — For authorized students only',
          style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF9CA3AF).withValues(alpha: 0.8))),
    ]);
  }

  // ── Reusable widgets ─────────────────────────────────────────────────────────
  Widget _card(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1729))),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: children),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 17, color: const Color(0xFF2347D4)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Flexible(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value == 'Not set'
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF0F1729))),
        ),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF3F4F6));
}
