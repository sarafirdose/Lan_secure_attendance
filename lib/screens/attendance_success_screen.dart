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
  late AnimationController _pulseCtrl;
  String _fullName = '';
  String _rollNumber = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await AuthService.getCachedUserData();
    if (mounted) {
      setState(() {
        _fullName = data['fullName'] ?? 'Student';
        _rollNumber = data['rollNumber'] ?? widget.rollNumber;
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${now.day} ${months[now.month - 1]}, ${now.year}';
  }

  String _formatTime() {
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Elegant Blue/White background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF0F7FF), Colors.white],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  // Success Animated Icon
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ScaleTransition(
                          scale: Tween(begin: 0.9, end: 1.1).animate(_pulseCtrl),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF059669).withOpacity(0.05),
                            ),
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF059669),
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Attendance Verified',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF000000),
                      letterSpacing: -1.2,
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 8),

                  const Text(
                    'Your presence has been recorded securely',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 48),

                  // Modern Receipt Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF0056B3).withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Subject', widget.subject, isPrimary: true),
                        _divider(),
                        _buildRow('Course Code', widget.subjectCode),
                        _divider(),
                        _buildRow('Student', _fullName.isEmpty ? 'Student' : _fullName),
                        _divider(),
                        _buildRow('Roll Number', _rollNumber.isEmpty ? widget.rollNumber : _rollNumber),
                        _divider(),
                        _buildRow('Date', _formatDate()),
                        _divider(),
                        _buildRow('Time', _formatTime()),
                      ],
                    ),
                  ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 48),

                  // Verification Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Authenticated Student Session',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 800.ms).fadeIn(),

                  const SizedBox(height: 48),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (_) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056B3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Return to Dashboard',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                  ).animate(delay: 1.seconds).fadeIn().slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0xFFF1F5F9));
}
