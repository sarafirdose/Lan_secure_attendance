import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../services/analytics_ai_service.dart';
import '../models/teacher_model.dart';
import '../services/admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  List<AttendanceSession> _sessions = [];
  List<Map<String, dynamic>> _defaulters = [];
  Map<String, Map<String, dynamic>> _subjectAnalytics = {};
  final List<TeacherProfile> _teachers = [];
  
  String? _selectedSemester;
  String? _selectedSubject;
  String? _selectedTeacher;
  bool _loading = true;
  Map<String, dynamic> _adminAIInsights = {};

  final List<String> _semesters = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5', 'Sem 6', 'Sem 7', 'Sem 8'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // In a real app, TeacherService would have a getAllTeachers method
    // For now, we use a mock or fetch if available
    setState(() => _loading = true);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      // Fetch all required data with a collective timeout
      final results = await Future.wait([
        SessionService.getPastSessions(),
        SessionService.getDefaulters(subject: _selectedSubject, semester: _selectedSemester),
        SessionService.getSubjectAnalytics(semester: _selectedSemester),
        AdminService.getAdminAIInsights(),
      ]).timeout(const Duration(seconds: 6));
      
      final sessions = results[0] as List<AttendanceSession>;
      final defaulters = results[1] as List<Map<String, dynamic>>;
      final analyticRes = results[2] as Map<String, Map<String, dynamic>>;
      final aiInsights = results[3] as Map<String, dynamic>;

      // Filter logic for sessions
      var filtered = sessions;
      if (_selectedSemester != null) {
        filtered = filtered.where((AttendanceSession s) => s.semester == _selectedSemester).toList();
      }
      if (_selectedSubject != null) {
        filtered = filtered.where((AttendanceSession s) => s.subject == _selectedSubject).toList();
      }

      if (mounted) {
        setState(() {
          _sessions = filtered;
          _defaulters = defaulters;
          _subjectAnalytics = analyticRes;
          _adminAIInsights = aiInsights;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _defaulters = [];
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Working in offline/cached mode'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFFFFF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('University Analytics',
            style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C2C2C)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildOverviewCards(),
                        const SizedBox(height: 24),
                        _buildAIInsightCards(),
                        const SizedBox(height: 24),
                        _buildSubjectCharts(),
                        const SizedBox(height: 40),
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FILTERS & SCOPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6B7280), letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _filterDropdown('Semester', _selectedSemester, _semesters, (v) => setState(() { _selectedSemester = v; _loadData(); }))),
              const SizedBox(width: 12),
              Expanded(child: _filterDropdown('Subject', _selectedSubject, _subjectAnalytics.keys.toList(), (v) => setState(() { _selectedSubject = v; _loadData(); }))),
            ],
          ),
          const SizedBox(height: 12),
          _filterDropdown('Faculty Member', _selectedTeacher, ['Dr. Aris', 'Prof. Khanna', 'Dr. Sharma'], (v) => setState(() { _selectedTeacher = v; _loadData(); })),
        ],
      ),
    );
  }

  Widget _filterDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF6B7280), size: 20),
          isExpanded: true,
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13, fontWeight: FontWeight.w600),
          items: [
            const DropdownMenuItem(value: null, child: Text('All')),
            ...items.map((i) => DropdownMenuItem(value: i, child: Text(i))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final total = _adminAIInsights['total_students'] ?? 500; 
    final risk = _adminAIInsights['critical_risk_count'] ?? _defaulters.length;

    return Row(
      children: [
        Expanded(child: _statCard('Total Students', '$total', context)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('At Risk (AI)', '$risk', context, isRisk: true)),
      ],
    );
  }

  Widget _statCard(String label, String value, BuildContext context, {bool isRisk = false}) {
    final color = isRisk ? const Color(0xFFEF4444) : const Color(0xFF2C2C2C);
    final bgColor = isRisk ? const Color(0xFFFEF2F2) : const Color(0xFFEEF2FF);
    final borderColor = isRisk ? const Color(0xFFFECACA) : const Color(0xFFC7D2FE);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildAIInsightCards() {
    final insights = AnalyticsAIService.generateInsights(
      sessions: _sessions,
      studentStats: _defaulters,
      subject: _selectedSubject,
      semester: _selectedSemester,
    );
    return Column(
      children: insights.map((i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: i['isCritical'] ? const Color(0xFFFFE4E6) : const Color(0xFFFFFFFF), // Added Background
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: i['isCritical'] ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(i['isCritical'] ? Icons.priority_high_rounded : Icons.auto_awesome_rounded, color: i['isCritical'] ? Colors.red : Colors.indigo),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Text(i['message'], style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ])),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSubjectCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SUBJECT BREAKDOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6B7280), letterSpacing: 1)),
        const SizedBox(height: 12),
        ..._subjectAnalytics.entries.map((e) {
          final pct = (e.value['totalStudents'] > 0) ? (e.value['totalPresent'] / e.value['totalStudents'] * 100).round() : 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFFFFFFFF))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pct < 75 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$pct%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: pct < 75 ? const Color(0xFFDC2626) : const Color(0xFF16A34A))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8), 
                  child: LinearProgressIndicator(
                    value: pct / 100, 
                    minHeight: 12, 
                    backgroundColor: const Color(0xFFFFFFFF), 
                    valueColor: AlwaysStoppedAnimation(pct < 75 ? const Color(0xFFEF4444) : const Color(0xFF059669))
                  )
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
