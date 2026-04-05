import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/app_state_service.dart';
import '../services/network_service.dart';
import 'dashboard_screen.dart';
import 'registration_screen.dart';
import 'admin_dashboard_screen.dart';
import 'teacher_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _rollValid = false;
  bool _passValid = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _rollController.addListener(() =>
        setState(() => _rollValid = _rollController.text.trim().length >= 5));
    _passwordController.addListener(() =>
        setState(() => _passValid = _passwordController.text.length >= 6));
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRoll = prefs.getString('saved_roll') ?? '';
    final savedPass = prefs.getString('saved_password') ?? '';
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember && savedRoll.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _rollController.text = savedRoll;
        _passwordController.text = savedPass;
        _rollValid = savedRoll.length >= 5;
        _passValid = savedPass.length >= 6;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_roll', _rollController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_roll');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_rollController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Please enter your roll number and password', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    
    final result = await AuthService.signIn(
      rollNumber: _rollController.text.trim().toUpperCase(),
      password: _passwordController.text.trim(),
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (result == AuthResult.success) {
      await _saveCredentials();
      // Read role directly from AppStateService (most reliable source after signIn)
      final appUser = AppStateService().currentUser;
      final userData = await AuthService.getCachedUserData();
      if (!mounted) return;
      
      Widget destination;
      final role = appUser?['role'] ?? userData['role'] ?? 'student';
      
      if (role == 'admin') {
        destination = const AdminDashboardScreen();
      } else if (role == 'teacher') {
        destination = const TeacherDashboardScreen();
      } else {
        destination = const DashboardScreen();
      }

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => destination),
          (_) => false);
    } else {
      _showSnack(result.message, isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSignIn = _rollValid && _passValid;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  _buildCard(canSignIn),
                  const SizedBox(height: 20),
                  _buildSignInButton(canSignIn),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildFeaturePills(),
                  const SizedBox(height: 28),
                  _buildRegisterRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero header ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 36),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              const Text('SECURE ATTENDANCE 🎓',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5)),
              const SizedBox(height: 12),
              const Text('Welcome Back',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 10),
              const Text('Institutional Access Required',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w500))
                  .animate(delay: 100.ms)
                  .fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main card ───────────────────────────────────────────────────────────────
  Widget _buildCard(bool canSignIn) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Roll number
            _fieldLabel('Roll Number'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _rollController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(12),
              ],
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500),
              decoration: _inputDec(
                hint: "Enter your roll number",
                icon: Icons.badge_outlined,
                isValid: _rollValid,
                hasText: _rollController.text.isNotEmpty,
              ),
            ),
            const SizedBox(height: 16),

            // Password
            _fieldLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePass,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500),
              decoration: _inputDec(
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                isValid: _passValid,
                hasText: _passwordController.text.isNotEmpty,
              ).copyWith(
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscurePass = !_obscurePass),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF9CA3AF)),
                  ),
                ),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
            const SizedBox(height: 12),

            // Remember me + Forgot password row
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _rememberMe
                            ? const Color(0xFF0056B3)
                            : Colors.transparent,
                        border: Border.all(
                          color: _rememberMe
                              ? const Color(0xFF0056B3)
                              : const Color(0xFFBDBDBD),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _rememberMe
                          ? const Icon(Icons.check_rounded,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 7),
                    const Text('Remember me',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showForgotPassword,
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0056B3),
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: 150.ms).fadeIn(duration: 500.ms);
  }

  // ── Sign in button ──────────────────────────────────────────────────────────
  Widget _buildSignInButton(bool canSignIn) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSignIn ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          foregroundColor: canSignIn ? Colors.white : const Color(0xFF94A3B8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(canSignIn ? 'CONTINUE' : 'SIGN IN',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ]),
      ),
    ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildDivider() {
    return Row(children: [
      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('secured by university protocol',
            style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF9CA3AF).withValues(alpha: 0.8))),
      ),
      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
    ]);
  }

  // ── Feature pills ───────────────────────────────────────────────────────────
  Widget _buildFeaturePills() {
    final features = [
      (Icons.wifi_lock_rounded, 'LAN Sync'),
      (Icons.qr_code_scanner_rounded, 'QR Secure'),
      (Icons.verified_user_rounded, 'Anti-Proxy'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features
          .map((f) => Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(f.$1, size: 14, color: const Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Text(f.$2,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600)),
                ]))
          .toList(),
    ).animate(delay: 350.ms).fadeIn();
  }

  Widget _buildRegisterRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("Don't have an account? ",
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
      GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
        child: const Text('Register Now',
            style: TextStyle(
                color: Color(0xFF0056B3),
                fontWeight: FontWeight.w900,
                fontSize: 13)),
      ),
    ]);
  }

  Widget _fieldLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827)));

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    required bool isValid,
    required bool hasText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon,
            size: 18,
            color: hasText
                ? (isValid ? const Color(0xFF059669) : const Color(0xFFEF4444))
                : const Color(0xFF6B7280)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }
}

// ── Forgot password bottom sheet ─────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _rollController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _done = false;
  String? _error;
  String? _emailHint;
  String? _generatedOtp;

  @override
  void dispose() {
    _rollController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Step 1: Find account and "send" OTP to college email
  Future<void> _sendOtp() async {
    final roll = _rollController.text.trim().toUpperCase();
    if (roll.length < 5) {
      setState(() => _error = "Enter your roll number");
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Check account exists
    final data = await AuthService.getCachedUserData();
    final storedRoll = data['rollNumber'] ?? '';
    final email = data['email'] ?? '';

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (storedRoll.toUpperCase() != roll) {
      setState(() {
        _isLoading = false;
        _error = "Roll number not found. Please register first.";
      });
      return;
    }

    // Generate 6-digit OTP (in real app, send via email API)
    _generatedOtp =
        (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // Build masked email hint e.g. sa***@gcu.edu.in
    String hint = email;
    if (email.contains('@')) {
      final parts = email.split('@');
      final local = parts[0];
      final masked = local.length > 2
          ? '${local.substring(0, 2)}${'*' * (local.length - 2)}'
          : local;
      hint = '$masked@${parts[1]}';
    }

    setState(() {
      _isLoading = false;
      _otpSent = true;
      _emailHint = hint;
      _error = null;
    });
  }

  // Step 2: Verify OTP
  Future<void> _verifyOtp() async {
    final entered = _otpController.text.trim();
    if (entered.length != 6) {
      setState(() => _error = "Enter the 6-digit OTP");
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (entered == _generatedOtp) {
      setState(() {
        _isLoading = false;
        _otpVerified = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = "Incorrect OTP. Check your college email and try again.";
      });
    }
  }

  // Step 3: Reset password
  Future<void> _resetPassword() async {
    final roll = _rollController.text.trim().toUpperCase();
    final newPass = _newPassController.text;
    final confirm = _confirmController.text;

    if (newPass.length < 8) {
      setState(() => _error = "Password must be at least 8 characters");
      return;
    }
    if (!newPass.contains(RegExp(r'[A-Z]'))) {
      setState(() => _error = "Add at least one uppercase letter");
      return;
    }
    if (!newPass.contains(RegExp(r'[0-9]'))) {
      setState(() => _error = "Add at least one number");
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result =
        await AuthService.resetPassword(rollNumber: roll, newPassword: newPass);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result) {
      setState(() => _done = true);
    } else {
      setState(() => _error = "Reset failed. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            if (_done)
              ..._buildSuccess()
            else if (_otpVerified)
              ..._buildNewPassword()
            else if (_otpSent)
              ..._buildOtpVerify()
            else
              ..._buildRollInput(),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Enter roll number ───────────────────────────────────────────────
  List<Widget> _buildRollInput() => [
        _sheetHeader(Icons.lock_reset_rounded, 'Reset Password',
            "We'll send an OTP to your college email"),
        const SizedBox(height: 20),
        if (_error != null) _errorBox(),
        _sheetField(
            controller: _rollController,
            hint: 'Roll Number (e.g. 23BEIS151)',
            icon: Icons.badge_outlined,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(12),
            ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.email_outlined,
                size: 14, color: Color(0xFF0056B3)),
            SizedBox(width: 8),
            Expanded(
                child: Text(
              'An OTP will be sent to your registered college email (Outlook). Check your inbox.',
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF1E3A8A), height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        _actionButton('Send OTP to College Email', Icons.send_rounded,
            _isLoading, _sendOtp),
      ];

  // ── Step 2: Enter OTP ───────────────────────────────────────────────────────
  List<Widget> _buildOtpVerify() => [
        _sheetHeader(Icons.mark_email_read_rounded, 'Check Your Email',
            'OTP sent to $_emailHint'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outlined,
                size: 14, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
              'OTP sent to ${_emailHint ?? ''}\nOpen Outlook and check your inbox.',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF15803D), height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 14),
        if (_error != null) _errorBox(),
        // OTP input — large digits
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: Color(0xFF0056B3)),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                fontWeight: FontWeight.w800),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF0056B3), width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Didn't receive it? ",
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          GestureDetector(
            onTap: () => setState(() {
              _otpSent = false;
              _error = null;
            }),
            child: const Text('Resend OTP',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0056B3))),
          ),
        ]),
        const SizedBox(height: 16),
        _actionButton(
            'Verify OTP', Icons.verified_rounded, _isLoading, _verifyOtp),
      ];

  // ── Step 3: New password ────────────────────────────────────────────────────
  List<Widget> _buildNewPassword() => [
        _sheetHeader(Icons.lock_rounded, 'Set New Password',
            'OTP verified — create your new password'),
        const SizedBox(height: 16),
        if (_error != null) _errorBox(),
        _sheetField(
            controller: _newPassController,
            hint: 'New Password (min 8 chars)',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureNew,
            toggleObscure: () => setState(() => _obscureNew = !_obscureNew)),
        const SizedBox(height: 10),
        _sheetField(
            controller: _confirmController,
            hint: 'Confirm New Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            toggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm)),
        const SizedBox(height: 8),
        // Mini requirements
        _req('At least 8 characters', _newPassController.text.length >= 8),
        _req('One uppercase letter',
            _newPassController.text.contains(RegExp(r'[A-Z]'))),
        _req('One number', _newPassController.text.contains(RegExp(r'[0-9]'))),
        const SizedBox(height: 16),
        _actionButton(
            'Update Password', Icons.save_rounded, _isLoading, _resetPassword),
      ];

  // ── Success ─────────────────────────────────────────────────────────────────
  List<Widget> _buildSuccess() => [
        Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF059669), size: 34)),
        const SizedBox(height: 14),
        const Text('Password Updated!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF))),
        const SizedBox(height: 6),
        const Text("You can now sign in with your new password.",
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0),
            child: const Text('Back to Sign In',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ];

  // ── Reusable widgets ────────────────────────────────────────────────────────
  Widget _sheetHeader(IconData icon, String title, String subtitle) =>
      Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFFFFFFFF), size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFFFFF))),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ])),
      ]);

  Widget _errorBox() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFFFCEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF09595))),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFA32D2D), size: 14),
            const SizedBox(width: 7),
            Expanded(
                child: Text(_error!,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFA32D2D)))),
          ]),
        ),
      );

  Widget _req(String text, bool met) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 12,
              color: met ? const Color(0xFF059669) : const Color(0xFFD1D5DB)),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  color:
                      met ? const Color(0xFF059669) : const Color(0xFF9CA3AF))),
        ]),
      );

  Widget _actionButton(
          String label, IconData icon, bool loading, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onTap,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Icon(icon, size: 17),
          label: Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0),
        ),
      );

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        inputFormatters: inputFormatters,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
          prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, size: 17, color: const Color(0xFF9CA3AF))),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: toggleObscure != null
              ? GestureDetector(
                  onTap: toggleObscure,
                  child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 17,
                          color: const Color(0xFF9CA3AF))))
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      );
}
