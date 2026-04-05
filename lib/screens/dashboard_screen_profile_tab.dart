import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/app_state_service.dart';
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
    // Also check AppStateService for any extra fields
    final appUser = AppStateService().currentUser;
    if (mounted) {
      setState(() {
        _userData = {
          ...data,
          if (appUser != null) ...{
            'fullName': appUser['name'] ?? appUser['fullName'] ?? data['fullName'] ?? '',
            'rollNumber': appUser['uid'] ?? data['rollNumber'] ?? '',
            'department': appUser['department'] ?? data['department'] ?? '',
            'yearSection': appUser['year_section'] ?? data['yearSection'] ?? '',
            'email': appUser['email'] ?? data['email'] ?? '',
            'phone': appUser['phone'] ?? data['phone'] ?? '',
          },
        };
        _loading = false;
      });
    }
  }

  String get _initials {
    final name = _userData['fullName'] ?? '';
    if (name.isEmpty) return 'ST';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get _rollNumber => _userData['rollNumber'] ?? '';
  String get _fullName => _userData['fullName'] ?? 'Student';
  String get _department => _userData['department'] ?? '';
  String get _yearSection => _userData['yearSection'] ?? '';
  String get _email => _userData['email'] ?? '';
  String get _phone => _userData['phone'] ?? '';

  double get _completionPercentage {
    int total = 5;
    int filled = 0;
    if (_rollNumber.isNotEmpty) filled++;
    if (_department.isNotEmpty) filled++;
    if (_yearSection.isNotEmpty) filled++;
    if (_email.isNotEmpty) filled++;
    if (_phone.isNotEmpty) filled++;
    return filled / total;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFFFFF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                children: [
                  if (_completionPercentage < 1.0) ...[
                    _buildCompleteProfileCTA(),
                    const SizedBox(height: 16),
                  ],
                  _buildAcademicCard(),
                  const SizedBox(height: 24),
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
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0056B3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              const Text('My Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              // Avatar with Progress Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CircularProgressIndicator(
                      value: _completionPercentage,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(_initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF059669),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(_fullName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Profile ${(_completionPercentage * 100).toInt()}% Complete',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteProfileCTA() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Complete Your Profile',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E))),
                const SizedBox(height: 4),
                Text('Add missing details to secure your account better.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _showEditProfileSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _fullName == 'Student' ? '' : _fullName);
    final phoneCtrl = TextEditingController(text: _phone);
    final emailCtrl = TextEditingController(text: _email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Edit Profile',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _editField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _editField(phoneCtrl, 'Mobile Number', Icons.phone_outlined,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _editField(emailCtrl, 'Email Address', Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    // Show loading
                    Navigator.pop(context);
                    setState(() => _loading = true);

                    final success = await AuthService.updateProfile(
                      fullName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                      phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                      email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                    );

                    // Reload the updated data
                    await _loadUser();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            Icon(
                              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                              color: Colors.white, size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(success ? 'Profile saved!' : 'Saved locally (offline)',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                          backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056B3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2),
        ),
      ),
    );
  }

  // ── Academic info card ───────────────────────────────────────────────────────
  Widget _buildAcademicCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: const Text('Personal Information',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF000000))),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (_rollNumber.isNotEmpty) ...[
                  _infoRow(Icons.badge_outlined, 'Roll Number', _rollNumber),
                  if (_department.isNotEmpty || _yearSection.isNotEmpty || _email.isNotEmpty || _phone.isNotEmpty) _divider(),
                ],
                if (_department.isNotEmpty) ...[
                  _infoRow(Icons.school_outlined, 'Department', _department),
                  if (_yearSection.isNotEmpty || _email.isNotEmpty || _phone.isNotEmpty) _divider(),
                ],
                if (_yearSection.isNotEmpty) ...[
                  _infoRow(Icons.class_outlined, 'Year & Section', _yearSection),
                  if (_email.isNotEmpty || _phone.isNotEmpty) _divider(),
                ],
                if (_email.isNotEmpty) ...[
                  _infoRow(Icons.email_outlined, 'Email', _email),
                  if (_phone.isNotEmpty) _divider(),
                ],
                if (_phone.isNotEmpty)
                  _infoRow(Icons.phone_outlined, 'Mobile', _phone),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1);
  }

  // ── Sign out section ─────────────────────────────────────────────────────────
  Widget _buildSignOutSection() {
    return Column(children: [
      if (!_showSignOutConfirm) ...[
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showSignOutConfirm = true),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Sign Out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFFFEF2F2),
            ),
          ),
        ),
      ] else ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFECACA)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Sign out of SecureAttend?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF000000))),
            const SizedBox(height: 8),
            const Text(
              'Your device is registered. If you sign out, you must sign back in with this exact device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showSignOutConfirm = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
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
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
      ],
      const SizedBox(height: 16),
      Text('SecureAttend v1.0.0',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9CA3AF))),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF0056B3)),
        const SizedBox(width: 16),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000))),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFEEEEEE));
}
