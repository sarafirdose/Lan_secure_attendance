import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../services/teacher_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TimetableManagerScreen extends StatefulWidget {
  const TimetableManagerScreen({super.key});

  @override
  State<TimetableManagerScreen> createState() => _TimetableManagerScreenState();
}

class _TimetableManagerScreenState extends State<TimetableManagerScreen> {
  List<TimetableEntry> _timetable = [];
  bool _isLoading = true;
  String _selectedDay = 'Monday';

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final t = await TeacherService.getTimetable();
    setState(() {
      _timetable = t;
      _isLoading = false;
    });
  }

  Future<void> _addEntry() async {
    final profile = await TeacherService.getProfile();
    if (profile == null) return;

    if (!mounted) return;

    TimeOfDay? start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? end = const TimeOfDay(hour: 10, minute: 0);
    String subject = profile.subjects.first;
    String section = profile.sections.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Class Slot', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
              const SizedBox(height: 24),
              
              const Text('Subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              DropdownButton<String>(
                value: subject,
                isExpanded: true,
                items: profile.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setModalState(() => subject = v!),
              ),
              const SizedBox(height: 16),

              const Text('Section', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              DropdownButton<String>(
                value: section,
                isExpanded: true,
                items: profile.sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setModalState(() => section = v!),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: start!);
                            if (picked != null) setModalState(() => start = picked);
                          },
                          child: Text(start!.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: end!);
                            if (picked != null) setModalState(() => end = picked);
                          },
                          child: Text(end!.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Add to Schedule', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _saveEntry(subject, section, start!, end!, profile);
      }
    });
  }

  void _saveEntry(String sub, String sec, TimeOfDay start, TimeOfDay end, TeacherProfile profile) async {
    final startTimeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    // Overlap check
    final hasOverlap = _timetable.any((e) => 
      e.day == _selectedDay && 
      ((startTimeStr.compareTo(e.startTime) >= 0 && startTimeStr.compareTo(e.endTime) < 0) ||
       (endTimeStr.compareTo(e.startTime) > 0 && endTimeStr.compareTo(e.endTime) <= 0)));

    if (hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot overlaps with an existing class!'), backgroundColor: Colors.red),
      );
      return;
    }

    final newEntry = TimetableEntry(
      entryId: DateTime.now().millisecondsSinceEpoch.toString(),
      day: _selectedDay,
      startTime: startTimeStr,
      endTime: endTimeStr,
      subject: sub,
      department: profile.department,
      year: profile.year,
      section: sec,
      semester: profile.semester,
    );

    setState(() {
      _timetable.add(newEntry);
      _timetable.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    await TeacherService.saveTimetable(_timetable);
    await TeacherService.syncNotificationReminders();
  }

  Future<void> _editEntry(TimetableEntry entry) async {
    final profile = await TeacherService.getProfile();
    if (profile == null) return;
    if (!mounted) return;

    final startParts = entry.startTime.split(':');
    final endParts = entry.endTime.split(':');
    
    TimeOfDay start = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    TimeOfDay end = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    String subject = entry.subject;
    String section = entry.section;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update Class Slot', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
                const SizedBox(height: 24),
                
                const Text('Subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                DropdownButton<String>(
                  value: subject,
                  isExpanded: true,
                  items: profile.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => subject = v!),
                ),
                const SizedBox(height: 16),
  
                const Text('Section', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                DropdownButton<String>(
                  value: section,
                  isExpanded: true,
                  items: profile.sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => section = v!),
                ),
                const SizedBox(height: 16),
  
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                          TextButton(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: start);
                              if (picked != null) setModalState(() => start = picked);
                            },
                            child: Text(start.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                          TextButton(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: end);
                              if (picked != null) setModalState(() => end = picked);
                            },
                            child: Text(end.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
  
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Update Schedule', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _updateEntry(entry.entryId, subject, section, start, end, profile);
      }
    });
  }

  void _updateEntry(String id, String sub, String sec, TimeOfDay start, TimeOfDay end, TeacherProfile profile) async {
    final startTimeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    final index = _timetable.indexWhere((e) => e.entryId == id);
    if (index == -1) return;

    final updatedEntry = TimetableEntry(
      entryId: id,
      day: _selectedDay,
      startTime: startTimeStr,
      endTime: endTimeStr,
      subject: sub,
      department: profile.department,
      year: profile.year,
      section: sec,
      semester: profile.semester,
    );

    setState(() {
      _timetable[index] = updatedEntry;
      _timetable.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    await TeacherService.saveTimetable(_timetable);
    await TeacherService.syncNotificationReminders();
  }

  void _deleteEntry(String id) async {
    setState(() {
      _timetable.removeWhere((e) => e.entryId == id);
    });
    await TeacherService.saveTimetable(_timetable);
    await TeacherService.syncNotificationReminders();
  }

  @override
  Widget build(BuildContext context) {
    final dayClasses = _timetable.where((e) => e.day == _selectedDay).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Weekly Timetable', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: const Color(0xFF2C2C2C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final isSelected = day == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(day, 
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF6B7280),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : dayClasses.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: dayClasses.length,
                        itemBuilder: (context, index) => _buildEntryCard(dayClasses[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No classes scheduled for $_selectedDay', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildEntryCard(TimetableEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF2C2C2C), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                const SizedBox(height: 4),
                Text('${entry.startTime} - ${entry.endTime}  •  Section ${entry.section}', 
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2C2C2C), size: 20),
            onPressed: () => _editEntry(entry),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            onPressed: () => _deleteEntry(entry.entryId),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.1).fadeIn();
  }
}
