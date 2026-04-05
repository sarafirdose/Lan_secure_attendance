import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../services/teacher_service.dart';
import '../services/auth_service.dart';
import '../services/app_state_service.dart';
import 'teacher_dashboard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherProfileSetupScreen extends StatefulWidget {
  final bool isEdit;
  const TeacherProfileSetupScreen({super.key, this.isEdit = false});

  @override
  State<TeacherProfileSetupScreen> createState() => _TeacherProfileSetupScreenState();
}

class _TeacherProfileSetupScreenState extends State<TeacherProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _department = 'Computer Science';
  String _year = '2nd Year';
  String _semester = '4th Sem';
  List<String> _selectedSubjects = [];
  List<String> _selectedSections = [];
  String _name = '';
  String _teacherId = '';

  final List<String> _departments = ['Computer Science', 'Electrical Eng', 'Mechanical Eng', 'Information Tech'];
  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _semesters = ['1st Sem', '2nd Sem', '3rd Sem', '4th Sem', '5th Sem', '6th Sem', '7th Sem', '8th Sem'];
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  final List<String> _subjects = ['DBMS', 'Operating Systems', 'Software Eng', 'Computer Networks', 'Discrete Math', 'Cyber Security', 'Web Tech', 'AI & ML'];

  @override
  void initState() {
    super.initState();
    _loadInitialIdentity();
    if (widget.isEdit) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadInitialIdentity() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _name = user['name'] ?? '';
        _teacherId = user['id'] ?? '';
      });
    }
  }

  Future<void> _loadExistingProfile() async {
    final profile = await TeacherService.getProfile();
    if (profile != null) {
      setState(() {
        _department = profile.department;
        _year = profile.year;
        _semester = profile.semester;
        _selectedSubjects = List.from(profile.subjects);
        _selectedSections = List.from(profile.sections);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedSubjects.isEmpty || _selectedSections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one subject and section'), backgroundColor: Colors.red),
      );
      return;
    }

    final deviceId = await TeacherService.generateDeviceId();
    final profile = TeacherProfile(
      name: _name,
      teacherId: _teacherId,
      department: _department,
      subjects: _selectedSubjects,
      year: _year,
      semester: _semester,
      sections: _selectedSections,
      email: '', 
      deviceId: deviceId,
      updatedAt: DateTime.now(),
    );

    await TeacherService.saveProfile(profile);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Teacher Profile' : 'Setup Faculty Profile',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personalize Your Dashboard', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
              const SizedBox(height: 8),
              const Text('Select your assigned subjects and classes for smart automation.', 
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 32),

              _buildDropdown('Department', _department, _departments, (v) => setState(() => _department = v!)),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildDropdown('Year', _year, _years, (v) => setState(() => _year = v!))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('Semester', _semester, _semesters, (v) => setState(() => _semester = v!))),
                ],
              ),
              const SizedBox(height: 32),

              _buildMultiSelect('Assigned Subjects', _subjects, _selectedSubjects, (v) {
                setState(() {
                  if (_selectedSubjects.contains(v)) {
                    _selectedSubjects.remove(v);
                  } else {
                    _selectedSubjects.add(v);
                  }
                });
              }),
              const SizedBox(height: 32),

              _buildMultiSelect('Assigned Sections', _sections, _selectedSections, (v) {
                setState(() {
                  if (_selectedSections.contains(v)) {
                    _selectedSections.remove(v);
                  } else {
                    _selectedSections.add(v);
                  }
                });
              }),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Complete Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('You can update this anytime in the Profile tab.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelect(String label, List<String> items, List<String> selected, Function(String) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) {
            final isSelected = selected.contains(e);
            return GestureDetector(
              onTap: () => onToggle(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  e,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
