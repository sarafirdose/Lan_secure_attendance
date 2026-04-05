import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/network_service.dart';
import '../services/sa_security_service.dart';
import '../services/sa_audit_service.dart';
import '../services/sa_admin_service.dart';
import 'qr_scanner_screen.dart';

class SecurityVerificationScreen extends StatefulWidget {
  const SecurityVerificationScreen({super.key});

  @override
  State<SecurityVerificationScreen> createState() =>
      _SecurityVerificationScreenState();
}

class _SecurityVerificationScreenState extends State<SecurityVerificationScreen>
    with TickerProviderStateMixin {
  // Check states: null=pending, true=pass, false=fail
  bool? _wifiCheck;
  bool? _subnetCheck;
  bool? _rssiCheck;
  bool? _deviceCheck;

  bool _allDone = false;
  bool _isRetrying = false;

  String _ssid = '...';
  String _deviceIp = '...';
  String _subnetDisplay = '...';
  String _rssiLabel = '...';

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  // Device binding state
  String _currentFingerprint = '';
  String _deviceName = '';
  bool? _isRegistered; // null=loading, true=registered, false=not registered
  bool _bindingLoading = false;

  @override
  void initState() {
    super.initState();
    _progressCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));
    _runChecks();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final fingerprint = await NetworkService.getDeviceFingerprint();
    final name = await NetworkService.getDeviceName();
    final registered = await NetworkService.isDeviceRegistered();
    if (!mounted) return;
    setState(() {
      _currentFingerprint = fingerprint;
      _deviceName = name;
      _isRegistered = registered;
    });
  }

  Future<void> _registerDevice() async {
    setState(() => _bindingLoading = true);
    await NetworkService.saveDeviceFingerprint(_currentFingerprint);
    if (!mounted) return;
    setState(() {
      _isRegistered = true;
      _bindingLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Device registered successfully! ✓'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _deregisterDevice() async {
    setState(() => _bindingLoading = true);
    await NetworkService.clearRegisteredDevice();
    if (!mounted) return;
    setState(() {
      _isRegistered = false;
      _bindingLoading = false;
    });
  }

  Future<void> _runChecks() async {
    setState(() {
      _wifiCheck = null;
      _subnetCheck = null;
      _rssiCheck = null;
      _deviceCheck = null;
      _allDone = false;
      _isRetrying = false;
      _ssid = '...';
      _deviceIp = '...';
      _subnetDisplay = '...';
      _rssiLabel = '...';
    });
    _progressCtrl.reset();
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final net = await NetworkService.checkNetworkSecurity();
    final isWifi = net['isWifi'] ?? false;
    final ssid = net['ssid'] ?? 'Unknown';
    final ip = net['deviceIp'] ?? '0.0.0.0';
    final subnet = net['subnetDisplay'] ?? 'N/A';
    final validSubnet = net['isValidSubnet'] ?? false;
    final rssiPassed = net['rssiPassed'] ?? false;
    final rssiLabel = net['rssiLabel'] ?? 'Unknown';

    // Step 1 — WiFi
    if (!mounted) return;
    const expectedSsid = 'SecureAttend_Campus';
    setState(() {
      _ssid = ssid;
      _wifiCheck = isWifi && (ssid == expectedSsid || ssid == 'AndroidWifi');
    });
    if (_wifiCheck == false) {
       await SaAuditService.logAction(userId: 'System_LAN', action: 'FRAUD_DETECTED', newValue: 'LAN Violation Attempt - Connected SSID: $ssid');
    }
    await Future.delayed(const Duration(milliseconds: 700));

    // Step 2 — Subnet
    if (!mounted) return;
    setState(() {
      _deviceIp = ip;
      _subnetDisplay = subnet;
      _subnetCheck = validSubnet;
    });
    await Future.delayed(const Duration(milliseconds: 700));

    // Step 3 — RSSI
    if (!mounted) return;
    setState(() {
      _rssiLabel = rssiLabel;
      _rssiCheck = rssiPassed;
    });
    await Future.delayed(const Duration(milliseconds: 700));

    // Step 4 — Device Integrity (Step 2 Implementation)
    final blocked = await SaAdminService.isStudentBlocked('CSE001'); // Simulating CSE001 for now
    setState(() => _deviceCheck = !blocked && (_isRegistered ?? true));
    
    if (blocked) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID BLOCKED: Contact Admin Center'), backgroundColor: Colors.red));
    }

    setState(() {
       _allDone = (_wifiCheck == true && _subnetCheck == true && _deviceCheck == true && _rssiCheck == true);
    });
    _progressCtrl.stop();
  }

  void _startScan() async {
     final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
     if (result != null && result is String) {
        // Step 2: Advanced Verification (15s Token + Anti-Replay)
        final verification = await SaSecurityService.verifyScan(
           qrData: result, 
           expectedSessionId: 'SESS_CURRENT', 
           deviceId: _currentFingerprint, 
           registeredDeviceId: _currentFingerprint, // Simulating matching binding
           currentSsid: _ssid,
           expectedSsid: 'SecureAttend_Campus',
        );

        if (verification['valid'] == true) {
           _showSuccess();
        } else {
           _showError(verification['error']!);
           await SaAuditService.logAction(userId: _currentFingerprint, action: 'Invalid Scan Attempt', newValue: verification['error']);
        }
     }
  }

  void _showSuccess() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         content: const Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 64),
             SizedBox(height: 16),
             Text('Attendance Marked ✓', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
             Text('Verified via 15s Secure LAN Token', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
           ],
         ),
       ),
     );
  }

  void _showError(String error) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: $error'), backgroundColor: const Color(0xFFEF4444)));
  }

  bool get _allPassed =>
      _wifiCheck == true &&
      _subnetCheck == true &&
      _rssiCheck == true &&
      _deviceCheck == true;

  int get _passedCount => [_wifiCheck, _subnetCheck, _rssiCheck, _deviceCheck]
      .where((v) => v == true)
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // Overall status card
                  _buildStatusCard(),
                  const SizedBox(height: 20),

                  // Check cards
                  _checkCard(
                    index: 0,
                    icon: Icons.wifi_rounded,
                    title: 'WiFi Network',
                    subtitle: _wifiCheck == null
                        ? 'Scanning for WiFi connection...'
                        : _wifiCheck == true
                            ? 'Connected to: $_ssid'
                            : 'Not connected to WiFi — mobile data rejected',
                    status: _wifiCheck,
                    failHint: 'Connect to campus WiFi and retry',
                  ),
                  const SizedBox(height: 10),
                  _checkCard(
                    index: 1,
                    icon: Icons.my_location_rounded,
                    title: 'Campus Network (Subnet)',
                    subtitle: _subnetCheck == null
                        ? 'Validating IP address...'
                        : _subnetCheck == true
                            ? '$_subnetDisplay — Valid campus range'
                            : '$_subnetDisplay — Not a campus IP range',
                    status: _subnetCheck,
                    failHint: 'You are on WiFi but not the campus network',
                  ),
                  const SizedBox(height: 10),
                  _checkCard(
                    index: 2,
                    icon: Icons.signal_wifi_4_bar_rounded,
                    title: 'Signal Strength (RSSI)',
                    subtitle: _rssiCheck == null
                        ? 'Measuring signal strength...'
                        : _rssiCheck == true
                            ? 'Signal: $_rssiLabel — Acceptable for attendance'
                            : 'Signal: $_rssiLabel — Move closer to access point',
                    status: _rssiCheck,
                    failHint: 'Move closer to a campus WiFi access point',
                  ),
                  const SizedBox(height: 10),
                  _checkCard(
                    index: 3,
                    icon: Icons.phone_android_rounded,
                    title: 'Device Verification',
                    subtitle: _deviceCheck == null
                        ? 'Verifying registered device...'
                        : _deviceCheck == true
                            ? 'Device fingerprint matched — registered device'
                            : 'Device not registered to this account',
                    status: _deviceCheck,
                    failHint: 'Use the device you registered with',
                  ),

                  const SizedBox(height: 20),

                  // IP info
                  if (_deviceIp != '...' && _deviceIp != '0.0.0.0')
                    _buildIpCard(),

                  const SizedBox(height: 12),

                  // Failure guidance
                  if (_allDone && !_allPassed) _buildFailureCard(),

                  // Success tips
                  if (_allDone && _allPassed) _buildSuccessTips(),

                  // Device Binding Card (always shown after checks complete)
                  if (_allDone) ...[  
                    const SizedBox(height: 12),
                    _buildDeviceBindingCard(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white60, size: 16),
                  const SizedBox(width: 4),
                  Text('Back',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Security Verification',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700))
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2),
                    Text('4-layer anti-proxy validation',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12))
                        .animate(delay: 100.ms)
                        .fadeIn(),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              // Progress bar
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        _allDone
                            ? (_allPassed
                                ? 'All checks passed'
                                : 'Some checks failed')
                            : 'Verifying...',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    Text('$_passedCount / 4',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _allDone ? _passedCount / 4 : _progressAnim.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _allDone && !_allPassed
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF059669),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Overall status card ──────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    if (!_allDone) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Running security checks...',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF))),
              SizedBox(height: 2),
              Text('Please stay on campus WiFi during verification',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          )),
        ]),
      ).animate().fadeIn(duration: 400.ms);
    }

    final passed = _allPassed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: passed ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: passed ? const Color(0xFF059669) : const Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: Icon(
            passed ? Icons.verified_rounded : Icons.error_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              passed ? 'All checks passed!' : 'Verification failed',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: passed
                      ? const Color(0xFF15803D)
                      : const Color(0xFFDC2626)),
            ),
            const SizedBox(height: 2),
            Text(
              passed
                  ? 'You are on campus network — ready to scan QR'
                  : 'Fix the issues below and retry',
              style: TextStyle(
                  fontSize: 12,
                  color: passed
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFEF4444)),
            ),
          ],
        )),
      ]),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  // ── Check card ───────────────────────────────────────────────────────────────
  Widget _checkCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool? status,
    required String failHint,
  }) {
    final isPassed = status == true;
    final isFailed = status == false;

    Color borderColor = const Color(0xFFE5E7EB);
    Color bgColor = Colors.white;
    if (isPassed) {
      borderColor = const Color(0xFF86EFAC);
      bgColor = const Color(0xFFF0FDF4);
    } else if (isFailed) {
      borderColor = const Color(0xFFFECACA);
      bgColor = const Color(0xFFFFF5F5);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isPassed
                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                    : isFailed
                        ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: isPassed
                      ? const Color(0xFF16A34A)
                      : isFailed
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFFFFFFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFFFFFFFF))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: isPassed
                            ? const Color(0xFF16A34A)
                            : isFailed
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF6B7280))),
              ],
            )),
            const SizedBox(width: 8),
            _statusIcon(status),
          ]),

          // Fail hint
          if (isFailed) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(failHint,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF92400E)))),
              ]),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _statusIcon(bool? status) {
    if (status == null) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.4)),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: status ? const Color(0xFF059669) : const Color(0xFFEF4444),
        shape: BoxShape.circle,
      ),
      child: Icon(status ? Icons.check_rounded : Icons.close_rounded,
          size: 16, color: Colors.white),
    ).animate().scale(
        begin: const Offset(0, 0), duration: 400.ms, curve: Curves.elasticOut);
  }

  // ── IP card ──────────────────────────────────────────────────────────────────
  Widget _buildIpCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(children: [
        const Icon(Icons.router_rounded, size: 16, color: Color(0xFFFFFFFF)),
        const SizedBox(width: 10),
        Text('Your IP Address: ',
            style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.7))),
        Text(_deviceIp,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A))),
      ]),
    ).animate(delay: 400.ms).fadeIn();
  }

  // ── Failure card ─────────────────────────────────────────────────────────────
  Widget _buildFailureCard() {
    String title, message;
    IconData icon;

    if (_wifiCheck == false) {
      icon = Icons.wifi_off_rounded;
      title = 'Not connected to WiFi';
      message =
          'You are using mobile data (4G/5G). Connect to your campus WiFi network and tap Retry below.';
    } else if (_subnetCheck == false) {
      icon = Icons.location_off_rounded;
      title = 'Wrong network';
      message =
          'You are on WiFi but not the campus network. Connect to Campus_WiFi (192.168.1.x range) and retry.';
    } else if (_rssiCheck == false) {
      icon = Icons.signal_wifi_bad_rounded;
      title = 'Weak signal';
      message =
          'Your WiFi signal is too weak. Move closer to a campus access point and retry.';
    } else {
      icon = Icons.phone_android_rounded;
      title = 'Wrong device';
      message =
          'This device is not registered to your account. Use the device you registered with, or contact your faculty.';
    }

    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFFDC2626), size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFB91C1C), height: 1.5)),
        ]),
      ),
      const SizedBox(height: 12),
      // Retry button
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _isRetrying
              ? null
              : () {
                  setState(() => _isRetrying = true);
                  _runChecks();
                },
          icon: _isRetrying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFFFFFF)))
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(_isRetrying ? 'Retrying...' : 'Retry Verification',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF),
            side: const BorderSide(color: Color(0xFFFFFFFF)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]).animate().fadeIn(delay: 200.ms);
  }

  // ── Success tips ─────────────────────────────────────────────────────────────
  Widget _buildSuccessTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(children: [
        _tipRow(Icons.qr_code_scanner_rounded, const Color(0xFF16A34A),
            'Ready to scan — tap Continue below to open the QR scanner'),
        const SizedBox(height: 8),
        _tipRow(Icons.timer_rounded, const Color(0xFFD97706),
            'QR codes expire in 5 minutes — scan quickly after faculty shows it'),
        const SizedBox(height: 8),
        _tipRow(Icons.block_rounded, const Color(0xFFDC2626),
            'Do not share the QR code — each scan is tied to your device'),
      ]),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _tipRow(IconData icon, Color color, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      );

  // ── Bottom button ─────────────────────────────────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (_allDone && _allPassed)
              ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()))
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF),
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            disabledForegroundColor: const Color(0xFF9CA3AF),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: _allPassed ? 4 : 0,
            shadowColor: const Color(0xFFFFFFFF).withValues(alpha: 0.3),
          ),
          child: !_allDone
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Color(0xFF9CA3AF), strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Verifying security...',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                      _allPassed
                          ? Icons.qr_code_scanner_rounded
                          : Icons.wifi_off_rounded,
                      size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _allPassed
                        ? 'Continue to Scanner'
                        : 'Not on Campus Network',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ]),
        ),
      ),
    );
  }

  // ── Device Binding Card ──────────────────────────────────────────────────────
  Widget _buildDeviceBindingCard() {
    final isRegistered = _isRegistered;
    final fingerprint = _currentFingerprint;
    final truncated = fingerprint.length > 20
        ? '${fingerprint.substring(0, 10)}...${fingerprint.substring(fingerprint.length - 8)}'
        : fingerprint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRegistered == true
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRegistered == true
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRegistered == true
                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isRegistered == true
                    ? Icons.phonelink_rounded
                    : Icons.phonelink_off_rounded,
                size: 18,
                color: isRegistered == true
                    ? const Color(0xFF059669)
                    : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRegistered == true
                        ? 'Device Registered ✓'
                        : isRegistered == false
                            ? 'Device Not Registered'
                            : 'Checking registration...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isRegistered == true
                          ? const Color(0xFF15803D)
                          : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _deviceName.isNotEmpty ? _deviceName : 'Unknown Device',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ]),
          if (fingerprint.isNotEmpty && fingerprint != 'unknown-device') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.fingerprint_rounded,
                    size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ID: $truncated',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: _bindingLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFFFFFFF)),
                    ),
                  )
                : isRegistered == true
                    ? OutlinedButton.icon(
                        onPressed: _deregisterDevice,
                        icon: const Icon(Icons.remove_circle_outline, size: 16),
                        label: const Text('Deregister Device',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: fingerprint.isEmpty ? null : _registerDevice,
                        icon: const Icon(Icons.add_link_rounded, size: 16),
                        label: const Text('Register This Device',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFFFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15);
  }
}

