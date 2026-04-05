import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../services/analytics_ai_service.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  List<AttendanceSession> _sessions = [];
  List<Map<String, dynamic>> _defaulters = [];
  Map<String, Map<String, dynamic>> _subjectAnalytics = {};
  
  String? _selectedSemester;
  String? _selectedSubject;
  final String _activeFilter = 'Total'; // 'Total', 'Above 75%', 'Below 75%'
  bool _loading = true;

  final List<String> _semesters = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5', 'Sem 6', 'Sem 7', 'Sem 8'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final sessions = await SessionService.getPastSessions();
    final defaulters = await SessionService.getDefaulters(
      subject: _selectedSubject,
      semester: _selectedSemester,
    );
    final analytics = await SessionService.getSubjectAnalytics(
      semester: _selectedSemester,
    );

    // Apply local filtering for sessions list
    var filteredSessions = sessions;
    if (_selectedSemester != null) {
      filteredSessions = filteredSessions.where((AttendanceSession s) => s.semester == _selectedSemester).toList();
    }
    if (_selectedSubject != null) {
      filteredSessions = filteredSessions.where((AttendanceSession s) => s.subject == _selectedSubject).toList();
    }

    if (mounted) {
      setState(() {
        _sessions = filteredSessions;
        _defaulters = defaulters;
        _subjectAnalytics = analytics;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewCards(),
                            const SizedBox(height: 20),
                            _buildAIInsightCards(),
                            const SizedBox(height: 20),
                            _buildTrendChart(),
                            const SizedBox(height: 20),
                            _buildSubjectFilter(),
                            const SizedBox(height: 20),
                            _buildSubjectCharts(),
                            const SizedBox(height: 20),
                            _buildDefaulterSection(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                  ),
                  const Text('AI Faculty Analytics',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Semester',
                      _selectedSemester,
                      _semesters,
                      (val) {
                        setState(() {
                          _selectedSemester = val;
                          _selectedSubject = null; // Reset subject on semester change
                        });
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Subject',
                      _selectedSubject,
                      _subjectAnalytics.keys.toList(),
                      (val) {
                        setState(() => _selectedSubject = val);
                        _loadData();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          dropdownColor: const Color(0xFFFFFFFF),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(value: null, child: Text('All $hint', style: const TextStyle(color: Colors.white, fontSize: 13))),
            ...items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 13)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No session data yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          const Text('Complete attendance sessions to see analytics',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  void _showStudentList(String title, List<Map<String, dynamic>> students) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _StudentDrillDownSheet(title: title, students: students),
    );
  }

  Widget _buildOverviewCards() {
    final totalRoster = SessionService.getInitialRoster();
    final totalCount = totalRoster.length;
    final below75Count = _defaulters.length;
    
    // Calculate Safe Count based on session history
    // For now, if we have past sessions, we can derive this. 
    // If not, we show 0 or total-defaulters if we assume all others are safe.
    final above75Count = totalCount - below75Count;

    return Row(
      children: [
        Expanded(
          child: _overviewCard(
            Icons.people_alt_rounded,
            'Total Students',
            '$totalCount',
            const Color(0xFFFFFFFF),
            const Color(0xFFEFF6FF),
            () => _showStudentList('Total Students', totalRoster.map((StudentAttendanceEntry s) => <String, dynamic>{'name': s.name, 'rollNumber': s.rollNumber, 'percentage': 100.0}).toList()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            Icons.check_circle_rounded,
            'Above 75%',
            '$above75Count',
            const Color(0xFF059669),
            const Color(0xFFDCFCE7),
            () => {}, // Drill down logic for safe students
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            Icons.warning_rounded,
            'Below 75%',
            '$below75Count',
            const Color(0xFFEF4444),
            const Color(0xFFFFE4E6),
            () => _showStudentList('At Risk (<75%)', _defaulters),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _overviewCard(IconData icon, String label, String value, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectFilter() {
    final subjects = _subjectAnalytics.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All Subjects', _selectedSubject == null, () {
            setState(() => _selectedSubject = null);
          }),
          ...subjects.map((s) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _filterChip(s, _selectedSubject == s, () {
                  setState(() => _selectedSubject = s);
                }),
              )),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFFFFF)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _buildSubjectCharts() {
    final filteredAnalytics = _selectedSubject != null
        ? {_selectedSubject!: _subjectAnalytics[_selectedSubject!]!}
        : _subjectAnalytics;

    if (filteredAnalytics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject-wise Attendance',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF))),
        const SizedBox(height: 12),
        ...filteredAnalytics.entries.map((entry) {
          final data = entry.value;
          final totalStudents = (data['totalStudents'] as int?) ?? 0;
          final totalPresent = (data['totalPresent'] as int?) ?? 0;
          final totalLate = (data['totalLate'] as int?) ?? 0;
          final totalAbsent = (data['totalAbsent'] as int?) ?? 0;
          final sessions = (data['totalSessions'] as int?) ?? 0;
          final pct =
              totalStudents > 0
                  ? (totalPresent / totalStudents * 100).round()
                  : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            size: 18, color: Color(0xFFFFFFFF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('$sessions sessions conducted',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pct >= 75
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$pct%',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: pct >= 75
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Bar chart row
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          if (totalPresent > 0)
                            Expanded(
                              flex: totalPresent,
                              child: Container(
                                color: const Color(0xFF059669),
                                alignment: Alignment.center,
                                child: totalPresent > 5
                                    ? Text('$totalPresent',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600))
                                    : null,
                              ),
                            ),
                          if (totalLate > 0)
                            Expanded(
                              flex: totalLate,
                              child: Container(
                                color: const Color(0xFFF59E0B),
                                alignment: Alignment.center,
                                child: totalLate > 5
                                    ? Text('$totalLate',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600))
                                    : null,
                              ),
                            ),
                          if (totalAbsent > 0)
                            Expanded(
                              flex: totalAbsent,
                              child: Container(
                                color: const Color(0xFFEF4444),
                                alignment: Alignment.center,
                                child: totalAbsent > 5
                                    ? Text('$totalAbsent',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600))
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Legend
                  Row(
                    children: [
                      _legend(const Color(0xFF059669), 'Present'),
                      const SizedBox(width: 12),
                      _legend(const Color(0xFFF59E0B), 'Late'),
                      const SizedBox(width: 12),
                      _legend(const Color(0xFFEF4444), 'Absent'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ).animate(delay: 200.ms).fadeIn();
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildDefaulterSection() {
    final defaulters = _selectedSubject != null
        ? _defaulters.where((d) => true).toList() // filter would need subject
        : _defaulters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_rounded,
                size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 6),
            const Text('Defaulters (Below 75%)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444))),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${defaulters.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (defaulters.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration_rounded,
                    color: Color(0xFF059669), size: 20),
                SizedBox(width: 8),
                Text('No defaulters! All students above 75%',
                    style: TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          )
        else
          ...defaulters.map((d) {
            final pct = (d['percentage'] as double).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: pct < 65
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: pct < 65
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${d['name']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${d['rollNumber']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pct < 65
                            ? const Color(0xFFFFE4E6)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$pct%',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: pct < 65
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B))),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    ).animate(delay: 300.ms).fadeIn();
  }

  // ── AI Insight Cards ───────────────────────────────────────────────────────

  Widget _buildAIInsightCards() {
    final insights = AnalyticsAIService.generateInsights(
      sessions: _sessions,
      studentStats: _defaulters, // We pass defaulters as risk input
      subject: _selectedSubject,
      semester: _selectedSemester,
    );

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.psychology_rounded, size: 16, color: Color(0xFFFFFFFF)),
            ),
            const SizedBox(width: 10),
            const Text('Intelligent Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
            const Spacer(),
            Text('${insights.length} Patterns Found', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
          ],
        ),
        const SizedBox(height: 12),
        ...insights.asMap().entries.map((e) {
          final insight = e.value;
          final color = insight['isCritical'] ? const Color(0xFFEF4444) : const Color(0xFF2C2C2C);
          final bg = insight['isCritical'] ? const Color(0xFFFFE4E6) : const Color(0xFFEEF2FF);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(insight['isCritical'] ? Icons.warning_amber_rounded : Icons.tips_and_updates_rounded, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(height: 4),
                      Text(insight['message'], style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: (e.key * 100).ms).slideX(begin: 0.05).fadeIn();
        }),
      ],
    );
  }

  // Old _generateAIInsights removed in favor of AnalyticsAIService

  // ── Trend Chart ────────────────────────────────────────────────────────────

  Widget _buildTrendChart() {
    if (_sessions.length < 2) return const SizedBox.shrink();

    final displayed = _sessions.reversed.take(7).toList();
    final dataPoints = displayed.map((s) {
      final total = s.students.length;
      final present = s.presentCount + s.lateCount;
      return total > 0 ? (present / total * 100) : 0.0;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Trend (Last Sessions)',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFFFFF)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: _TrendLineChart(
                  dataPoints: dataPoints,
                  sessions: displayed,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legend(const Color(0xFF059669), 'Above 75%'),
                  const SizedBox(width: 16),
                  _legend(const Color(0xFFEF4444), 'Below 75%'),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 2,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      const Text('75% line',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF6B7280))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate(delay: 100.ms).fadeIn();
  }
}

// ── Trend Line Chart Widget ─────────────────────────────────────────────────

class _TrendLineChart extends StatelessWidget {
  final List<double> dataPoints;
  final List<AttendanceSession> sessions;

  const _TrendLineChart(
      {required this.dataPoints, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _TrendLinePainter(dataPoints: dataPoints),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> dataPoints;

  const _TrendLinePainter({required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.2),
        Offset(0, size.height),
        [const Color(0xFFFFFFFF).withOpacity(0.3), const Color(0xFFFFFFFF).withOpacity(0.0)],
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    final double spacing = size.width / (dataPoints.length - 1);
    final double chartHeight = size.height - 20;

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * spacing;
      final double y = chartHeight - (dataPoints[i] / 100 * chartHeight) + 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final double prevX = (i - 1) * spacing;
        final double prevY = chartHeight - (dataPoints[i - 1] / 100 * chartHeight) + 10;
        
        // Use cubic Bezier for smooth curves
        final double controlX1 = prevX + (x - prevX) / 2;
        final double controlY1 = prevY;
        final double controlX2 = prevX + (x - prevX) / 2;
        final double controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots at points
    for (int i = 0; i < dataPoints.length; i++) {
       final double x = i * spacing;
       final double y = chartHeight - (dataPoints[i] / 100 * chartHeight) + 10;
       
       canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white..style = PaintingStyle.fill);
       canvas.drawCircle(Offset(x, y), 5, paint..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) => oldDelegate.dataPoints != dataPoints;
}

// ── DRILL-DOWN STUDENT LIST SHEET ──────────────────────────────────────────

class _StudentDrillDownSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> students;

  const _StudentDrillDownSheet({required this.title, required this.students});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
                    Text('${students.length} students found', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final s = students[index];
                final pct = (s['percentage'] as double).round();
                final isRisk = pct < 75;
                final color = isRisk ? const Color(0xFFEF4444) : const Color(0xFF059669);

                return InkWell(
                  onTap: () => _showRecommendation(context, s),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
                          child: Center(
                            child: Text(s['name'][0], style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                              Text(s['rollNumber'], style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          height: 20,
                          child: CustomPaint(
                            painter: _SparklinePainter(color: color, data: isRisk ? [0.6, 0.4, 0.5, 0.3, 0.2] : [0.7, 0.8, 0.85, 0.9, 0.95]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$pct%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                            Text(isRisk ? 'At Risk' : 'Safe', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color.withOpacity(0.7))),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRecommendation(BuildContext context, Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecommendationSheet(student: student),
    );
  }
}

class _RecommendationSheet extends StatelessWidget {
  final Map<String, dynamic> student;

  const _RecommendationSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    final pct = (student['percentage'] as double).round();
    final isRisk = pct < 75;
    
    // Mock classes for calculation (In real app, we fetch from stats)
    const totalClasses = 20.0; // Mock current subject session count
    final attended = (totalClasses * (pct / 100)).round();
    
    final classesNeeded = AnalyticsAIService.classesToReach75(attended, totalClasses.toInt());

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(width: 16),
              const Text('AI Recommendation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isRisk 
              ? 'Student ${student['name']} is currently below the mandatory 75% attendance threshold.'
              : 'Student ${student['name']} is maintaining a healthy attendance record.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          if (isRisk) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  const Row(
                    children: [
                       Icon(Icons.lightbulb_rounded, color: Color(0xFFEAB308), size: 18),
                       SizedBox(width: 10),
                       Text('Goal to reach 75%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Must attend next $classesNeeded classes consecutively',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Got it', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
class _SparklinePainter extends CustomPainter {
  final Color color;
  final List<double> data;
  _SparklinePainter({required this.color, required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    final spacing = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
        final x = i * spacing;
        final y = size.height - (data[i] * size.height);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
