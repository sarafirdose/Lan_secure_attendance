import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'teacher_qr_screen.dart';

class TeacherSelectClassScreen extends StatefulWidget {
  const TeacherSelectClassScreen({super.key});

  @override
  State<TeacherSelectClassScreen> createState() =>
      _TeacherSelectClassScreenState();
}

class _TeacherSelectClassScreenState extends State<TeacherSelectClassScreen> {
  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedSection;
  String? _selectedSubject;

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Electronics & Comm.',
    'Electrical Engineering',
    'Mechanical Engineering',
  ];

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  final List<String> _sections = ['A', 'B', 'C', 'D'];

  final List<String> _subjects = [
    'Data Structures',
    'Computer Networks',
    'Operating Systems',
    'Database Management',
    'Software Engineering',
    'Machine Learning',
    'Web Development',
  ];

  bool get _canStart =>
      _selectedDepartment != null &&
      _selectedYear != null &&
      _selectedSection != null &&
      _selectedSubject != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: Color(0xFFFFFFFF)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Select class details to generate attendance QR code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDropdown(
                          label: 'Department',
                          hint: 'Select Department',
                          icon: Icons.school_outlined,
                          value: _selectedDepartment,
                          items: _departments,
                          onChanged: (v) =>
                              setState(() => _selectedDepartment = v),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDropdown(
                                label: 'Year',
                                hint: 'Select Year',
                                icon: Icons.calendar_today_outlined,
                                value: _selectedYear,
                                items: _years,
                                onChanged: (v) =>
                                    setState(() => _selectedYear = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                label: 'Section',
                                hint: 'Sec',
                                icon: Icons.group_outlined,
                                value: _selectedSection,
                                items: _sections,
                                onChanged: (v) =>
                                    setState(() => _selectedSection = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Subject',
                          hint: 'Select Subject',
                          icon: Icons.menu_book_rounded,
                          value: _selectedSubject,
                          items: _subjects,
                          onChanged: (v) =>
                              setState(() => _selectedSubject = v),
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 20),

                  // Session preview
                  if (_canStart)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF059669), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Session Ready',
                                style: TextStyle(
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '📚 $_selectedSubject\n'
                            '🏫 $_selectedDepartment — $_selectedYear — Section $_selectedSection',
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              const Text('Select Class',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Choose department, year, section & subject',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF9CA3AF)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
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
              borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _canStart
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherQRScreen(
                        department: _selectedDepartment!,
                        year: _selectedYear!,
                        section: _selectedSection!,
                        subject: _selectedSubject!,
                      ),
                    ),
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF),
            disabledBackgroundColor: const Color(0xFF9CA3AF),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 22),
              SizedBox(width: 8),
              Text('Start Attendance Session',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
