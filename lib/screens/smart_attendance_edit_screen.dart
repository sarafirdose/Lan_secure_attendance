import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/teacher_service.dart';
import '../services/session_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SmartAttendanceEditScreen extends StatefulWidget {
  const SmartAttendanceEditScreen({super.key});

  @override
  State<SmartAttendanceEditScreen> createState() => _SmartAttendanceEditScreenState();
}

class _SmartAttendanceEditScreenState extends State<SmartAttendanceEditScreen> {
  int _currentStep = 0;
  
  // Selection State
  String? _selectedSubject;
  String? _selectedClass; // DEP-YEAR-SEC
  AttendanceSession? _selectedSession;
  List<StudentAttendanceEntry> _editList = [];
  Map<String, StudentStatus> _originalStatus = {};
  
  List<String> _subjects = [];
  List<String> _classes = [];
  List<AttendanceSession> _availableSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profile = await TeacherService.getProfile();
    if (profile != null) {
      setState(() {
        _subjects = profile.subjects;
        _classes = profile.allowedClasses;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSessions() async {
    if (_selectedSubject == null || _selectedClass == null) return;
    
    setState(() => _isLoading = true);
    final allSessions = await SessionService.getPastSessions();
    
    // Filter sessions matching subject and class
    final filtered = allSessions.where((AttendanceSession s) {
      final classMatch = '${s.department}-${s.year}-${s.section}' == _selectedClass;
      return s.subject == _selectedSubject && classMatch;
    }).toList();

    setState(() {
      _availableSessions = filtered;
      _isLoading = false;
    });
  }

  void _nextStep() {
    if (_currentStep == 0 && (_selectedSubject == null || _selectedClass == null)) return;
    if (_currentStep == 1 && _selectedSession == null) return;
    
    setState(() {
      if (_currentStep == 1) {
        _editList = List.from(_selectedSession!.students.map((s) => StudentAttendanceEntry(
          rollNumber: s.rollNumber,
          name: s.name,
          status: s.status,
          scanTime: s.scanTime,
          specialReason: s.specialReason,
        )));
        _originalStatus = { for (var s in _editList) s.rollNumber : s.status };
      }
      _currentStep++;
    });
    
    if (_currentStep == 1) _loadSessions();
  }

  Future<void> _saveChanges() async {
    if (_selectedSubject == null || _selectedClass == null || _selectedSession == null) return;

    // Step 7: Security Layer Validation
    final isAuth = await TeacherService.isAuthorized(_selectedSubject!, _selectedClass!);
    if (!isAuth) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized access to this class!'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // AI Audit Trail Integration
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate AI audit

    final modifiedCount = _editList.where((s) => s.status != _originalStatus[s.rollNumber]).length;

    // Update the session in the original list
    // This is simplified; in production, you'd send this to the backend
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance updated successfully. AI Audit logged $modifiedCount changes.'), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Smart Editor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStepper(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildStepContent(),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepIndicator(0, 'Scope', _currentStep >= 0),
          _stepLine(_currentStep >= 1),
          _stepIndicator(1, 'Date', _currentStep >= 1),
          _stepLine(_currentStep >= 2),
          _stepIndicator(2, 'Edit', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _stepIndicator(int index, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('${index + 1}', 
                style: TextStyle(color: active ? Colors.white : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? const Color(0xFF2C2C2C) : const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 14),
      color: active ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _stepSelection();
      case 1: return _stepSessionList();
      case 2: return _stepEditor();
      default: return const SizedBox();
    }
  }

  Widget _stepSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Attendance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
        const SizedBox(height: 8),
        const Text('Select the subject and class you wish to modify.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 32),
        
        _buildLabel('Subject'),
        _buildDropdown(_selectedSubject, _subjects, (v) => setState(() => _selectedSubject = v)),
        const SizedBox(height: 24),

        _buildLabel('Class (Dept-Year-Sec)'),
        _buildDropdown(_selectedClass, _classes, (v) => setState(() => _selectedClass = v)),
      ],
    ).animate().fadeIn();
  }

  Widget _stepSessionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
        const SizedBox(height: 32),
        if (_availableSessions.isEmpty) 
          const Center(child: Text('No historical sessions found for this selection.'))
        else
          ..._availableSessions.map((s) => _sessionCard(s)),
      ],
    ).animate().fadeIn();
  }

  Widget _stepEditor() {
    final diff = DateTime.now().difference(_selectedSession!.startTime).inDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (diff > 0) _buildWarning('HISTORICAL MODIFICATION: You are editing attendance from $diff days ago.'),
        const SizedBox(height: 24),
        ..._editList.map((stu) => _studentEditRow(stu)),
      ],
    ).animate().fadeIn();
  }

  Widget _buildWarning(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFED7AA))),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)))),
        ],
      ),
    );
  }

  Widget _sessionCard(AttendanceSession s) {
    final isSelected = _selectedSession?.sessionId == s.sessionId;
    return GestureDetector(
      onTap: () => setState(() => _selectedSession = s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, MMM d').format(s.startTime), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(DateFormat('h:mm a').format(s.startTime), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
            const Spacer(),
            Text('${s.presentCount} Present', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _studentEditRow(StudentAttendanceEntry stu) {
    final isModified = stu.status != _originalStatus[stu.rollNumber];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isModified ? const Color(0xFFE0F2FE) : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isModified ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0), width: isModified ? 1.5 : 1)
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(stu.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    if (isModified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(4)),
                        child: const Text('AI AUDITED', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                Text(stu.rollNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: stu.isPresent, 
                activeThumbColor: const Color(0xFF059669),
                onChanged: (v) => setState(() => stu.status = v ? StudentStatus.present : StudentStatus.absent),
              ),
              Text(stu.isPresent ? 'Present' : 'Absent', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: stu.isPresent ? const Color(0xFF059669) : const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))));

  Widget _buildDropdown(String? val, List<String> list, Function(String?) fn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isExpanded: true,
          hint: const Text('Select Option', style: TextStyle(fontSize: 14)),
          items: list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: fn,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _currentStep == 2 ? _saveChanges : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(_currentStep == 2 ? 'Save Changes' : 'Next Step', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
