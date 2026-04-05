import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/fraud_detection_service.dart';

class FraudDetectionScreen extends StatefulWidget {
  const FraudDetectionScreen({super.key});

  @override
  State<FraudDetectionScreen> createState() => _FraudDetectionScreenState();
}

class _FraudDetectionScreenState extends State<FraudDetectionScreen>
    with TickerProviderStateMixin {
  int _totalScans = 0;
  int _clearedCount = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    
    // In real-time mode, we start with 0 scans unless fetched from historical logs
    _totalScans = 0; 
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _severityColor(FraudSeverity s) {
    switch (s) {
      case FraudSeverity.critical:
        return const Color(0xFFEF4444);
      case FraudSeverity.warning:
        return const Color(0xFFF59E0B);
      case FraudSeverity.suspicious:
        return const Color(0xFF8B5CF6);
    }
  }

  Color _severityBg(FraudSeverity s) {
    switch (s) {
      case FraudSeverity.critical:
        return const Color(0xFFFFE4E6);
      case FraudSeverity.warning:
        return const Color(0xFFFEF3C7);
      case FraudSeverity.suspicious:
        return const Color(0xFFEDE9FE);
    }
  }

  IconData _ruleIcon(FraudRule r) {
    switch (r) {
      case FraudRule.duplicateQr:
        return Icons.qr_code_2_rounded;
      case FraudRule.deviceMismatch:
        return Icons.phone_android_rounded;
      case FraudRule.rapidReScan:
        return Icons.timer_off_rounded;
      case FraudRule.unauthorizedNetwork:
        return Icons.wifi_off_rounded;
      case FraudRule.expiredToken:
        return Icons.access_time_filled_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = FraudDetectionService.logs;
    final active = logs.where((l) => !l.isDismissed).toList();
    final critical =
        active.where((l) => l.severity == FraudSeverity.critical).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(active.length, critical),
          _buildStatsBar(active.length, critical),
          Expanded(
            child: logs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: logs.length,
                    itemBuilder: (_, i) => _buildAlertCard(logs[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int active, int critical) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.gpp_bad_rounded,
                        color: Color(0xFFEF4444), size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fraud Detection',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('AI Monitoring System',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(int active, int critical) {
    final dismissed = FraudDetectionService.logs
        .where((l) => l.isDismissed)
        .length;
    return Container(
      color: const Color(0xFF1A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _statItem('$_totalScans', 'Total Scans', const Color(0xFFBFDBFE)),
          _divider(),
          _statItem('$active', 'Active Alerts', const Color(0xFFFCA5A5)),
          _divider(),
          _statItem('$critical', 'Critical', const Color(0xFFDC2626)),
          _divider(),
          _statItem('$dismissed', 'Reviewed', const Color(0xFF86EFAC)),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withOpacity(0.1),
      );

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 72, color: Color(0xFF059669)),
          const SizedBox(height: 16),
          const Text('No Fraud Detected',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFFFFF))),
          const SizedBox(height: 8),
          Text('All attendance scans look clean',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildAlertCard(FraudLog log, int index) {
    final color = _severityColor(log.severity);
    final bg = _severityBg(log.severity);
    final icon = _ruleIcon(log.rule);
    final timeAgo = _timeAgo(log.timestamp);
    final isDismissed = log.isDismissed;

    return Opacity(
      opacity: isDismissed ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDismissed
                ? const Color(0xFFE5E7EB)
                : color.withOpacity(0.35),
            width: isDismissed ? 1 : 1.5,
          ),
          boxShadow: [
            if (!isDismissed)
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Severity badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                log.severity.name.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isDismissed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('REVIEWED',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF9CA3AF))),
                               ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(log.ruleLabel,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDismissed
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFFFFFFFF))),
                        const SizedBox(height: 2),
                        Text(log.ruleDescription,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Student info row
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _infoItem(Icons.person_rounded, log.studentName),
                  const SizedBox(width: 12),
                  _infoItem(Icons.badge_rounded, log.rollNumber),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  _infoItem(Icons.phone_android_rounded,
                      log.deviceId.length > 12 ? log.deviceId.substring(0, 12) : log.deviceId),
                  const SizedBox(width: 12),
                  _infoItem(Icons.router_rounded, log.ipAddress),
                ],
              ),
            ),

            // Time + action row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(_timeAgo(log.timestamp),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                  const Spacer(),
                  if (!isDismissed) ...[
                    // Block button
                    if (!log.isBlocked)
                      GestureDetector(
                        onTap: () {
                          FraudDetectionService.blockStudent(log.id);
                          setState(() {});
                          _showSnack('${log.studentName} blocked from scanning');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block_rounded,
                                  size: 12, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text('Block',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.do_not_disturb_rounded,
                                size: 12, color: Color(0xFF991B1B)),
                            SizedBox(width: 4),
                            Text('Blocked',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF991B1B))),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Dismiss button
                    GestureDetector(
                      onTap: () {
                        FraudDetectionService.dismissLog(log.id);
                        setState(() => _clearedCount++);
                        _showSnack('Alert marked as reviewed');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 12, color: Color(0xFF6B7280)),
                            SizedBox(width: 4),
                            Text('Review',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index < 5 ? index * 80 : 0))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.15, curve: Curves.easeOut);
  }

  Widget _infoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
