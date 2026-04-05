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
  ];

  List<Map<String, String>> get _filtered {
    var list = _allRecords;
    if (_activeFilter == 'Today') {
      list = list.where((r) => r['day'] == 'today').toList();
    } else if (_activeFilter == 'This Week') {
      list = list.where((r) => r['day'] == 'today' || r['day'] == 'week').toList();
    }
    if (_statusFilter != 'All') {
      list = list.where((r) => r['status'] == _statusFilter).toList();
    }
    return list;
  }

  Map<String, List<Map<String, String>>> get _groupedRecords {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (var record in _filtered) {
      final date = record['date']!;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlsRow(),
                  const SizedBox(height: 24),
                  _buildStatusFilterRow(),
                  const SizedBox(height: 24),
                  if (_filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ..._groupedRecords.entries.map((entry) => _buildDateGroup(entry.key, entry.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Scan History',
              style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.file_download_outlined,
                  color: Color(0xFF0056B3), size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Exporting records to PDF...')));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['All Time', 'This Week', 'Today'].map((filter) {
          final isActive = filter == (_activeFilter == 'All' ? 'All Time' : _activeFilter);
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilter = filter == 'All Time' ? 'All' : filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0056B3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF424242)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statusChip('All', const Color(0xFF0056B3)),
          const SizedBox(width: 8),
          _statusChip('Present', const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          _statusChip('Absent', const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    final isActive = _statusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? color : const Color(0xFFE5E7EB)),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'All') ...[
              Icon(label == 'Present' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 14, color: isActive ? Colors.white : color),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(String date, List<Map<String, String>> records) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000000))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: records.asMap().entries.map((entry) {
                final isLast = entry.key == records.length - 1;
                return Column(
                  children: [
                    _buildRecordRow(entry.value),
                    if (!isLast)
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFFFFFFF)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  Widget _buildRecordRow(Map<String, String> record) {
    final status = record['status']!;
    final isPresent = status == 'Present';

    final Color statusColor = isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final Color statusBg = isPresent ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);
    final String initials = record['subject']!.split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0056B3))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['subject']!,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF000000))),
                const SizedBox(height: 4),
                Text('${record['code']}  •  ${record['time']}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF424242))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFFFFFFFF)),
            ),
            const SizedBox(height: 16),
            const Text('No records found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF))),
            const SizedBox(height: 8),
            const Text('Try adjusting your filters to see more.',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
