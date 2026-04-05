import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/attendance_model.dart';
import '../services/attendance_data_service.dart';
import '../widgets/attendance_forecast_graph.dart';

class StudentRiskScreen extends StatefulWidget {
  const StudentRiskScreen({super.key});

  @override
  State<StudentRiskScreen> createState() => _StudentRiskScreenState();
}

class _StudentRiskScreenState extends State<StudentRiskScreen>
    with SingleTickerProviderStateMixin {
  // Interactive input controllers
  final _totalCtrl = TextEditingController(text: '24');
  final _attendedCtrl = TextEditingController(text: '18');
  final _upcomingCtrl = TextEditingController(text: '12');
  bool _showCalculator = true;

  // AI Insights
  double _confidence = 85.0;
  String _predictionReason = 'Based on average class participation.';
  List<AttendanceRecord> _history = [];

  // Computed values from calculator
  int _totalClasses = 24;
  int _attendedClasses = 18;
  int _upcomingClasses = 12;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  // Static subject-wise data
  final List<Map<String, dynamic>> _subjects = const [
    {
      'name': 'Software Engineering',
      'code': 'CSU633',
      'present': 18,
      'total': 24,
      'upcoming': 12,
    },
    {
      'name': 'Data Structures',
      'code': 'CSU412',
      'present': 14,
      'total': 20,
      'upcoming': 10,
    },
    {
      'name': 'Computer Networks',
      'code': 'CSU521',
      'present': 10,
      'total': 18,
      'upcoming': 8,
    },
    {
      'name': 'Database Management',
      'code': 'CSU314',
      'present': 8,
      'total': 16,
      'upcoming': 6,
    },
    {
      'name': 'Operating Systems',
      'code': 'CSU445',
      'present': 12,
      'total': 22,
      'upcoming': 10,
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim = Tween<double>(begin: 0, end: _percentage / 100)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward();
    _loadHistory();
  }

  void _loadHistory() {
    final mockData = AttendanceDataService.getMockAttendance();
    if (mockData.isNotEmpty) {
      setState(() {
        _history = mockData[0].recentRecords;
      });
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _totalCtrl.dispose();
    _attendedCtrl.dispose();
    _upcomingCtrl.dispose();
    super.dispose();
  }

  double get _percentage =>
      _totalClasses == 0 ? 0 : (_attendedClasses / _totalClasses) * 100;

  int get _classesNeeded {
    if (_percentage >= 75 || _totalClasses == 0) return 0;
    for (int i = 1; i <= _upcomingClasses; i++) {
      if ((_attendedClasses + i) / (_totalClasses + i) * 100 >= 75) return i;
    }
    return _upcomingClasses;
  }

  int get _canMiss {
    int canMiss = 0;
    for (int i = 0; i <= _upcomingClasses; i++) {
      if (_attendedClasses / (_totalClasses + i) * 100 >= 75) {
        canMiss = i;
      } else {
        break;
      }
    }
    return canMiss;
  }

  String get _riskLevel {
    if (_percentage >= 85) return 'Safe';
    if (_percentage >= 75) return 'Moderate';
    if (_percentage >= 65) return 'Risky';
    return 'Critical';
  }


  void _calculate() {
    final total = int.tryParse(_totalCtrl.text) ?? 0;
    final attended = int.tryParse(_attendedCtrl.text) ?? 0;
    final upcoming = int.tryParse(_upcomingCtrl.text) ?? 0;

    if (attended > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attended classes cannot exceed total classes'),
          backgroundColor: const Color(0xFFEF4444),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final newPct =
        total == 0 ? 0.0 : (attended / total * 100);

    setState(() {
      _totalClasses = total;
      _attendedClasses = attended;
      _upcomingClasses = upcoming;

      // Calculate confidence based on data completeness
      if (total > 0 && _history.length > 3) {
        _confidence = 85.0 + (math.min(_history.length, 5) * 2.5);
        
        // Simple slope-based explanation
        int recentPresent = _history.where((r) => r.status == AttendanceStatus.present).length;
        if (recentPresent >= 4) {
          _predictionReason = 'Consistent attendance in recent sessions.';
        } else if (recentPresent <= 1) {
          _predictionReason = 'Declining trend detected in last 5 sessions.';
        } else {
          _predictionReason = 'Variable attendance pattern identified.';
        }
      } else {
        _confidence = 70.0;
        _predictionReason = 'Limited historical data for precise trend analysis.';
      }
    });

    _progressCtrl.reset();
    _progressAnim = Tween<double>(begin: 0, end: newPct / 100)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _subjects
        .where((s) => s['present'] / s['total'] * 100 < 75)
        .length;

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
                  // ── Interactive Calculator Card ────────────────────────────
                  _buildCalculatorCard(),
                  const SizedBox(height: 16),

                  _buildAiInsightsPanel(),
                  const SizedBox(height: 20),

                  // ── Live Prediction Card ───────────────────────────────────
                  _buildLivePredictionCard(),
                  const SizedBox(height: 20),

                  // ── Subject Breakdown ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subject-wise Analysis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: criticalCount > 0
                              ? const Color(0xFFFFE4E6)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          criticalCount > 0
                              ? '$criticalCount at risk'
                              : 'All safe',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: criticalCount > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 12),

                  ..._subjects.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final pct = s['present'] / s['total'] * 100;
                    return _buildSubjectCard(s, pct, i)
                        .animate(
                          delay: Duration(milliseconds: 100 * i + 300),
                        )
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.2, curve: Curves.easeOut);
                  }),

                  const SizedBox(height: 20),

                  // ── AI Tips ────────────────────────────────────────────────
                  _buildAITips(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF2C2C2C), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white60, size: 16),
                  const SizedBox(width: 4),
                  Text('Back',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Attendance Forecast',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Smart prediction & risk analysis',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _percentage >= 75
                          ? const Color(0xFF059669)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _percentage >= 75 ? '✓ Safe' : '⚠ At Risk',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
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

  // ── Interactive Calculator Card ─────────────────────────────────────────────

  Widget _buildCalculatorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Title row
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () => setState(() => _showCalculator = !_showCalculator),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calculate_rounded,
                        size: 20, color: Color(0xFFFFFFFF)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance Calculator',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFFFFF))),
                        Text('Enter your class data',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showCalculator ? 0.25 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _showCalculator
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          controller: _totalCtrl,
                          label: 'Total Classes',
                          hint: 'e.g. 30',
                          icon: Icons.class_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _inputField(
                          controller: _attendedCtrl,
                          label: 'Attended',
                          hint: 'e.g. 22',
                          icon: Icons.how_to_reg_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _inputField(
                          controller: _upcomingCtrl,
                          label: 'Upcoming',
                          hint: 'e.g. 10',
                          icon: Icons.upcoming_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.auto_graph_rounded, size: 18),
                      label: const Text('Calculate & Predict',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
  }

  // ── AI Insights Panel ──────────────────────────────────────────────────────
  Widget _buildAiInsightsPanel() {
    if (_totalCtrl.text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded,
                    size: 22, color: Color(0xFF2C2C2C)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Insight Engine',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFFFFF))),
                    Text('Deep neural trend analysis',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('${_confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const Text('CONFIDENCE',
                        style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // THE GRAPH
          AttendanceForecastGraph(
            recentRecords: _history,
            currentPercentage: _percentage,
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFFFFFFF)),
          const SizedBox(height: 16),
          _insightRow(Icons.auto_awesome_rounded, 'Forecast Basis', _predictionReason),
          const SizedBox(height: 10),
          _insightRow(
            Icons.speed_rounded, 
            'Stability Status', 
            _percentage >= 85 ? 'Highly Resilient' : _percentage >= 75 ? 'Optimal' : 'Immediate Intervention'
          ),
          const SizedBox(height: 10),
          _insightRow(Icons.security_rounded, 'Logic Layer', 'Secure QR Protocol v2.1'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _insightRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text('$label:',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
        ),
      ],
    );
  }


  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFFFFF)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 15),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFFFFFFF), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Live Prediction Card ────────────────────────────────────────────────────

  Widget _buildLivePredictionCard() {
    final pct = _percentage;

    String predictionMsg;
    if (pct >= 75) {
      if (_canMiss > 0) {
        predictionMsg =
            'You can afford to miss up to $_canMiss upcoming classes and still stay above 75%.';
      } else {
        predictionMsg =
            'You are right at 75%. Attend all upcoming classes to maintain eligibility.';
      }
    } else {
      if (_classesNeeded <= _upcomingClasses) {
        predictionMsg =
            'Attend the next $_classesNeeded classes continuously to reach 75% and become exam eligible.';
      } else {
        predictionMsg =
            'Even attending all upcoming classes may not bring you to 75%. Contact your faculty immediately.';
      }
    }

    return Container(
      decoration: BoxDecoration(color: Color(0xFF2C2C2C), const Color(0xFFFFFFFF)]
              : [const Color(0xFF7F1D1D), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (pct >= 75
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFDC2626))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Animated circular progress
              SizedBox(
                width: 88,
                height: 88,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(88, 88),
                        painter: _CircularProgressPainter(
                          progress: _progressAnim.value,
                          color: Colors.white,
                          bgColor: Colors.white24,
                          strokeWidth: 8,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(pct).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _riskLevel,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Attendance',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_attendedClasses / $_totalClasses classes attended',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    // Progress bar with 75% marker
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (_, __) => LinearProgressIndicator(
                              value: _progressAnim.value,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              minHeight: 10,
                            ),
                          ),
                        ),
                        // 75% threshold line
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.75 *
                              0.38 -
                              2,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0%',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 9)),
                        const Text('75% min',
                            style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                        Text('100%',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Prediction message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  pct >= 75
                      ? Icons.tips_and_updates_rounded
                      : Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    predictionMsg,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          if (pct < 75 && _classesNeeded > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_classesNeeded',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          'Classes To Attend',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${(75 - pct).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          'Gap to 75%',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  // ── Subject Card ───────────────────────────────────────────────────────────

  Widget _buildSubjectCard(Map<String, dynamic> subject, double pct, int index) {
    final colorMap = {
      'color': pct >= 85
          ? const Color(0xFF059669)
          : pct >= 75
              ? const Color(0xFFFFFFFF)
              : pct >= 65
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444),
      'bg': pct >= 85
          ? const Color(0xFFDCFCE7)
          : pct >= 75
              ? const Color(0xFFEFF6FF)
              : pct >= 65
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFFFE4E6),
    };
    final color = colorMap['color'] as Color;
    final bg = colorMap['bg'] as Color;
    final needed = _subjectClassesNeeded(
        subject['present'], subject['total'], subject['upcoming']);
    final canMiss =
        _subjectCanMiss(subject['present'], subject['total'], subject['upcoming']);
    final riskLabel = pct >= 85
        ? 'Safe'
        : pct >= 75
            ? 'Moderate'
            : pct >= 65
                ? 'Risky'
                : 'Critical';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pct < 75 ? color.withOpacity(0.3) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.menu_book_rounded, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFFFFFFFF))),
                    Text(subject['code'],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(riskLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${pct.round()}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniInfo('${subject['present']}/${subject['total']}', 'Attended',
                  const Color(0xFF6B7280)),
              const SizedBox(width: 12),
              _miniInfo('${subject['upcoming']}', 'Upcoming',
                  const Color(0xFFFFFFFF)),
              const Spacer(),
              if (pct < 75 && needed > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('Need $needed more',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444))),
                )
              else if (pct >= 75 && canMiss > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('Can miss $canMiss',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String value, String label, Color color) {
    return Row(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
        const SizedBox(width: 3),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ],
    );
  }

  int _subjectClassesNeeded(int present, int total, int upcoming) {
    if (total == 0) return 0;
    if (present / total * 100 >= 75) return 0;
    for (int i = 1; i <= upcoming; i++) {
      if ((present + i) / (total + i) * 100 >= 75) return i;
    }
    return upcoming;
  }

  int _subjectCanMiss(int present, int total, int upcoming) {
    int canMiss = 0;
    for (int i = 0; i <= upcoming; i++) {
      if (present / (total + i) * 100 >= 75) {
        canMiss = i;
      } else {
        break;
      }
    }
    return canMiss;
  }

  // ── AI Tips ────────────────────────────────────────────────────────────────

  Widget _buildAITips() {
    final pct = _percentage;
    final tips = <Map<String, dynamic>>[];

    if (pct < 65) {
      tips.add({
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFFE4E6),
        'text':
            '🚨 Critical zone! Attend ALL upcoming classes. Missing even one may cost you exam eligibility.',
      });
      tips.add({
        'icon': Icons.school_rounded,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFFF1F2),
        'text':
            'Contact your subject teacher and inform them of your situation. Seek academic support immediately.',
      });
    } else if (pct < 75) {
      tips.add({
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFEF3C7),
        'text':
            '⚠️ You are below 75%. Attend next $_classesNeeded classes continuously to recover your standing.',
      });
      tips.add({
        'icon': Icons.schedule_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFEF9C3),
        'text':
            'Avoid missing upcoming classes — even one absence now sets you back significantly.',
      });
    } else if (pct < 85) {
      tips.add({
        'icon': Icons.thumb_up_rounded,
        'color': const Color(0xFFFFFFFF),
        'bg': const Color(0xFFEFF6FF),
        'text':
            '👍 Good standing! You have a small buffer — stay consistent and aim for 85%+ for exam safety.',
      });
    } else {
      tips.add({
        'icon': Icons.celebration_rounded,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFDCFCE7),
        'text':
            '🎉 Excellent attendance! You have a healthy buffer. Keep maintaining this momentum.',
      });
    }

    tips.addAll([
      {
        'icon': Icons.lightbulb_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFEF3C7),
        'text':
            'Tip: Consistent attendance is better than attending in bursts. Build a daily habit.',
      },
      {
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFDCFCE7),
        'text':
            'Goal: Maintain 85%+ for a safety buffer against emergencies or illness.',
      },
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_rounded,
                  size: 16, color: Color(0xFFFFFFFF)),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI Smart Suggestions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFFFFF)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tips.asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: e.value['bg'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(e.value['icon'], size: 18, color: e.value['color']),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value['text'],
                        style: TextStyle(
                            fontSize: 12,
                            color: e.value['color'],
                            height: 1.5,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: 100 * e.key + 600))
                  .fadeIn(duration: 400.ms),
            ),
      ],
    );
  }
}

// ── Custom Circular Progress Painter ──────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  const _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress;
}
