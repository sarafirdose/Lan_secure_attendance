import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../services/sa_admin_service.dart';
import '../services/onboarding_ai_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherManagementScreen extends StatefulWidget {
  final bool openAddDialog;
  const TeacherManagementScreen({super.key, this.openAddDialog = false});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  List<TeacherProfile> _teachers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addOrEditTeacher();
      });
    }
  }

  Future<void> _loadTeachers() async {
    final t = await SaAdminService.getTeachers();
    setState(() {
      _teachers = t;
      _isLoading = false;
    });
  }

  Future<void> _addOrEditTeacher([TeacherProfile? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final idCtrl = TextEditingController(text: existing?.teacherId ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final passCtrl = TextEditingController(); // Always empty for security

    String department = existing?.department ?? 'Computer Science';
    String year = existing?.year ?? '2nd Year';
    List<String> subjects = existing != null ? List.from(existing.subjects) : [];
    List<String> sections = existing != null ? List.from(existing.sections) : [];
    
    List<Map<String, dynamic>> aiSubSuggestions = [];
    Map<String, dynamic>? duplicateWarning;
    bool isAiLoading = false;
    bool isPassVisible = false;

    final structure = await SaAdminService.getStructure();
    final List<String> allDepts = List<String>.from(structure['departments'] ?? ['Computer Science', 'Electronic Eng', 'Mathematics', 'Information Tech']);
    final List<String> allYears = List<String>.from(structure['years'] ?? ['1st', '2nd', '3rd', '4th']);
    final List<String> allSecs = List<String>.from(structure['sections'] ?? ['A', 'B', 'C']);
    final List<String> allSubs = ['DBMS', 'OS', 'SE', 'Networks', 'AI', 'ML', 'Cyber', 'Web'];

    if (!allDepts.contains(department)) department = allDepts.first;
    if (!allYears.contains(year)) year = allYears.first;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // AI Helper
          void handleGenerateCredentials() async {
            setModalState(() => isAiLoading = true);
            final newId = await OnboardingAIService.generateTeacherId(department);
            final newPass = OnboardingAIService.generatePassword();
            final newEmail = OnboardingAIService.suggestEmail(nameCtrl.text);
            
            setModalState(() {
              idCtrl.text = newId;
              passCtrl.text = newPass;
              if (emailCtrl.text.isEmpty) emailCtrl.text = newEmail;
              isAiLoading = false;
            });
          }

          void updateAIStats() async {
             final suggestions = await OnboardingAIService.suggestSubjects(department);
             final duplicate = await OnboardingAIService.detectDuplicate(nameCtrl.text, department, emailCtrl.text);
             setModalState(() {
               aiSubSuggestions = suggestions;
               duplicateWarning = duplicate;
             });
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Register New Faculty' : 'Edit Faculty Member', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),

                _buildLabel('Full Name'),
                TextField(
                  controller: nameCtrl,
                  onChanged: (v) => updateAIStats(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Dr. Jane Smith', 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: duplicateWarning != null ? const Icon(Icons.warning_amber_rounded, color: Colors.orange) : null,
                  ),
                ),
                if (duplicateWarning != null) 
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text('AI Alert: ${duplicateWarning!['type']} match detected', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                _buildLabel('Department'),
                DropdownButton<String>(
                  value: department,
                  isExpanded: true,
                  items: allDepts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) {
                    setModalState(() => department = v!);
                    updateAIStats();
                  },
                ),
                const SizedBox(height: 16),

                if (aiSubSuggestions.isNotEmpty) ...[
                  Row(
                    children: [
                       const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF2C2C2C)),
                       const SizedBox(width: 4),
                       _buildLabel('AI Suggested Subjects (Load Balanced)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: aiSubSuggestions.map((s) {
                      final name = s['subject'];
                      final isSel = subjects.contains(name);
                      final score = (s['score'] * 100).toInt();
                      return ActionChip(
                        avatar: Text('$score%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
                        label: Text(name, style: const TextStyle(fontSize: 11)),
                        backgroundColor: isSel ? const Color(0xFFEEF2FF) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), 
                          side: BorderSide(color: isSel ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0))
                        ),
                        onPressed: () => setModalState(() => isSel ? subjects.remove(name) : subjects.add(name)),
                        tooltip: s['reason'],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildLabel('Manual Subject Control'),
                Wrap(
                  spacing: 8,
                  children: allSubs.map((s) {
                    final isSel = subjects.contains(s);
                    return FilterChip(
                      label: Text(s, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: const Color(0xFF2C2C2C),
                      onSelected: (v) => setModalState(() => v ? subjects.add(s) : subjects.remove(s)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _buildLabel('Year Level'),
                DropdownButton<String>(
                  value: year,
                  isExpanded: true,
                  items: allYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setModalState(() => year = v!),
                ),
                const SizedBox(height: 16),

                _buildLabel('Assigned Sections'),
                Wrap(
                  spacing: 8,
                  children: allSecs.map((s) {
                    final isSel = sections.contains(s);
                    return FilterChip(
                      label: Text(s, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: const Color(0xFF059669),
                      onSelected: (v) => setModalState(() => v ? sections.add(s) : sections.remove(s)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: handleGenerateCredentials,
                    icon: isAiLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.vpn_key_rounded, size: 18),
                    label: const Text('Generate ID & Password', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel('Professional Email'),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(hintText: 'e.g. j.smith@college.edu', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),

                _buildLabel('Teacher ID (Unique)'),
                TextField(
                  controller: idCtrl,
                  enabled: existing == null,
                  decoration: InputDecoration(
                    hintText: 'e.g. TCH-CS-2026-001', 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                         Clipboard.setData(ClipboardData(text: idCtrl.text));
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Copied')));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (existing == null) ...[
                  _buildLabel('Generated Password'),
                  TextField(
                    controller: passCtrl,
                    obscureText: !isPassVisible,
                    decoration: InputDecoration(
                      hintText: 'Xy@45kLm', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isPassVisible ? Icons.visibility_off : Icons.visibility, size: 18),
                            onPressed: () => setModalState(() => isPassVisible = !isPassVisible),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            onPressed: () => setModalState(() => passCtrl.text = OnboardingAIService.generatePassword()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () {
                               Clipboard.setData(ClipboardData(text: passCtrl.text));
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Copied')));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Faculty Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    ),
  ).then((confirmed) async {
      if (confirmed == true && nameCtrl.text.isNotEmpty && idCtrl.text.isNotEmpty) {
        final teacher = TeacherProfile(
          name: nameCtrl.text.trim(),
          teacherId: idCtrl.text.trim().toUpperCase(),
          email: emailCtrl.text.trim(),
          department: department,
          subjects: subjects,
          year: year,
          semester: '1st',
          sections: sections,
          deviceId: existing?.deviceId ?? '',
          updatedAt: DateTime.now(),
        );
        
        await SaAdminService.saveTeacher(teacher, password: passCtrl.text.isNotEmpty ? passCtrl.text : null);
        _loadTeachers();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty Saved Successfully'), backgroundColor: Colors.green));
        }
      }
    });
  }

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))));

  @override
  Widget build(BuildContext context) {
    final filtered = _teachers.where((t) => 
      t.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      t.teacherId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      t.department.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Faculty Management', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTeacher(),
        backgroundColor: const Color(0xFFFFFFFF),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _teacherCard(filtered[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Name, ID, or Dept...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No faculty members found.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _teacherCard(TeacherProfile t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2C2C2C).withOpacity(0.1),
            child: const Icon(Icons.person_rounded, color: Color(0xFF2C2C2C)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name.isEmpty ? 'Unknown Faculty' : t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('${t.teacherId} • ${t.department}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C))),
                Text('${t.subjects.length} Subjects • ${t.sections.length} Classes', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6B7280)), onPressed: () => _addOrEditTeacher(t)),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => SaAdminService.deleteTeacher(t.deviceId).then((_) => _loadTeachers()),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
