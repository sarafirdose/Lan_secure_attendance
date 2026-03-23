import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _ringCtrl;

  int _stepIndex = 0;
  bool _stepDone = false;

  final List<_Step> _steps = const [
    _Step(Icons.security_rounded, 'Initializing SecureAttend',
        'Setting up security layers'),
    _Step(Icons.wifi_rounded, 'Checking network',
        'Scanning campus WiFi availability'),
    _Step(Icons.phone_android_rounded, 'Verifying device',
        'Checking device registration'),
    _Step(Icons.verified_user_rounded, 'Ready', 'All systems operational'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Cycle through steps
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _stepIndex = i);
    }

    setState(() => _stepDone = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Check if already logged in
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            loggedIn ? const DashboardScreen() : const LandingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Full background
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1B8E),
                  Color(0xFF1530A6),
                  Color(0xFF2347D4),
                  Color(0xFF2F5BEB)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated grid pattern
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Decorative blobs
          Positioned(top: -80, right: -80, child: _blob(240, 0.06)),
          Positioned(bottom: 100, left: -60, child: _blob(200, 0.05)),
          Positioned(
              top: size.height * 0.3, right: -40, child: _blob(140, 0.04)),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildLogoSection(),
                const SizedBox(height: 36),
                _buildBrandText(),
                const Spacer(flex: 3),
                _buildStepIndicator(),
                const SizedBox(height: 32),
                _buildLoadingBar(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  // ── Logo section ─────────────────────────────────────────────────────────────
  Widget _buildLogoSection() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outermost rotating dashed ring
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _rotateCtrl.value * 2 * 3.14159,
              child: child,
            ),
            child: SizedBox(
              width: 190,
              height: 190,
              child: CustomPaint(
                  painter: _DashedCirclePainter(
                      color: Colors.white.withValues(alpha: 0.12),
                      dashCount: 20)),
            ),
          ),

          // Pulsing ring 1
          AnimatedBuilder(
            animation: _ringCtrl,
            builder: (_, __) {
              final val = _ringCtrl.value;
              return Opacity(
                opacity: (1 - val).clamp(0.0, 1.0) * 0.3,
                child: Container(
                  width: 160 + val * 30,
                  height: 160 + val * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  ),
                ),
              );
            },
          ),

          // Pulsing ring 2 (offset)
          AnimatedBuilder(
            animation: _ringCtrl,
            builder: (_, __) {
              final val = (_ringCtrl.value + 0.5) % 1.0;
              return Opacity(
                opacity: (1 - val).clamp(0.0, 1.0) * 0.25,
                child: Container(
                  width: 160 + val * 30,
                  height: 160 + val * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                ),
              );
            },
          ),

          // Static inner ring
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 1),
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // Logo container
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + _pulseCtrl.value * 0.04,
              child: child,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12)),
                  BoxShadow(
                      color: const Color(0xFF2347D4).withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: -5),
                ],
              ),
              child: const Icon(Icons.security_rounded,
                  size: 52, color: Color(0xFF2347D4)),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
              begin: const Offset(0.3, 0.3),
              duration: 800.ms,
              curve: Curves.easeOutBack),

          // Security badges around logo
          ..._buildBadges(),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 600.ms);
  }

  List<Widget> _buildBadges() {
    final badges = [
      (Icons.wifi_rounded, const Offset(-72, -20)),
      (Icons.qr_code_rounded, const Offset(72, -20)),
      (Icons.lock_rounded, const Offset(0, -78)),
      (Icons.verified_rounded, const Offset(0, 78)),
    ];
    return badges.asMap().entries.map((e) {
      final delay = Duration(milliseconds: 600 + e.key * 150);
      return Positioned(
        left: 100 + e.value.$2.dx - 14,
        top: 100 + e.value.$2.dy - 14,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(e.value.$1, size: 14, color: Colors.white),
        )
            .animate(delay: delay)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
      );
    }).toList();
  }

  // ── Brand text ───────────────────────────────────────────────────────────────
  Widget _buildBrandText() {
    return Column(children: [
      const Text('SecureAttend',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5))
          .animate(delay: 300.ms)
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text('Anti-Proxy Attendance System',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                letterSpacing: 0.3)),
      ).animate(delay: 450.ms).fadeIn(duration: 600.ms),
      const SizedBox(height: 20),
      // Feature pills
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _featurePill(Icons.wifi_lock_rounded, 'LAN Verified'),
          _featurePill(Icons.qr_code_scanner_rounded, 'QR Scan'),
          _featurePill(Icons.phone_android_rounded, 'Device Lock'),
        ],
      ).animate(delay: 550.ms).fadeIn(duration: 600.ms),
    ]);
  }

  Widget _featurePill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  // ── Step indicator ────────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final step = _steps[_stepIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(children: [
        // Step icons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _steps.asMap().entries.map((e) {
            final done =
                e.key < _stepIndex || (e.key == _stepIndex && _stepDone);
            final active = e.key == _stepIndex;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 36 : 28,
                height: active ? 36 : 28,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF22C55E)
                      : active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2),
                        ]
                      : null,
                ),
                child: Icon(
                  done ? Icons.check_rounded : e.value.icon,
                  size: active ? 18 : 14,
                  color: done
                      ? Colors.white
                      : active
                          ? const Color(0xFF2347D4)
                          : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              if (e.key < _steps.length - 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: e.key < _stepIndex
                        ? const Color(0xFF22C55E)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ]);
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Current step text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(anim),
                child: child),
          ),
          child: Column(
            key: ValueKey(_stepIndex),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (!_stepDone || _stepIndex < _steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                Text(step.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (_stepDone && _stepIndex == _steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF22C55E), size: 16),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(step.subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12)),
            ],
          ),
        ),
      ]),
    ).animate(delay: 700.ms).fadeIn(duration: 500.ms);
  }

  // ── Loading bar ───────────────────────────────────────────────────────────────
  Widget _buildLoadingBar() {
    final progress = _stepDone ? 1.0 : (_stepIndex + 1) / _steps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                  _stepDone ? const Color(0xFF22C55E) : Colors.white),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ...List.generate(
              3,
              (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                          onPlay: (c) => c.repeat(),
                          delay: Duration(milliseconds: 200 * i))
                      .scaleXY(
                          begin: 0.5,
                          end: 1.2,
                          duration: 500.ms,
                          curve: Curves.easeInOut)
                      .then()
                      .scaleXY(
                          begin: 1.2,
                          end: 0.5,
                          duration: 500.ms,
                          curve: Curves.easeInOut)),
        ]),
        const SizedBox(height: 16),
        Text('v1.0.0 — Authorized students only',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 10)),
      ]),
    ).animate(delay: 800.ms).fadeIn(duration: 500.ms);
  }
}

// ── Data class ───────────────────────────────────────────────────────────────
class _Step {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Step(this.icon, this.title, this.subtitle);
}

// ── Grid painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const gap = 40.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Dashed circle painter ─────────────────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  const _DashedCirclePainter({required this.color, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 2;
    const dashAngle = 3.14159 * 2 / 40;
    for (int i = 0; i < dashCount; i++) {
      final start = i * (3.14159 * 2 / dashCount);
      final end = start + dashAngle;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), start,
          end, false, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
