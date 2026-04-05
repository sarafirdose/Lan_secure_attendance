import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'teacher_login_screen.dart';
import 'admin_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int? _selectedRole;

  final _roles = [
    const _RoleData(
      title: 'Student',
      subtitle: 'Mark attendance via QR scan',
      icon: Icons.person_rounded,
    ),
    const _RoleData(
      title: 'Teacher',
      subtitle: 'Generate QR & manage classes',
      icon: Icons.school_rounded,
    ),
    const _RoleData(
      title: 'Admin',
      subtitle: 'Full system control & reports',
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  void _proceed() {
    if (_selectedRole == null) return;
    Widget screen;
    switch (_selectedRole) {
      case 0: screen = const LoginScreen(); break;
      case 1: screen = const TeacherLoginScreen(); break;
      case 2: screen = const AdminLoginScreen(); break;
      default: return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Elite Logo Container
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                ),
                child: const Icon(Icons.security_rounded,
                    color: Color(0xFF0056B3), size: 42),
              ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
            ),

            const SizedBox(height: 24),

            const Text('SecureAttend',
                style: TextStyle(
                    color: Color(0xFF0056B3),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0))
                .animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 8),

            const Text('Identify your faculty role to proceed',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 15,
                    fontWeight: FontWeight.w500))
                .animate(delay: 200.ms).fadeIn(),

            const Spacer(),

            // Elite Role cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ...List.generate(_roles.length, (i) {
                    final role = _roles[i];
                    final isSelected = _selectedRole == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCirc,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0056B3)
                                  : const Color(0xFFEEEEEE),
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: isSelected ? [
                               BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ] : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(role.icon,
                                    color: isSelected ? const Color(0xFF0056B3) : const Color(0xFF94A3B8),
                                    size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(role.title,
                                        style: TextStyle(
                                            color: isSelected ? const Color(0xFF0056B3) : const Color(0xFF334155),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(role.subtitle,
                                        style: TextStyle(
                                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF0056B3), size: 28)
                                    .animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                            ],
                          ),
                        ),
                      ),
                    ).animate(delay: (300 + i * 150).ms)
                        .fadeIn()
                        .slideY(begin: 0.1, curve: Curves.easeOut);
                  }),

                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _selectedRole != null ? _proceed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056B3),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE0E0E0),
                        disabledForegroundColor: const Color(0xFF9E9E9E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Continue',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, size: 22)
                              .animate(onPlay: (c) => c.repeat())
                              .moveX(begin: 0, end: 5, duration: 1.seconds, curve: Curves.easeInOut)
                              .then()
                              .moveX(begin: 5, end: 0, duration: 1.seconds, curve: Curves.easeInOut),
                        ],
                      ),
                    ),
                  ).animate(delay: 800.ms).fadeIn(),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RoleData {
  final String title;
  final String subtitle;
  final IconData icon;
  const _RoleData({required this.title, required this.subtitle, required this.icon});
}
