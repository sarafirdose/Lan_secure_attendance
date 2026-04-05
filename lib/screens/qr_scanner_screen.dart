import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart';
import '../services/network_service.dart';
import '../services/attendance_proof_service.dart';
import 'attendance_success_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  bool _isProcessing = false;
  int _secondsLeft = 180;
  Timer? _timer;

  // Cached network info from security verification
  String _cachedIp = '';
  String _cachedSsid = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _cacheNetworkInfo();
  }

  Future<void> _cacheNetworkInfo() async {
    final result = await NetworkService.checkNetworkSecurity();
    if (mounted) {
      _cachedIp = result['deviceIp'] ?? '';
      _cachedSsid = result['ssid'] ?? '';
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerDisplay {
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // ── QR detection → Firestore write ──────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    final rawValue = barcode!.rawValue!;

    // Expected QR format: TOKEN|SUBJECT_CODE|SUBJECT_NAME|TIMESTAMP
    // e.g. "abc123xyz|CSU633|Software Engineering|1742234400"
    final parts = rawValue.split('|');
    if (parts.length < 3) {
      _showError('Invalid QR code format. Please scan the attendance QR.');
      return;
    }

    final qrToken = parts[0];
    final subjectCode = parts[1];
    final subjectName = parts[2];

    // Get device fingerprint for verification
    final fingerprint = await NetworkService.getDeviceFingerprint();

    // Write to Firestore with all validations
    final result = await FirestoreService.markAttendance(
      subjectCode: subjectCode,
      subjectName: subjectName,
      qrToken: qrToken,
      deviceFingerprint: fingerprint,
      deviceIp: _cachedIp,
      ssid: _cachedSsid,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // ── Step 7: Generate and save verifiable proof ─────────────────────────
      await AttendanceProofService.saveProof(
        sessionID: 'SESS_${subjectCode}_${parts.length > 3 ? parts[3] : DateTime.now().millisecondsSinceEpoch}',
        subjectCode: subjectCode,
        subjectName: subjectName,
        token: qrToken,
        deviceID: fingerprint,
      );

      _scanned = true;
      _timer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceSuccessScreen(
            subject: subjectName,
            subjectCode: subjectCode,
            rollNumber: '', // will be loaded from Firestore in success screen
          ),
        ),
      );
    } else {
      _showError(result.message);
    }
  }

  Future<void> _performTestScan() async {
    setState(() => _isProcessing = true);
    _controller.stop();

    // Dummy data for testing bypass
    const subjectCode = "TEST101";
    const subjectName = "Debug Test Module";
    const qrToken = "DEBUG_TOKEN_123";
    const fingerprint = "DEBUG_DEVICE_FINGERPRINT";

    await AttendanceProofService.saveProof(
      sessionID: 'SESS_DEBUG_${DateTime.now().millisecondsSinceEpoch}',
      subjectCode: subjectCode,
      subjectName: subjectName,
      token: qrToken,
      deviceID: fingerprint,
    );

    if (!mounted) return;
    _scanned = true;
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AttendanceSuccessScreen(
          subject: subjectName,
          subjectCode: subjectCode,
          rollNumber: 'DEBUG_USER',
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Re-enable scanning after showing error
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_scanned) {
        _controller.start();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Scan Attendance QR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera Layer
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2. Processing Overlay Layer
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Verifying attendance...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          // 3. UI Layer
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Timer badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _secondsLeft < 30
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Session ends: $_timerDisplay',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 40),

                  // Scan frame
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          _corner(top: true, left: true),
                          _corner(top: true, left: false),
                          _corner(top: false, left: true),
                          _corner(top: false, left: false),
                          if (!_isProcessing) const _ScanLine(),
                        ],
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 32),
                  const Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 60),

                  // Security status bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _securityBadge(
                            Icons.wifi_rounded, 'Campus WiFi', Colors.green),
                        Container(
                            width: 1, height: 32, color: Colors.grey[200]),
                        _securityBadge(Icons.my_location_rounded,
                            'Subnet Valid', Colors.green),
                        Container(
                            width: 1, height: 32, color: Colors.grey[200]),
                        _securityBadge(Icons.verified_rounded,
                            'Device Verified', Colors.green),
                      ],
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),

                  const SizedBox(height: 48),

                  // ── DEBUG BYPASS BUTTON ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton.icon(
                      onPressed: _performTestScan,
                      icon: const Icon(Icons.bug_report_rounded),
                      label: const Text('FORCE TEST SCAN (BYPASS)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ).animate(delay: 600.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    return Positioned(
      top: top ? -1 : null,
      bottom: top ? null : -1,
      left: left ? -1 : null,
      right: left ? null : -1,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: Color(0xFF059669), width: 4)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: Color(0xFF059669), width: 4)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: Color(0xFF059669), width: 4)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: Color(0xFF059669), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _securityBadge(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827))),
      ],
    );
  }
}

// ── Animated scan line ────────────────────────────────────────────────────────
class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: _anim.value * 230 + 15,
        left: 20,
        right: 20,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

