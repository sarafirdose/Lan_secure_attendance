import 'package:flutter/material.dart';
import '../services/fraud_detection_service.dart';
import '../services/sa_admin_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FraudMonitoringScreen extends StatefulWidget {
  const FraudMonitoringScreen({super.key});

  @override
  State<FraudMonitoringScreen> createState() => _FraudMonitoringScreenState();
}

class _FraudMonitoringScreenState extends State<FraudMonitoringScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  bool _autoBlock = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final a = await SaAdminService.getLatestFraudAlerts();
    setState(() {
      _alerts = a;
      _isLoading = false;
    });
  }

  Future<void> _handleDismiss(String id) async {
    setState(() => _alerts.removeWhere((a) => a['id'] == id));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert dismissed')));
  }

  Future<void> _handleTakeAction(Map<String, dynamic> a) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Action for ${a['stu']}'),
        content: Text('Select a security measure to counter the detected anomaly: ${a['type']}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'block'), child: const Text('Block Student', style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(context, 'reset'), child: const Text('Reset Device ID')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      )
    );

    if (result == 'block') {
      await SaAdminService.toggleBlockStudent(a['roll'], true);
      _handleDismiss(a['id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${a['stu']} has been blocked')));
    } else if (result == 'reset') {
      await SaAdminService.resetDeviceFingerprint(a['roll']);
      _handleDismiss(a['id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device fingerprint reset for ${a['stu']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Fraud Intelligence Hub', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        actions: [
          Row(
            children: [
              const Text('AI PROTECT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF6B7280))),
              Switch(
                value: _autoBlock, 
                activeColor: const Color(0xFF059669),
                onChanged: (v) => setState(() => _autoBlock = v),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlobalRiskCard(),
                  const SizedBox(height: 32),
                  const Text('RECENT SUSPICIOUS ACTIVITY', 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6B7280), letterSpacing: 1)),
                  const SizedBox(height: 16),
                  if (_alerts.isEmpty) 
                    const Center(child: Text('No active threats detected', style: TextStyle(color: Color(0xFF94A3B8)))),
                  ..._alerts.map((a) => _fraudAlertCard(a)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildGlobalRiskCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF059669), size: 18),
              const SizedBox(width: 12),
              const Text('SYSTEM INTEGRITY SCORE', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
              const Spacer(),
              Text('${100 - (FraudDetectionService.activeCount * 2).clamp(0, 10)}%', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(value: 0.95, color: Color(0xFF059669), backgroundColor: Colors.white12),
          const SizedBox(height: 16),
          const Text('Anomaly detection engine active across 3 active sessions.', 
              style: TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _fraudAlertCard(Map<String, dynamic> a) {
    Color col = a['severity'] == 'High' ? const Color(0xFFEF4444) : (a['severity'] == 'Medium' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.warning_amber_rounded, size: 20, color: col),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['type'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFFFFFFF))),
                    Text('${a['stu']} (${a['dept']} Dept) • ${a['time']}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                           _anomalyTag(Icons.wifi_tethering_rounded, 'Subnet: ${a['ip'] ?? "192.168.x"}'),
                           const SizedBox(width: 8),
                           _anomalyTag(Icons.phone_android_rounded, 'Device Match: 88%'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(10)),
                child: Text(a['severity'], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => _handleDismiss(a['id']), child: const Text('Dismiss', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _handleTakeAction(a), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFFFF), 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  elevation: 0,
                ),
                child: const Text('Take Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _anomalyTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
