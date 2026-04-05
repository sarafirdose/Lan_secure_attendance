import 'package:flutter/material.dart';
import '../services/sa_admin_service.dart';
import '../services/admin_service.dart';
import '../services/audit_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentManagementScreen extends StatefulWidget {
  final bool openAddDialog;
  const StudentManagementScreen({super.key, this.openAddDialog = false});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Map<String, String>> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bulkUpload();
      });
    }
  }

  Future<void> _loadStudents() async {
    final s = await SaAdminService.getStudents();
    setState(() {
      _students = s;
      _isLoading = false;
    });
  }

  Future<void> _bulkUpload() async {
    final TextEditingController csvController = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Student Upload', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Paste CSV data in format: Name,ID,Dept,Year,Sec', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            TextField(
              controller: csvController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'John Doe,CS001,CS,2,A\nJane Smith,CS002,CS,2,A',
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Parse Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ).then((confirmed) async {
       if (confirmed == true && csvController.text.isNotEmpty) {
         final lines = csvController.text.split('\n');
         final List<Map<String, String>> newStudents = [];
         for (final line in lines) {
           final parts = line.split(',');
           if (parts.length >= 5) {
             newStudents.add({
               'name': parts[0].trim(),
               'id': parts[1].trim(),
               'dept': parts[2].trim(),
               'year': parts[3].trim(),
               'sec': parts[4].trim(),
             });
           }
         }
         await SaAdminService.bulkUploadStudents(newStudents);
         _loadStudents();
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) => 
      s['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      s['id']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Student Directory', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: const Text('Bulk Upload'),
            onPressed: _bulkUpload,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 8),
        ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _studentCard(filtered[index]),
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
          hintText: 'Search by Name or Student ID...',
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
          Icon(Icons.group_outlined, size: 64, color: Colors.grey[350]),
          const SizedBox(height: 16),
          const Text('No students found in global directory.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _studentCard(Map<String, String> s) {
    final roll = s['id'] ?? '';
    final name = s['name'] ?? '';
    final isBlocked = s['isBlocked'] == 'true';
    final hasFingerprint = s['deviceId'] != null && s['deviceId']!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBlocked ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB)),
        boxShadow: isBlocked ? [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10)] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isBlocked ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.person_rounded, color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF6B7280), size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isBlocked ? const Color(0xFFB91C1C) : const Color(0xFFFFFFFF))),
                        if (isBlocked) ...[
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(4)), child: const Text('BLOCKED', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w900))),
                         ],
                      ],
                    ),
                    Text('$roll  •  ${s['dept']} - ${s['year']} Year (${s['sec']})', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  isBlocked ? 'Unblock' : 'Block Student', 
                  isBlocked ? const Color(0xFF059669) : const Color(0xFFEF4444), 
                  () => _toggleBlock(roll, !isBlocked),
                  isBlocked ? Icons.check_circle_rounded : Icons.block_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'Reset Device', 
                  const Color(0xFF2C2C2C), 
                  () => _handleResetFingerprint(roll),
                  Icons.phonelink_erase_rounded,
                  isDisabled: !hasFingerprint,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideX(begin: 0.1).fadeIn();
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap, IconData icon, {bool isDisabled = false}) {
     return SizedBox(
       height: 36,
       child: OutlinedButton.icon(
          onPressed: isDisabled ? null : onTap,
          icon: Icon(icon, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
             foregroundColor: color,
             side: BorderSide(color: color.withOpacity(isDisabled ? 0.1 : 0.3)),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             backgroundColor: isDisabled ? Colors.grey[50] : color.withOpacity(0.05),
          ),
       ),
     );
  }

  Future<void> _toggleBlock(String roll, bool block) async {
     await AdminService.toggleBlockStudent(roll, block);
     await SaAdminService.toggleBlockStudent(roll, block); // UI Sync wrapper
     await AuditService.logAction(action: block ? 'SECURITY_BLOCK' : 'SECURITY_UNBLOCK', description: 'Student $roll permissions modified natively by Admin');
     _loadStudents();
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(block ? '$roll Blocked' : '$roll Unblocked'), backgroundColor: block ? Colors.red : Colors.green));
  }

  Future<void> _handleResetFingerprint(String roll) async {
      await SaAdminService.resetDeviceFingerprint(roll); // Keeps UI sync valid
      await AuditService.logAction(action: 'DEVICE_CHANGE', description: 'Enforced Device Fingerprint Drop for Roll: $roll natively');
      _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device binding reset successful ✓'), backgroundColor: Colors.indigo));
  }
}
