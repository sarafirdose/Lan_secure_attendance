import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/demo_state_service.dart';
import '../services/app_state_service.dart';
import '../services/attendance_data_service.dart';

class DemoQrScannerScreen extends StatefulWidget {
  const DemoQrScannerScreen({super.key});

  @override
  State<DemoQrScannerScreen> createState() => _DemoQrScannerScreenState();
}

class _DemoQrScannerScreenState extends State<DemoQrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  bool _hasPermission = false;
  bool _isProcessing = false;
  bool _torchOn = false;

  double _zoomFactor = 0.0;
  late AnimationController _scanLineCtrl;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() => _hasPermission = status.isGranted);
      if (status.isGranted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _controller.setZoomScale(0.2);
            setState(() => _zoomFactor = 0.2);
          }
        });
      }
    }
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await _controller.stop();
        _processQR(barcode.rawValue!);
        break;
      }
    }
  }

  void _processQR(String code) {
    final demo = DemoStateService();
    final user = AppStateService().currentUser;

    final studentName = user?['name'] ?? user?['fullName'] ?? 'Student';
    final rollNumber = user?['uid'] ?? 'DEMO_STU';
    final scannedSessionId = code.split('|').first;

    if (!demo.hasActiveSession) {
      _showResult(
        success: false,
        title: 'No Active Session',
        subtitle: 'Teacher has not started a session yet.',
        code: code,
      );
      return;
    }

    demo.markAttendance(
      studentName: studentName,
      rollNumber: rollNumber,
      scannedSessionId: scannedSessionId,
    );

    if (demo.demoSubject != null) {
      AttendanceDataService.markAttendance(demo.demoSubject!);
    }

    _showResult(
      success: true,
      title: 'Attendance Marked!',
      subtitle: 'Subject: ${demo.demoSubject ?? "Unknown"}\nClass: ${demo.demoClass ?? ""}',
      code: code,
    );
  }

  void _showResult({
    required bool success,
    required String title,
    required String subtitle,
    required String code,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (success ? const Color(0xFF059669) : const Color(0xFFEF4444))
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: success ? const Color(0xFF059669) : const Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Attendance QR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn ? Colors.yellow : Colors.white),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: !_hasPermission
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  const Text('Camera permission required',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestCameraPermission,
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleDetection,
                ),

                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        ..._buildCorners(),
                        AnimatedBuilder(
                          animation: _scanLineCtrl,
                          builder: (_, __) => Positioned(
                            top: _scanLineCtrl.value * 230 + 15,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0056B3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0056B3).withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 20,
                  top: MediaQuery.of(context).size.height * 0.2,
                  bottom: MediaQuery.of(context).size.height * 0.3,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: _zoomFactor,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF0056B3),
                      inactiveColor: Colors.white24,
                      onChanged: (v) {
                        setState(() => _zoomFactor = v);
                        _controller.setZoomScale(v);
                      },
                    ),
                  ),
                ),

                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      if (_isProcessing)
                        const CircularProgressIndicator(color: Color(0xFF0056B3)),
                      if (!_isProcessing) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Align the QR code within the frame\nUse the slider on the right to zoom',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildCorners() {
    const color = Color(0xFF0056B3);
    const size = 24.0;
    const thickness = 3.0;
    return [
      Positioned(top: 0, left: 0, child: _corner(Colors.transparent, color, Colors.transparent, color, size, thickness)),
      Positioned(top: 0, right: 0, child: _corner(Colors.transparent, Colors.transparent, color, color, size, thickness)),
      Positioned(bottom: 0, left: 0, child: _corner(color, color, Colors.transparent, Colors.transparent, size, thickness)),
      Positioned(bottom: 0, right: 0, child: _corner(color, Colors.transparent, color, Colors.transparent, size, thickness)),
    ];
  }

  Widget _corner(Color top, Color bottom, Color left, Color right, double size, double thickness) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top != Colors.transparent ? BorderSide(color: top, width: thickness) : BorderSide.none,
          bottom: bottom != Colors.transparent ? BorderSide(color: bottom, width: thickness) : BorderSide.none,
          left: left != Colors.transparent ? BorderSide(color: left, width: thickness) : BorderSide.none,
          right: right != Colors.transparent ? BorderSide(color: right, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }
}
