import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../utils/ux_constants.dart';

class TeacherManualAttendanceSheet extends StatefulWidget {
  final AttendanceSession session;
  final VoidCallback onUpdate;

  const TeacherManualAttendanceSheet({
    super.key,
    required this.session,
    required this.onUpdate,
  });

  @override
  State<TeacherManualAttendanceSheet> createState() =>
      _TeacherManualAttendanceSheetState();
}

class _TeacherManualAttendanceSheetState
    extends State<TeacherManualAttendanceSheet> {
  String _searchQuery = '';
  String _filterStatus = 'All';

  List<StudentAttendanceEntry> get _filteredStudents {
    var list = widget.session.students;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filterStatus != 'All') {
      list = list.where((s) => s.status.label == _filterStatus).toList();
    }
    return list;
  }

  void _cycleStatus(StudentAttendanceEntry student) {
    setState(() {
      switch (student.status) {
        case StudentStatus.absent:
          student.status = StudentStatus.present;
          student.scanTime = DateTime.now();
          break;
        case StudentStatus.present:
          student.status = StudentStatus.late;
          break;
        case StudentStatus.late:
          student.status = StudentStatus.absent;
          student.scanTime = null;
          break;
        default:
          student.status = StudentStatus.present;
          student.scanTime = DateTime.now();
      }
    });
    widget.onUpdate();
  }

  void _showSpecialCaseDialog(StudentAttendanceEntry student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mark special case:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            _specialButton('🏅 Sports Participation', StudentStatus.sports,
                student, const Color(0xFF8B5CF6)),
            const SizedBox(height: 8),
            _specialButton('🏥 Medical Leave', StudentStatus.medical, student,
                const Color(0xFF06B6D4)),
            const SizedBox(height: 8),
            _specialButton('💼 Placement Activity', StudentStatus.placement,
                student, const Color(0xFFEC4899)),
          ],
        ),
      ),
    );
  }

  Widget _specialButton(
      String label, StudentStatus status, StudentAttendanceEntry student,
      Color color) {
    final isSelected = student.status == status;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            student.status = status;
            student.scanTime = DateTime.now();
            student.specialReason = status.label;
          });
          widget.onUpdate();
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? color.withOpacity(0.1) : null,
          side: BorderSide(
              color: isSelected ? color : const Color(0xFFE5E7EB)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? color : const Color(0xFF374151),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: UXConstants.bgLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Manual Attendance',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFFFFF))),
                      Row(
                        children: [
                          _actionChip('All Present', Icons.check_circle_rounded,
                              const Color(0xFF059669), () {
                            SessionService.markAllPresent(widget.session);
                            setState(() {});
                            widget.onUpdate();
                          }),
                          const SizedBox(width: 8),
                          _actionChip('All Absent', Icons.cancel_rounded,
                              const Color(0xFFEF4444), () {
                            SessionService.markAllAbsent(widget.session);
                            setState(() {});
                            widget.onUpdate();
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search student by name or roll...',
                      hintStyle: const TextStyle(
                          color: Color(0xFFD1D5DB), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Present', 'Absent', 'Late', 'Sports', 'Medical', 'Placement']
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(f, style: const TextStyle(fontSize: 11)),
                                  selected: _filterStatus == f,
                                  onSelected: (_) =>
                                      setState(() => _filterStatus = f),
                                  selectedColor:
                                      const Color(0xFFFFFFFF).withOpacity(0.15),
                                  labelStyle: TextStyle(
                                    color: _filterStatus == f
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: _filterStatus == f
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Student list
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: _filteredStudents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final student = _filteredStudents[i];
                  return _studentRow(student);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _studentRow(StudentAttendanceEntry student) {
    final statusColor = _getStatusColor(student.status);

    return Container(
      decoration: BoxDecoration(
        color: UXConstants.surface,
        borderRadius: UXConstants.radius12,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: UXConstants.shadowSoft,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(student.name[0],
                  style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(student.rollNumber,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),

          // Status toggle
          GestureDetector(
            onTap: () => _cycleStatus(student),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(student.status.label,
                  style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 6),

          // Special case button
          GestureDetector(
            onTap: () => _showSpecialCaseDialog(student),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  size: 16, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.present:
        return const Color(0xFF059669);
      case StudentStatus.absent:
        return const Color(0xFFEF4444);
      case StudentStatus.late:
        return const Color(0xFFF59E0B);
      case StudentStatus.sports:
        return const Color(0xFF8B5CF6);
      case StudentStatus.medical:
        return const Color(0xFF06B6D4);
      case StudentStatus.placement:
        return const Color(0xFFEC4899);
    }
  }
}
