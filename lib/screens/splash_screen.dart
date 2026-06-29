import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';
import 'landing_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;

  int _stepIndex = 0;
  bool _stepDone = false;

  final List<_Step> _steps = const [
    _Step(Icons.security_rounded, 'Initializing Security', 'Encrypting local storage'),
    _Step(Icons.wifi_rounded, 'Checking Network', 'Scanning connection status'),
    _Step(Icons.cloud_sync_rounded, 'Finding Server', 'Locating backend automatically'),
    _Step(Icons.phone_android_rounded, 'Verifying Device', 'Checking enrollment'),
    _Step(Icons.verified_user_rounded, 'Ready', 'System operational'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _runSequence();
  }

  Future<void> _runSequence() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _stepIndex = i);

      if (i == 2) {
        // Run network discovery with a hard limit to prevent splash freeze
        try {
          await NetworkService.discoverServer().timeout(const Duration(seconds: 10));
        } catch (_) {
          debugPrint('Network Discovery Timeout - Continuing with default IP');
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 600)); // Faster transitions
      }
    }

    if (!mounted) return;
    setState(() => _stepDone = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => loggedIn ? const DashboardScreen() : const LandingScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Solid Blue Background as requested
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0056B3), // Solid Institutional Blue
            ),
          ),

          // Animated Grid/Pattern from Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          // Decorative Vibrant Overlays
          Positioned(
            top: -100,
            right: -50,
            child: _GlowCircle(size: 300, color: Colors.blueAccent.withOpacity(0.15)),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: _GlowCircle(size: 250, color: Colors.indigoAccent.withOpacity(0.1)),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                
                // Animated Orbital Logo Section (From Image)
                _buildOrbitalLogo(),
                
                const SizedBox(height: 56),
                
                const Text(
                  'SecureAttend',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 12),
                
                // Sub-pill (From Image)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Institutional Attendance Portal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ).animate(delay: 400.ms).fadeIn(),
                
                const Spacer(flex: 2),
                
                // Feature Icons (Secondary visibility)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconPill(Icons.wifi_rounded, 'LAN LINK'),
                    const SizedBox(width: 8),
                    _iconPill(Icons.qr_code_scanner_rounded, 'SECURE SCAN'),
                  ],
                ).animate(delay: 600.ms).fadeIn(),
                
                const SizedBox(height: 32),

                // Step Bar (From Image)
                _buildStepBar(),

                const SizedBox(height: 32),
                
                // Centered Ready Status (From Image)
                _buildReadyStatus(),
                
                const SizedBox(height: 64),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitalLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Orbiting Rings
          RotationTransition(
            turns: _rotateCtrl,
            child: CustomPaint(
              size: const Size(220, 220),
              painter: _OrbitalPainter(),
            ),
          ),
          
          // Outer Badges (Static positions on orbit)
          ..._buildOrbitIcons(),

          // Pulsing Glow
          ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.1).animate(_pulseCtrl),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          // Main Shield Container (From Image)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 52,
              color: Color(0xFF0056B3),
            ),
          ).animate().scale(duration: 1.seconds, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  List<Widget> _buildOrbitIcons() {
    final icons = [Icons.lock_rounded, Icons.wifi_tethering_error_rounded, Icons.qr_code_rounded, Icons.verified_user_rounded];
    final offsets = [const Offset(0, -90), const Offset(-90, 0), const Offset(90, 0), const Offset(0, 90)];
    return List.generate(4, (i) {
      return Transform.translate(
        offset: offsets[i],
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(icons[i], size: 14, color: Colors.white),
        ),
      );
    });
  }

  Widget _iconPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStepBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(5, (i) {
          final isDone = i < _stepIndex;
          final isCurrent = i == _stepIndex;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone || _stepDone 
                        ? const Color(0xFF22C55E) // Green from image
                        : isCurrent ? Colors.white : Colors.white.withOpacity(0.15),
                    boxShadow: isCurrent ? [const BoxShadow(color: Colors.white24, blurRadius: 10)] : null,
                  ),
                  child: Icon(
                    isDone || _stepDone ? Icons.check : _steps[i].icon,
                    size: 16,
                    color: isDone || _stepDone ? Colors.white : isCurrent ? const Color(0xFF2563EB) : Colors.white54,
                  ),
                ),
                if (i < 4) 
                   Expanded(
                     child: Container(
                       height: 2,
                       color: isDone ? const Color(0xFF22C55E) : Colors.white.withOpacity(0.15),
                     ),
                   ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReadyStatus() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            Text(
              _steps[_stepIndex].title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _steps[_stepIndex].subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    ).animate(key: ValueKey(_stepIndex)).fadeIn();
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 0.5;
    const gap = 30.0;
    for (double i = 0; i < size.width; i += gap) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += gap) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override bool shouldRepaint(_) => false;
}

class _OrbitalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2.2, paint);
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2.8, paint);
  }
  @override bool shouldRepaint(_) => false;
}

class _Step {
  final IconData icon; final String title; final String subtitle;
  const _Step(this.icon, this.title, this.subtitle);
}
