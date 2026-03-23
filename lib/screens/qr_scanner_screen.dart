import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart';
import '../services/network_service.dart';
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
        backgroundColor: const Color(0xFF2347D4),
        title: const Text('Scan Attendance QR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Verifying attendance...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Timer badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _secondsLeft < 30
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF2347D4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Session ends: $_timerDisplay',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),

                const SizedBox(height: 32),

                // Scan frame
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF2347D4), width: 3),
                      borderRadius: BorderRadius.circular(16),
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

                const SizedBox(height: 20),

                Text(
                  _isProcessing
                      ? 'Processing...'
                      : 'Point camera at the attendance QR',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ).animate(delay: 300.ms).fadeIn(),

                const Spacer(),

                // Security status bar
                Container(
                  margin: const EdgeInsets.all(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _securityBadge(
                          Icons.wifi_rounded, 'Campus\nWiFi', Colors.green),
                      Container(width: 1, height: 36, color: Colors.grey[200]),
                      _securityBadge(Icons.my_location_rounded, 'Subnet\nValid',
                          Colors.green),
                      Container(width: 1, height: 36, color: Colors.grey[200]),
                      _securityBadge(Icons.verified_rounded, 'Device\nVerified',
                          Colors.green),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
              ],
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
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: Color(0xFF4B7BF5), width: 3)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: Color(0xFF4B7BF5), width: 3)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: Color(0xFF4B7BF5), width: 3)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: Color(0xFF4B7BF5), width: 3)
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
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
        left: 8,
        right: 8,
        child: Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0x882347D4),
                Color(0xFF2347D4),
                Color(0x882347D4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
