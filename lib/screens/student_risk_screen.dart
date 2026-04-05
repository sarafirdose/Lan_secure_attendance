import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentRiskScreen extends StatelessWidget {
  const StudentRiskScreen({super.key});

  // Sample data - will connect to Firebase later
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

  double _getPercentage(int present, int total) =>
      total == 0 ? 0 : (present / total * 100);

  String _getRiskLevel(double percentage) {
    if (percentage >= 85) return 'Safe';
    if (percentage >= 75) return 'Moderate';
    if (percentage >= 65) return 'Risky';
    return 'Critical';
  }

  Color _getRiskColor(double percentage) {
    if (percentage >= 85) return const Color(0xFF059669);
    if (percentage >= 75) return const Color(0xFFFFFFFF);
    if (percentage >= 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getRiskBg(double percentage) {
    if (percentage >= 85) return const Color(0xFFDCFCE7);
    if (percentage >= 75) return const Color(0xFFEFF6FF);
    if (percentage >= 65) return const Color(0xFFFEF3C7);
    return const Color(0xFFFFE4E6);
  }

  // AI Prediction: classes needed to reach 75%
  int _classesNeeded(int present, int total, int upcoming) {
    if (total == 0) return 0;
    double current = present / total * 100;
    if (current >= 75) return 0;
    // Calculate how many of upcoming classes needed
    for (int i = 1; i <= upcoming; i++) {
      double newPct = (present + i) / (total + i) * 100;
      if (newPct >= 75) return i;
    }
    return upcoming;
  }

  // AI Prediction: max classes can miss
  int _canMiss(int present, int total, int upcoming) {
    int canMiss = 0;
    for (int i = 0; i <= upcoming; i++) {
      double newPct = present / (total + i) * 100;
      if (newPct >= 75) {
        canMiss = i;
      } else {
        break;
      }
    }
    return canMiss;
  }

  @override
  Widget build(BuildContext context) {
    // Overall stats
    int totalPresent = _subjects.fold(0, (s, e) => s + (e['present'] as int));
    int totalClasses = _subjects.fold(0, (s, e) => s + (e['total'] as int));
    double overallPct = _getPercentage(totalPresent, totalClasses);
    int criticalCount = _subjects
        .where((s) => _getPercentage(s['present'], s['total']) < 75)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context, overallPct, criticalCount),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Summary Card
                  _buildAISummary(overallPct, criticalCount),
                  const SizedBox(height: 20),

                  // Subject breakdown
                  const Text(
                    'Subject-wise Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 12),

                  ..._subjects.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final pct = _getPercentage(s['present'], s['total']);
                    return _buildSubjectCard(s, pct, i)
                        .animate(
                          delay: Duration(milliseconds: 100 * i + 300),
                        )
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.2, curve: Curves.easeOut);
                  }),

                  const SizedBox(height: 20),

                  // AI Tips
                  _buildAITips(overallPct),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, double overallPct, int criticalCount) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white60, size: 16),
                    const SizedBox(width: 4),
                    Text('Back',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13)),
                  ],
                ),
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Smart prediction & risk analysis',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Risk badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: overallPct >= 75
                          ? const Color(0xFF059669)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      overallPct >= 75 ? '✓ Safe' : '⚠ At Risk',
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

  Widget _buildAISummary(double overallPct, int criticalCount) {
    return Container(
      decoration: BoxDecoration(color: Color(0xFF2C2C2C), const Color(0xFFFFFFFF)]
              : [const Color(0xFF7F1D1D), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: overallPct / 100,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 8,
                    ),
                    Text(
                      '${overallPct.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      overallPct >= 85
                          ? '🎉 Excellent! Keep it up'
                          : overallPct >= 75
                              ? '👍 Good, stay consistent'
                              : overallPct >= 65
                                  ? '⚠️ Warning: Attend more classes'
                                  : '🚨 Critical: Immediate action needed',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (criticalCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$criticalCount subject${criticalCount > 1 ? 's' : ''} below 75%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildSubjectCard(
      Map<String, dynamic> subject, double pct, int index) {
    final color = _getRiskColor(pct);
    final bgColor = _getRiskBg(pct);
    final riskLevel = _getRiskLevel(pct);
    final needed = _classesNeeded(
        subject['present'], subject['total'], subject['upcoming']);
    final canMiss =
        _canMiss(subject['present'], subject['total'], subject['upcoming']);

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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    Text(
                      subject['code'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
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
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stats row
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Need $needed more classes',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                )
              else if (pct >= 75 && canMiss > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Can miss $canMiss classes',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
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
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildAITips(double overallPct) {
    final tips = <Map<String, dynamic>>[];

    if (overallPct < 75) {
      tips.add({
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFFE4E6),
        'text':
            'You are below 75% overall. Attend all upcoming classes to avoid detention.',
      });
    }

    tips.addAll([
      {
        'icon': Icons.lightbulb_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFEF3C7),
        'text':
            'Tip: Attend consistently rather than in bursts for better results.',
      },
      {
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFDCFCE7),
        'text': 'Goal: Maintain above 85% to have buffer for emergencies.',
      },
      {
        'icon': Icons.notifications_active_rounded,
        'color': const Color(0xFFFFFFFF),
        'bg': const Color(0xFFEFF6FF),
        'text':
            'Smart reminder: You have 2 subjects approaching 75% threshold.',
      },
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Smart Tips',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: 100 * e.key + 600))
                  .fadeIn(duration: 400.ms),
            ),
        const SizedBox(height: 20),
      ],
    );
  }
}
