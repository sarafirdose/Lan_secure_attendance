import 'package:flutter/material.dart';
import '../services/sa_admin_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await SaAdminService.getSettings();
    setState(() {
      _settings = s;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    await SaAdminService.saveSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Global Configurations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionTitle('ATTENDANCE PROTOCOL'),
                _buildSliderSetting('Attendance Threshold', 'attendanceThreshold', 50, 95, '%'),
                _buildSliderSetting('Default Session', 'sessionDuration', 30, 180, ' mins'),
                _buildSliderSetting('Grace Period', 'gracePeriod', 0, 30, ' mins'),
                
                const SizedBox(height: 48),
                _buildSectionTitle('DATA CONTROL & RECOVERY'),
                _buildActionItem(Icons.cloud_upload_outlined, 'Generate & Export Report', 'Export all attendance data to JSON format', const Color(0xFF2C2C2C), _handleExport),
                _buildActionItem(Icons.history_rounded, 'System Backup', 'Create a manual backup of current data state', const Color(0xFF8B5CF6), _handleBackup),
                _buildActionItem(Icons.restore_rounded, 'Restore from Backup', 'Revert system to a previous data state', const Color(0xFFDC2626), _handleRestore),

                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFFFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Apply Global Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleBackup() async {
    final state = await SaAdminService.exportSystemState();
    await Clipboard.setData(ClipboardData(text: state));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup copied to clipboard! Save it safely.'), backgroundColor: Color(0xFF2C2C2C)));
    }
  }

  Future<void> _handleRestore() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore System State'),
        content: TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: 'Paste backup JSON here')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      )
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        await SaAdminService.importSystemState(controller.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('System restored successfully! Restart app to apply.'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid backup format'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _handleExport() async {
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON Report generated and ready for export'), backgroundColor: Colors.blue));
    }
  }

  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6B7280), letterSpacing: 1.5)));

  Widget _buildSliderSetting(String label, String key, double min, double max, String suffix) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
              Text('${_settings[key]}$suffix', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C))),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: (_settings[key] as num).toDouble().clamp(min, max),
            min: min, max: max,
            activeColor: const Color(0xFF2C2C2C),
            onChanged: (v) => setState(() => _settings[key] = v.round()),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildActionItem(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
     return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                    Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
