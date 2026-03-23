import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _activeFilter = 'All';
  String _statusFilter = 'All';

  final List<Map<String, String>> _allRecords = const [
    {
      'subject': 'NLP',
      'code': 'E-IV',
      'date': 'Wed, Mar 18, 2026',
      'time': '10:00 AM',
      'status': 'Present',
      'day': 'today'
    },
    {
      'subject': 'Internet of Things',
      'code': 'IoT',
      'date': 'Wed, Mar 18, 2026',
      'time': '11:00 AM',
      'status': 'Present',
      'day': 'today'
    },
    {
      'subject': 'Big Data Analytics',
      'code': 'BDA',
      'date': 'Tue, Mar 17, 2026',
      'time': '12:15 PM',
      'status': 'Present',
      'day': 'week'
    },
    {
      'subject': 'Full Stack Cloud Dev',
      'code': 'FCD',
      'date': 'Mon, Mar 16, 2026',
      'time': '02:15 PM',
      'status': 'Present',
      'day': 'week'
    },
    {
      'subject': 'Deep Learning',
      'code': 'E-III',
      'date': 'Mon, Mar 16, 2026',
      'time': '04:15 PM',
      'status': 'Absent',
      'day': 'week'
    },
    {
      'subject': 'App Dev (SS)',
      'code': 'AppDev',
      'date': 'Fri, Mar 14, 2026',
      'time': '02:15 PM',
      'status': 'Present',
      'day': 'week'
    },
    {
      'subject': 'NLP',
      'code': 'E-IV',
      'date': 'Thu, Mar 13, 2026',
      'time': '10:00 AM',
      'status': 'Absent',
      'day': 'all'
    },
    {
      'subject': 'BDA Lab',
      'code': 'BDA',
      'date': 'Tue, Mar 11, 2026',
      'time': '02:15 PM',
      'status': 'Present',
      'day': 'all'
    },
    {
      'subject': 'FCD Lab',
      'code': 'FCD',
      'date': 'Thu, Mar 12, 2026',
      'time': '12:15 PM',
      'status': 'Present',
      'day': 'all'
    },
    {
      'subject': 'Deep Learning',
      'code': 'E-III',
      'date': 'Fri, Mar 07, 2026',
      'time': '10:00 AM',
      'status': 'Absent',
      'day': 'all'
    },
  ];

  List<Map<String, String>> get _filtered {
    var list = _allRecords;
    // Time filter
    if (_activeFilter == 'Today') {
      list = list.where((r) => r['day'] == 'today').toList();
    } else if (_activeFilter == 'This Week') {
      list =
          list.where((r) => r['day'] == 'today' || r['day'] == 'week').toList();
    }
    // Status filter
    if (_statusFilter != 'All') {
      list = list.where((r) => r['status'] == _statusFilter).toList();
    }
    return list;
  }

  int _countStatus(String status) =>
      _allRecords.where((r) => r['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    final records = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: records.isEmpty && _activeFilter != 'All'
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      _buildTimeFilterRow(),
                      const SizedBox(height: 10),
                      _buildStatusFilterRow(),
                      const SizedBox(height: 16),
                      _buildSectionHeader(records),
                      const SizedBox(height: 10),
                      if (records.isEmpty)
                        _buildEmptyState()
                      else
                        ...records.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildRecordCard(e.value)
                                    .animate(
                                        delay:
                                            Duration(milliseconds: 50 * e.key))
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: 0.1, curve: Curves.easeOut),
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2347D4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scan History',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5))
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 4),
                    Text('Every QR attendance scan logged here',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13))
                        .animate(delay: 100.ms)
                        .fadeIn(),
                  ],
                )),
                // Total badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.history_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text('${_allRecords.length} scans',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary cards ────────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Row(children: [
      _summaryCard(
          '${_countStatus('Present')}',
          'Present',
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
          Icons.check_circle_rounded),
      const SizedBox(width: 8),
      _summaryCard(
          '${_countStatus('Absent')}',
          'Absent',
          const Color(0xFFDC2626),
          const Color(0xFFFFE4E6),
          Icons.cancel_rounded),
    ]);
  }

  Widget _summaryCard(
      String count, String label, Color color, Color bg, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(
            () => _statusFilter = _statusFilter == label ? 'All' : label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: _statusFilter == label ? color : bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _statusFilter == label ? color : color.withValues(alpha: 0.2),
              width: _statusFilter == label ? 2 : 1,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                size: 22, color: _statusFilter == label ? Colors.white : color),
            const SizedBox(height: 6),
            Text(count,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _statusFilter == label ? Colors.white : color)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusFilter == label
                        ? Colors.white.withValues(alpha: 0.85)
                        : color)),
          ]),
        ),
      ),
    );
  }

  // ── Time filter row ──────────────────────────────────────────────────────────
  Widget _buildTimeFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'Today', 'This Week']
            .map(
              (label) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _activeFilter = label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: _activeFilter == label
                          ? const Color(0xFF2347D4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _activeFilter == label
                            ? const Color(0xFF2347D4)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _activeFilter == label
                                ? Colors.white
                                : const Color(0xFF6B7280))),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Status filter row ────────────────────────────────────────────────────────
  Widget _buildStatusFilterRow() {
    final statuses = ['All', 'Present', 'Absent'];
    final colors = {
      'All': const Color(0xFF2347D4),
      'Present': const Color(0xFF16A34A),
      'Late': const Color(0xFFD97706),
      'Absent': const Color(0xFFDC2626),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final active = _statusFilter == s;
          final color = colors[s]!;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? color : const Color(0xFFE5E7EB)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (s != 'All') ...[
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                  ],
                  Text(s,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? color : const Color(0xFF6B7280))),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────────
  Widget _buildSectionHeader(List<Map<String, String>> records) {
    String label;
    if (_activeFilter == 'Today')
      label = 'Today';
    else if (_activeFilter == 'This Week')
      label = 'This week';
    else
      label = 'All records';

    return Row(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F1729))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2347D4).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${records.length}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2347D4))),
      ),
    ]);
  }

  // ── Record card ──────────────────────────────────────────────────────────────
  Widget _buildRecordCard(Map<String, String> record) {
    final status = record['status']!;
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    Color accentBar;

    switch (status) {
      case 'Present':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = Icons.check_circle_rounded;
        accentBar = const Color(0xFF16A34A);
        break;
      case 'Late':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.access_time_rounded;
        accentBar = const Color(0xFFD97706);
        break;
      default:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFFE4E6);
        statusIcon = Icons.cancel_rounded;
        accentBar = const Color(0xFFDC2626);
    }

    // Subject initials
    final words = record['subject']!.split(' ');
    final initials = words.take(2).map((w) => w[0]).join().toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(width: 4, color: accentBar),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Subject icon with initials
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2347D4).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(initials,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2347D4))),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Details — Expanded prevents overflow
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(record['subject']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF0F1729))),
                          const SizedBox(height: 2),
                          Text(record['code']!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2347D4),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 10, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${record['date']}  ·  ${record['time']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status badge — fixed width prevents layout issues
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 3),
                        Text(status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2347D4).withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                size: 36, color: Color(0xFF2347D4)),
          ),
          const SizedBox(height: 16),
          Text(
            _statusFilter != 'All'
                ? 'No $_statusFilter records found'
                : 'No scans yet',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F1729)),
          ),
          const SizedBox(height: 6),
          Text(
            _statusFilter != 'All'
                ? 'Try changing the status filter above'
                : 'Your QR attendance scans will appear here',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }
}
