import 'package:flutter/material.dart';
import '../services/sa_admin_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ClassStructureScreen extends StatefulWidget {
  const ClassStructureScreen({super.key});

  @override
  State<ClassStructureScreen> createState() => _ClassStructureScreenState();
}

class _ClassStructureScreenState extends State<ClassStructureScreen> {
  Map<String, dynamic> _structure = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  Future<void> _loadStructure() async {
    final s = await SaAdminService.getStructure();
    setState(() {
      _structure = s;
      _isLoading = false;
    });
  }

  Future<void> _addEntity(String key, String title) async {
    final TextEditingController cont = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New $title'),
        content: TextField(controller: cont, decoration: const InputDecoration(hintText: 'e.g. Mechanical Eng')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && cont.text.isNotEmpty) {
        setState(() {
          _structure[key].add(cont.text.trim());
        });
        await SaAdminService.saveStructure(_structure);
      }
    });
  }

  Future<void> _removeEntity(String key, int index) async {
    setState(() {
      _structure[key].removeAt(index);
    });
    await SaAdminService.saveStructure(_structure);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('University Structure', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSection('Departments', 'departments', Icons.business_rounded, const Color(0xFF2C2C2C)),
                const SizedBox(height: 32),
                _buildSection('Year Levels', 'years', Icons.layers_rounded, const Color(0xFF7C3AED)),
                const SizedBox(height: 32),
                _buildSection('Sections', 'sections', Icons.grid_view_rounded, const Color(0xFF2563EB)),
              ],
            ),
    );
  }

  Widget _buildSection(String title, String key, IconData icon, Color color) {
    final List<String> items = List<String>.from(_structure[key]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
              ],
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: color),
              onPressed: () => _addEntity(key, title.substring(0, title.length - 1)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFFFFFFFF),
                side: BorderSide.none,
                deleteIcon: const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFF6B7280)),
                onDeleted: () => _removeEntity(key, entry.key),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}
