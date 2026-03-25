import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'teacher_login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _floatAnim;
  int _currentFeature = 0;

  final List<_Feature> _features = const [
    _Feature(Icons.wifi_rounded, 'LAN Verified',
        'Attendance only allowed on campus WiFi'),
    _Feature(Icons.qr_code_scanner_rounded, 'QR Scan',
        'Faculty generates a time-limited QR per class'),
    _Feature(Icons.phone_android_rounded, 'Device Lock',
        'One device per student — no proxy possible'),
    _Feature(Icons.verified_user_rounded, 'Anti-Proxy',
        'Multiple verification layers every scan'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      setState(
          () => _currentFeature = (_currentFeature + 1) % _features.length);
      return true;
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1530A6),
                  Color(0xFF2347D4),
                  Color(0xFF3558E8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
              top: -60,
              right: -60,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05)))),
          Positioned(
              bottom: 200,
              left: -50,
              child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTopBadge(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildLogo(),
                        const SizedBox(height: 24),
                        _buildHeadline(),
                        const SizedBox(height: 28),
                        _buildFeatureCarousel(),
                        const SizedBox(height: 36),
                        _buildButtons(),
                        const SizedBox(height: 20),
                        _buildFooter(),
                        const SizedBox(height: 16),

                        // Teacher Login Button
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeacherLoginScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Login as Teacher',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: 700.ms).fadeIn(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: Color(0xFF22C55E), shape: BoxShape.circle))
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 600.ms)
            .then()
            .fadeOut(duration: 600.ms),
        const SizedBox(width: 7),
        const Text('System Active — Campus Ready',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ]),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
          offset: Offset(0, _floatAnim.value), child: child),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) =>
            Transform.scale(scale: _pulseAnim.value, child: child),
        child: Column(children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15), width: 1.5)),
            child: Center(
                child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.security_rounded,
                  color: Color(0xFF2347D4), size: 42),
            )),
          ),
          const SizedBox(height: 16),
          const Text('SecureAttend',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Anti-proxy attendance system',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 13)),
        ]),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms);
  }

  Widget _buildHeadline() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
        ),
        child: const Text('100% Proxy-Free Guarantee',
            style: TextStyle(
                color: Color(0xFF86EFAC),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 12),
      Text('Secure attendance\nfor your university',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5)),
    ]).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildFeatureCarousel() {
    return Column(children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
                        .animate(anim),
                child: child)),
        child: Container(
          key: ValueKey(_currentFeature),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_features[_currentFeature].icon,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_features[_currentFeature].title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_features[_currentFeature].desc,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65), fontSize: 12)),
                ])),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              _features.length,
              (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == _currentFeature ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentFeature
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ))),
    ]).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildButtons() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2347D4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.login_rounded, size: 20),
            SizedBox(width: 8),
            Text('Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegistrationScreen())),
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side:
                  BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.how_to_reg_rounded, size: 20),
            SizedBox(width: 8),
            Text('Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ]).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildFooter() {
    return Column(children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['Encrypted', 'Secure', 'Verified']
              .asMap()
              .entries
              .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        [
                          Icons.lock_outline,
                          Icons.shield_outlined,
                          Icons.verified_outlined
                        ][e.key],
                        size: 11,
                        color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 3),
                    Text(e.value,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10)),
                    if (e.key < 2)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('·',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3)))),
                  ]))
              .toList()),
      const SizedBox(height: 6),
      Text('v1.0.0 — For authorized students only',
          style:
              TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10)),
    ]).animate(delay: 600.ms).fadeIn();
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  const _Feature(this.icon, this.title, this.desc);
}
