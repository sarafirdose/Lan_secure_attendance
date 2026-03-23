import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class AttendanceSuccessScreen extends StatefulWidget {
  final String subject;
  final String subjectCode;
  final String rollNumber;

  const AttendanceSuccessScreen({
    super.key,
    required this.subject,
    required this.subjectCode,
    required this.rollNumber,
  });

  @override
  State<AttendanceSuccessScreen> createState() =>
      _AttendanceSuccessScreenState();
}

class _AttendanceSuccessScreenState extends State<AttendanceSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _pulseCtrl;
  String _fullName = '';
  String _rollNumber = '';

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _checkCtrl.forward();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await AuthService.getCachedUserData();
    if (mounted)
      setState(() {
        _fullName = data['fullName'] ?? 'Student';
        _rollNumber = data['rollNumber'] ?? widget.rollNumber;
      });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _formatTime() {
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12
        ? h - 12
        : h == 0
            ? 12
            : h;
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          // Background accent
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D8A3C),
                    Color(0xFF16A34A),
                    Color(0xFF22C55E)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // Confetti dots
          ...List.generate(12, (i) {
            final colors = [
              Colors.yellow,
              Colors.white,
              const Color(0xFF86EFAC),
              Colors.orange,
              Colors.pink,
              Colors.cyan
            ];
            return Positioned(
              top: 20.0 + (i * 17) % 180,
              left: i.isEven
                  ? 20.0 + (i * 31) % (MediaQuery.of(context).size.width * 0.4)
                  : MediaQuery.of(context).size.width * 0.5 + (i * 23) % 140,
              child: Container(
                width: 6 + (i % 3) * 3.0,
                height: 6 + (i % 3) * 3.0,
                decoration: BoxDecoration(
                  color: colors[i % colors.length].withValues(alpha: 0.6),
                  shape: i % 2 == 0 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: i % 2 != 0 ? BorderRadius.circular(2) : null,
                ),
              )
                  .animate(delay: Duration(milliseconds: 100 * i))
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.5, curve: Curves.easeOut),
            );
          }),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSuccessIcon(),
                  const SizedBox(height: 20),
                  _buildSuccessTitle(),
                  const SizedBox(height: 32),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  _buildVerificationCard(),
                  const SizedBox(height: 16),
                  _buildAttendanceTipCard(),
                  const SizedBox(height: 32),
                  _buildButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Stack(alignment: Alignment.center, children: [
      // Outer pulse ring
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 110 + _pulseCtrl.value * 20,
          height: 110 + _pulseCtrl.value * 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1 * (1 - _pulseCtrl.value)),
          ),
        ),
      ),
      // Main circle
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
      ),
      // Check icon
      AnimatedBuilder(
        animation: _checkCtrl,
        builder: (_, child) => Transform.scale(
          scale: _checkCtrl.value,
          child: child,
        ),
        child: const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 60),
      ),
    ]).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.3, 0.3),
        duration: 600.ms,
        curve: Curves.easeOutBack);
  }

  Widget _buildSuccessTitle() {
    return Column(children: [
      const Text('Attendance Marked!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5))
          .animate(delay: 300.ms)
          .fadeIn()
          .slideY(begin: 0.2),
      const SizedBox(height: 6),
      Text('Your presence has been recorded securely',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 13))
          .animate(delay: 400.ms)
          .fadeIn(),
    ]);
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF16A34A), size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Attendance Receipt',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('PRESENT',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ),
          ]),
        ),
        // Details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _detailRow(Icons.menu_book_rounded, 'Subject', widget.subject),
            _divider(),
            _detailRow(Icons.tag_rounded, 'Subject Code', widget.subjectCode),
            _divider(),
            _detailRow(Icons.person_rounded, 'Student',
                _fullName.isEmpty ? 'Student' : _fullName),
            _divider(),
            _detailRow(Icons.badge_outlined, 'Roll Number',
                _rollNumber.isEmpty ? widget.rollNumber : _rollNumber),
            _divider(),
            _detailRow(Icons.calendar_today_outlined, 'Date', _formatDate()),
            _divider(),
            _detailRow(Icons.access_time_rounded, 'Time', _formatTime()),
          ]),
        ),
      ]),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.verified_rounded,
              size: 16, color: Color(0xFF2347D4)),
          const SizedBox(width: 8),
          const Text('Verification Summary',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A))),
        ]),
        const SizedBox(height: 10),
        _verifyRow(Icons.wifi_rounded, 'Campus WiFi verified'),
        const SizedBox(height: 6),
        _verifyRow(Icons.my_location_rounded, 'Campus subnet confirmed'),
        const SizedBox(height: 6),
        _verifyRow(Icons.phone_android_rounded, 'Registered device used'),
        const SizedBox(height: 6),
        _verifyRow(Icons.qr_code_rounded, 'Valid QR code scanned'),
      ]),
    ).animate(delay: 600.ms).fadeIn();
  }

  Widget _buildAttendanceTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFD97706)),
        const SizedBox(width: 8),
        const Expanded(
            child: Text(
          'Remember: Maintain 75% attendance per subject to be eligible for end-semester exams.',
          style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
        )),
      ]),
    ).animate(delay: 700.ms).fadeIn();
  }

  Widget _buildButtons() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (_) => false),
          icon: const Icon(Icons.home_rounded, size: 20),
          label: const Text('Back to Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2347D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (_) => false),
          icon: const Icon(Icons.grid_view_rounded, size: 18),
          label: const Text('View Attendance Portal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2347D4),
              side: const BorderSide(color: Color(0xFF2347D4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
        ),
      ),
    ]).animate(delay: 800.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 16, color: const Color(0xFF2347D4)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const Spacer(),
          Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1729)))),
        ]),
      );

  Widget _verifyRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: const Color(0xFF2347D4)),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
        const Spacer(),
        const Icon(Icons.check_rounded, size: 13, color: Color(0xFF16A34A)),
      ]);

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF3F4F6));
}
