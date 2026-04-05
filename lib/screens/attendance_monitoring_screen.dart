import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AttendanceMonitoringScreen extends StatefulWidget {
  const AttendanceMonitoringScreen({super.key});

  @override
  State<AttendanceMonitoringScreen> createState() => _AttendanceMonitoringScreenState();
}

class _AttendanceMonitoringScreenState extends State<AttendanceMonitoringScreen> {
  List<AttendanceSession> _allSessions = [];
  bool _isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAllSessions();
  }

  Future<void> _loadAllSessions() async {
    final s = await SessionService.getPastSessions();
    setState(() {
      _allSessions = s;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Global Attendance Monitoring', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryHeader(),
                _buildFilterStrip(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _allSessions.length,
                    itemBuilder: (context, index) => _sessionReportCard(_allSessions[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader() {
    final avg = _allSessions.isEmpty ? 0 : (_allSessions.map((s) => s.presentPercentage).reduce((a, b) => a + b) / _allSessions.length).round();
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _summaryItem('Total Sessions', '${_allSessions.length}', const Color(0xFF38BDF8)),
          const Spacer(),
          _summaryItem('Avg. Attendance', '$avg%', const Color(0xFF059669)),
          const Spacer(),
          _summaryItem('Risk Alert', 'Nominal', const Color(0xFFFB7185)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip('All'),
          _filterChip('Active'),
          _filterChip('Completed'),
          _filterChip('High Risk'),
        ],
      ),
    );
  }

  Widget _filterChip(String t) {
    final isSel = _filter == t;
    return GestureDetector(
      onTap: () => setState(() => _filter = t),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _sessionReportCard(AttendanceSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_rounded, color: Color(0xFF2C2C2C), size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('${s.department} • ${s.year} Year', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s.presentPercentage >= 75 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${s.presentPercentage}%', 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.presentPercentage >= 75 ? const Color(0xFF166534) : const Color(0xFF991B1B))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              const Text('Faculty: Dr. Teacher', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const Spacer(),
              Text(DateFormat('MMM d, h:mm a').format(s.startTime), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
