import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rollController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _selectedDept;
  String? _selectedSem;
  String? _selectedSection;

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  int _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  bool _rollValid = false;
  bool _nameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmValid = false;

  final List<String> _departments = [
    'Computer Science Engineering',
    'Information Technology',
    'Electronics & Communication',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
    'Artificial Intelligence & ML',
  ];

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _rollController.addListener(() =>
        setState(() => _rollValid = _rollController.text.trim().length >= 5));
    _nameController.addListener(() {
      final v = _nameController.text.trim();
      setState(() => _nameValid = v.length >= 3 && v.contains(' '));
    });
    _emailController.addListener(() {
      final emailRegex = RegExp(
          r'^[a-zA-Z0-9][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      setState(() =>
          _emailValid = emailRegex.hasMatch(_emailController.text.trim()));
    });
    _passwordController.addListener(_validatePassword);
    _confirmController.addListener(() => setState(() => _confirmValid =
        _confirmController.text == _passwordController.text &&
            _confirmController.text.isNotEmpty));
  }

  @override
  void dispose() {
    _rollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final v = _passwordController.text;
    int strength = 0;
    if (v.length >= 8) strength++;
    if (v.contains(RegExp(r'[A-Z]'))) strength++;
    if (v.contains(RegExp(r'[0-9]'))) strength++;
    if (v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;
    String label;
    Color color;
    switch (strength) {
      case 0:
      case 1:
        label = 'Weak';
        color = const Color(0xFFEF4444);
        break;
      case 2:
        label = 'Fair';
        color = const Color(0xFFF59E0B);
        break;
      case 3:
        label = 'Good';
        color = const Color(0xFF3B82F6);
        break;
      default:
        label = 'Strong';
        color = const Color(0xFF22C55E);
    }
    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = v.isEmpty ? '' : label;
      _passwordStrengthColor = color;
      _passwordValid = strength >= 3 && v.length >= 8;
    });
  }

  int get _filledFields {
    return [
      _rollValid,
      _nameValid,
      _emailValid,
      _passwordValid,
      _confirmValid,
      _selectedDept != null,
      _selectedSem != null,
      _selectedSection != null
    ].where((v) => v).length;
  }

  double get _formProgress => _filledFields / 8;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDept == null ||
        _selectedSem == null ||
        _selectedSection == null) {
      _showSnack('Please select department, semester and section',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await AuthService.register(
      rollNumber: _rollController.text.trim().toUpperCase(),
      fullName: _nameController.text.trim(),
      department: _selectedDept!,
      yearSection: '$_selectedSem - Section $_selectedSection',
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess) {
      _showSnack('Account created successfully!', isError: false);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
          isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar(),
                    const SizedBox(height: 20),
                    _sectionLabel('Academic information'),
                    const SizedBox(height: 10),
                    _buildField(
                        controller: _rollController,
                        label: 'Roll Number',
                        hint: 'e.g. 23BEIS151',
                        icon: Icons.badge_outlined,
                        isValid: _rollValid,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')),
                          LengthLimitingTextInputFormatter(12)
                        ],
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v == null || v.trim().length < 5
                            ? 'Enter a valid roll number'
                            : null,
                        helperText: 'Your unique student ID from your ID card'),
                    const SizedBox(height: 14),
                    _buildDropdown(
                        label: 'Department',
                        hint: 'Select Department',
                        value: _selectedDept,
                        items: _departments,
                        onChanged: (v) => setState(() => _selectedDept = v)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: _buildDropdown(
                              label: 'Semester',
                              hint: 'Select Sem',
                              value: _selectedSem,
                              items: _semesters,
                              onChanged: (v) =>
                                  setState(() => _selectedSem = v))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDropdown(
                              label: 'Section',
                              hint: 'Select',
                              value: _selectedSection,
                              items: _sections,
                              onChanged: (v) =>
                                  setState(() => _selectedSection = v))),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel('Personal information'),
                    const SizedBox(height: 10),
                    _buildField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'e.g. Sara Firdose',
                        icon: Icons.person_outline_rounded,
                        isValid: _nameValid,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter your full name';
                          if (!v.trim().contains(' '))
                            return 'Enter first and last name';
                          return null;
                        },
                        helperText: 'As it appears on your college ID card'),
                    const SizedBox(height: 14),
                    _buildField(
                        controller: _emailController,
                        label: 'College Email',
                        hint: 'e.g. 23beis151@gcu.edu.in',
                        icon: Icons.email_outlined,
                        isValid: _emailValid,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter your college email';
                          if (!RegExp(
                                  r'^[a-zA-Z0-9][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(v.trim())) return 'Enter a valid email';
                          return null;
                        },
                        helperText: 'Used for attendance notifications'),
                    const SizedBox(height: 24),
                    _sectionLabel('Set password'),
                    const SizedBox(height: 10),
                    _buildPasswordField(),
                    const SizedBox(height: 14),
                    _buildField(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        isValid: _confirmValid,
                        obscureText: _obscureConfirm,
                        suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            child: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: const Color(0xFF9CA3AF))),
                        validator: (v) => v != _passwordController.text
                            ? 'Passwords do not match'
                            : null),
                    const SizedBox(height: 28),
                    _buildRegisterButton(),
                    const SizedBox(height: 16),
                    _buildSignInRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF2347D4),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(children: [
                const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white60, size: 16),
                const SizedBox(width: 4),
                Text('Back',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 14),
            const Text('Create Account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5))
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.2),
            const SizedBox(height: 4),
            Text('Register with your college credentials',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13))
                .animate(delay: 100.ms)
                .fadeIn(),
          ]),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Form completion',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text('$_filledFields / 8 fields',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2347D4),
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _formProgress,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: AlwaysStoppedAnimation<Color>(_formProgress == 1.0
              ? const Color(0xFF22C55E)
              : const Color(0xFF2347D4)),
          minHeight: 6,
        ),
      ),
    ]);
  }

  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: const Color(0xFF2347D4),
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151))),
    ]);
  }

  Widget _buildPasswordField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Min 8 chars, uppercase, number, symbol',
          icon: Icons.lock_outline_rounded,
          isValid: _passwordValid,
          obscureText: _obscurePass,
          suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF9CA3AF))),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter a password';
            if (v.length < 8) return 'Minimum 8 characters required';
            if (!v.contains(RegExp(r'[A-Z]')))
              return 'Add at least one uppercase letter';
            if (!v.contains(RegExp(r'[0-9]'))) return 'Add at least one number';
            return null;
          }),
      if (_passwordController.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          ...List.generate(
              4,
              (i) => Expanded(
                  child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                      decoration: BoxDecoration(
                          color: i < _passwordStrength
                              ? _passwordStrengthColor
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2))))),
          const SizedBox(width: 8),
          Text(_passwordStrengthLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _passwordStrengthColor)),
        ]),
        const SizedBox(height: 6),
        _req('At least 8 characters', _passwordController.text.length >= 8),
        _req('One uppercase letter (A–Z)',
            _passwordController.text.contains(RegExp(r'[A-Z]'))),
        _req('One number (0–9)',
            _passwordController.text.contains(RegExp(r'[0-9]'))),
      ],
    ]);
  }

  Widget _req(String text, bool met) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 13,
              color: met ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB)),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  color:
                      met ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF))),
        ]),
      );

  Widget _buildRegisterButton() {
    final allValid = _rollValid &&
        _nameValid &&
        _emailValid &&
        _passwordValid &&
        _confirmValid &&
        _selectedDept != null &&
        _selectedSem != null &&
        _selectedSection != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
            backgroundColor:
                allValid ? const Color(0xFF2347D4) : const Color(0xFF9CA3AF),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.how_to_reg_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                    allValid ? 'Create Account' : 'Fill all fields to continue',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
      ),
    );
  }

  Widget _buildSignInRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Already have an account? ',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Sign In',
                  style: TextStyle(
                      color: Color(0xFF2347D4),
                      fontWeight: FontWeight.w700,
                      fontSize: 14))),
        ],
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isValid,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    final hasText = controller.text.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const Text(' *',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
          prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon,
                  size: 18,
                  color: hasText
                      ? (isValid
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444))
                      : const Color(0xFF9CA3AF))),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12), child: suffixIcon)
              : (hasText
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                          isValid
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 18,
                          color: isValid
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444)))
                  : null),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: hasText
                      ? (isValid
                          ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                          : const Color(0xFFEF4444).withValues(alpha: 0.5))
                      : const Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isValid
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF2347D4),
                  width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444))),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          helperText: helperText,
          helperStyle: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
        ),
      ),
    ]);
  }

  Widget _buildDropdown(
      {required String label,
      required String hint,
      required String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const Text(' *',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF9CA3AF)),
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2347D4), width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
      ),
    ]);
  }
}
