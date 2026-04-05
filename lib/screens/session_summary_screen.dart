import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/session_model.dart';
import 'teacher_dashboard_screen.dart';

class SessionSummaryScreen extends StatelessWidget {
  final AttendanceSession session;

  const SessionSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final present = session.presentCount;
    final absent = session.absentCount;
    final late_ = session.lateCount;
    final special = session.specialCount;
    final total = session.students.length;
    final pct = total > 0 ? (present / total * 100).round() : 0;
    final duration = session.duration;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        const Text('Session Complete!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          '${session.subject} — ${session.classLabel}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),

                  // Circular progress
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    value: total > 0 ? present / total : 0,
                                    strokeWidth: 12,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF059669)),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$pct%',
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFFFFFF))),
                                    const Text('Attendance',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _summaryChip('Present', '$present',
                                  const Color(0xFF059669)),
                              _summaryChip(
                                  'Absent', '$absent', const Color(0xFFEF4444)),
                              _summaryChip(
                                  'Late', '$late_', const Color(0xFFF59E0B)),
                              if (special > 0)
                                _summaryChip('Special', '$special',
                                    const Color(0xFF8B5CF6)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 20),

                  // Student breakdown
                  const Text('Student Breakdown',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFFFFF))),
                  const SizedBox(height: 12),

                  // Present students
                  if (_getByStatus(StudentStatus.present).isNotEmpty)
                    _statusSection('✅ Present', _getByStatus(StudentStatus.present),
                        const Color(0xFF059669)),

                  if (_getByStatus(StudentStatus.late).isNotEmpty)
                    _statusSection('⏰ Late', _getByStatus(StudentStatus.late),
                        const Color(0xFFF59E0B)),

                  if (_getSpecialStudents().isNotEmpty)
                    _statusSection('📋 Special Cases', _getSpecialStudents(),
                        const Color(0xFF8B5CF6)),

                  if (_getByStatus(StudentStatus.absent).isNotEmpty)
                    _statusSection('❌ Absent', _getByStatus(StudentStatus.absent),
                        const Color(0xFFEF4444)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white60, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Session Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _statusSection(
      String title, List<StudentAttendanceEntry> students, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${students.length}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...students.map((s) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(s.name[0],
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFFFFF))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text(s.rollNumber,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<StudentAttendanceEntry> _getByStatus(StudentStatus status) {
    return session.students.where((s) => s.status == status).toList();
  }

  List<StudentAttendanceEntry> _getSpecialStudents() {
    return session.students
        .where((s) =>
            s.status == StudentStatus.sports ||
            s.status == StudentStatus.medical ||
            s.status == StudentStatus.placement)
        .toList();
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            // Pop back to teacher dashboard
            // Safely return to dashboard
            // Safely return to dashboard and clear the stack to avoid logout loop
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_rounded, size: 20),
              SizedBox(width: 8),
              Text('Back to Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
