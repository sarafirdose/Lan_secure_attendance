import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/attendance_model.dart';
import '../services/attendance_data_service.dart';

class StudentPortalScreen extends StatefulWidget {
  const StudentPortalScreen({super.key});

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  final List<SubjectAttendance> _subjects =
      AttendanceDataService.getMockAttendance();
  String _filter = 'all';
  final Set<int> _expandedIndexes = {};

  // ── Totals ──────────────────────────────────────────────────────────────────
  int get _totalPresent =>
      _subjects.fold<int>(0, (s, e) => s + e.attendedClasses);
  int get _totalAbsent => _subjects.fold<int>(0, (s, e) => s + e.absentClasses);
  int get _totalLate => _subjects.fold<int>(0, (s, e) => s + e.lateCount);
  int get _totalClasses => _subjects.fold<int>(0, (s, e) => s + e.totalClasses);
  double get _overallPct =>
      _totalClasses == 0 ? 0 : (_totalPresent / _totalClasses) * 100;

  List<SubjectAttendance> get _filtered {
    if (_filter == 'danger') {
      return _subjects
          .where((s) => s.health == AttendanceHealth.danger)
          .toList();
    }
    if (_filter == 'safe') {
      return _subjects
          .where((s) => s.health != AttendanceHealth.danger)
          .toList();
    }
    return _subjects;
  }

  List<SubjectAttendance> get _dangerSubjects =>
      _subjects.where((s) => s.health == AttendanceHealth.danger).toList();

  // Exam eligibility — needs 75% overall
  bool get _isEligible => _overallPct >= 75;

  // Monthly data for bar chart
  // Each entry: {month, present, absent}
  final List<Map<String, dynamic>> _monthlyData = const [
    {'month': 'Jan', 'present': 18, 'absent': 4},
    {'month': 'Feb', 'present': 20, 'absent': 2},
    {'month': 'Mar', 'present': 19, 'absent': 3},
    {'month': 'Apr', 'present': 22, 'absent': 1},
    {'month': 'May', 'present': 17, 'absent': 5},
    {'month': 'Jun', 'present': 16, 'absent': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _buildOverallCard(),
                const SizedBox(height: 10),
                _buildCondonationCard(),
                if (_dangerSubjects.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildWarningBanner(),
                ],
                const SizedBox(height: 12),
                _buildFilterRow(),
                const SizedBox(height: 4),
                ..._filtered.asMap().entries.map((e) {
                  final i = _subjects.indexOf(e.value);
                  return _buildSubjectCard(e.value, i);
                }),
                const SizedBox(height: 12),
                _buildMonthlyChart(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF2347D4),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text('SA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Student Portal',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('AK',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arjun Kumar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('CS2022045  |  CSE  |  3rd Year  |  Sec B',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Overall donut card ───────────────────────────────────────────────────────
  Widget _buildOverallCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(72, 72),
                  painter: _DonutPainter(percentage: _overallPct),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_overallPct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F1729))),
                      const Text('overall',
                          style:
                              TextStyle(fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Semester attendance',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F1729))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statPill('$_totalPresent', 'Present',
                        const Color(0xFF3B6D11), const Color(0xFFEAF3DE)),
                    const SizedBox(width: 6),
                    _statPill('$_totalLate', 'Late', const Color(0xFF854F0B),
                        const Color(0xFFFAEEDA)),
                    const SizedBox(width: 6),
                    _statPill('$_totalAbsent', 'Absent',
                        const Color(0xFFA32D2D), const Color(0xFFFCEBEB)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label, Color textColor, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  // ── Condonation / exam eligibility card ─────────────────────────────────────
  Widget _buildCondonationCard() {
    final eligible = _isEligible;
    final Color cardBg =
        eligible ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB);
    final Color iconColor =
        eligible ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D);
    final Color textColor =
        eligible ? const Color(0xFF27500A) : const Color(0xFF791F1F);
    final IconData icon =
        eligible ? Icons.verified_rounded : Icons.warning_rounded;
    final String title =
        eligible ? 'Eligible for exams' : 'Not eligible for exams';
    final String subtitle = eligible
        ? 'Your overall attendance meets the 75% requirement'
        : 'You need ${(75 - _overallPct).toStringAsFixed(1)}% more attendance to become eligible';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                eligible ? const Color(0xFF97C459) : const Color(0xFFF09595)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 11, color: textColor, height: 1.4)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_overallPct.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColor)),
          ),
        ],
      ),
    );
  }

  // ── Warning banner ───────────────────────────────────────────────────────────
  Widget _buildWarningBanner() {
    final names = _dangerSubjects.map((s) => s.name).join(' & ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFAC775)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
                color: Color(0xFFEF9F27), shape: BoxShape.circle),
            child: const Center(
              child: Text('!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$names ${_dangerSubjects.length == 1 ? 'is' : 'are'} below 75% — tap to see missed classes',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF633806), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter row ───────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Row(
      children: [
        _filterChip('All', 'all'),
        const SizedBox(width: 6),
        _filterChip('Below 75%', 'danger'),
        const SizedBox(width: 6),
        _filterChip('Above 75%', 'safe'),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2347D4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? const Color(0xFF2347D4)
                  : Colors.black.withValues(alpha: 0.12)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : Colors.black54)),
      ),
    );
  }

  // ── Subject card ─────────────────────────────────────────────────────────────
  Widget _buildSubjectCard(SubjectAttendance subject, int index) {
    final expanded = _expandedIndexes.contains(index);
    final health = subject.health;

    Color accentColor;
    Color bgColor;
    Color textColor;
    switch (health) {
      case AttendanceHealth.safe:
        accentColor = const Color(0xFF639922);
        bgColor = const Color(0xFFEAF3DE);
        textColor = const Color(0xFF27500A);
      case AttendanceHealth.warning:
        accentColor = const Color(0xFFEF9F27);
        bgColor = const Color(0xFFFAEEDA);
        textColor = const Color(0xFF633806);
      case AttendanceHealth.danger:
        accentColor = const Color(0xFFE24B4A);
        bgColor = const Color(0xFFFCEBEB);
        textColor = const Color(0xFF791F1F);
    }

    final initials =
        subject.name.split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              expanded
                  ? _expandedIndexes.remove(index)
                  : _expandedIndexes.add(index);
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(initials,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subject.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F1729))),
                            Text(subject.code,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black45)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('${subject.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.chevron_right,
                            size: 18, color: Colors.black38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: subject.percentage / 100,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniStat('Present', '${subject.attendedClasses}'),
                      _miniStat('Absent', '${subject.absentClasses}'),
                      _miniStat('Late', '${subject.lateCount}'),
                      _miniStat('Total', '${subject.totalClasses}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildAbsenceLog(
                subject, accentColor, bgColor, textColor, health),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: Colors.black45),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF0F1729))),
        ],
      ),
    );
  }

  // ── Absence log ──────────────────────────────────────────────────────────────
  Widget _buildAbsenceLog(SubjectAttendance subject, Color accentColor,
      Color bgColor, Color textColor, AttendanceHealth health) {
    final missed = subject.recentRecords
        .where((r) =>
            r.status == AttendanceStatus.absent ||
            r.status == AttendanceStatus.late)
        .toList();
    final needed = subject.classesNeededFor(75);

    String badgeLabel;
    Color badgeBg;
    Color badgeText;
    if (health == AttendanceHealth.safe) {
      badgeLabel = 'Safe zone';
      badgeBg = const Color(0xFFE6F1FB);
      badgeText = const Color(0xFF0C447C);
    } else if (health == AttendanceHealth.warning) {
      badgeLabel = 'Attend $needed more';
      badgeBg = const Color(0xFFFAEEDA);
      badgeText = const Color(0xFF633806);
    } else {
      badgeLabel = 'Attend next $needed';
      badgeBg = const Color(0xFFFCEBEB);
      badgeText = const Color(0xFF791F1F);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Text('MISSED CLASSES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black38,
                      letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(20)),
                child: Text(badgeLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: badgeText)),
              ),
            ],
          ),
        ),
        if (missed.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text('No missed classes — perfect attendance!',
                style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF3B6D11),
                    fontStyle: FontStyle.italic)),
          )
        else
          ...missed.map((r) => _absenceRow(r)),
        if (health != AttendanceHealth.safe)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Text(
              health == AttendanceHealth.warning
                  ? 'Attend the next $needed consecutive classes to move safely above 75%.'
                  : 'Critical: You need $needed more classes. Missing even one more makes recovery very difficult.',
              style: TextStyle(fontSize: 11, color: textColor, height: 1.5),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _absenceRow(AttendanceRecord r) {
    final isAbsent = r.status == AttendanceStatus.absent;
    final months = [
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
    final day = r.date.day.toString();
    final month = months[r.date.month - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Text(day,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1729),
                        height: 1)),
                Text(month,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black45)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.topic,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F1729))),
                Text('${r.day}  ${r.time}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  isAbsent ? const Color(0xFFFCEBEB) : const Color(0xFFFAEEDA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAbsent ? 'Absent' : 'Late',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isAbsent
                      ? const Color(0xFF791F1F)
                      : const Color(0xFF633806)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly bar chart ────────────────────────────────────────────────────────
  Widget _buildMonthlyChart() {
    final maxVal = _monthlyData
        .map((m) => (m['present'] as int) + (m['absent'] as int))
        .reduce(math.max)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Monthly overview',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1729))),
              const Spacer(),
              // Legend
              Row(
                children: [
                  _legendDot(const Color(0xFF2347D4), 'Present'),
                  const SizedBox(width: 10),
                  _legendDot(const Color(0xFFE24B4A), 'Absent'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyData.map((m) {
                final present = (m['present'] as int).toDouble();
                final absent = (m['absent'] as int).toDouble();
                final presentH = (present / maxVal) * 90;
                final absentH = (absent / maxVal) * 90;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Absent bar (top)
                      Container(
                        height: absentH,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE24B4A),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      // Present bar (bottom)
                      Container(
                        height: presentH,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2347D4),
                          borderRadius: absentH == 0
                              ? BorderRadius.circular(4)
                              : const BorderRadius.vertical(
                                  bottom: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(m['month'] as String,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }
}

// ── Donut painter ─────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double percentage;
  const _DonutPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 6;
    const strokeW = 7.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFE6F1FB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final fillPaint = Paint()
      ..color = const Color(0xFF2347D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);
    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.percentage != percentage;
}
