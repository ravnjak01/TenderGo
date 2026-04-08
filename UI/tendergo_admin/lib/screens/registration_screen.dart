import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  final AuthService authService;
  const RegistrationScreen({super.key, required this.authService});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _fnameController   = TextEditingController();
  final _lnameController   = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _confirmController    = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;

  static const Color _midBlue    = Color(0xFF2A4BAD);
  static const Color _btnBlue    = Color(0xFF2D4DB5);
  static const Color _linkBlue   = Color(0xFF4472C4);

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      _showSnack("Passwords don't match!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.authService.register(
      _emailController.text.trim(),
      _passwordController.text,
      _fnameController.text.trim(),
      _lnameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnack("Account created successfully!");
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _showSnack("Registration failed. Please try again.", isError: true);
    }
  }

void _showSnack(String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      width: 400,
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
      behavior: SnackBarBehavior.floating, // Čini da SnackBar lebdi
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
      elevation: 6,
      dismissDirection: DismissDirection.horizontal, // Dozvoljava swipe-to-dismiss
    ),
  );
}
  // ── reusable field builder ────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    bool? showToggle,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFD1D5DB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFD1D5DB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: _midBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1),
            ),
            suffixIcon: showToggle == true
                ? IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF9CA3AF)),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // deep blue background from screenshot
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A3A6B), Color(0xFF1E4DB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 12))
                  ],
                ),
                child: Row(
                  children: [
                    // ── LEFT PANEL ───────────────────────────────────────
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(48),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A3A6B), Color(0xFF2A5AC9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft:    Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Join our platform and start\nexploring tenders easily.',
                              style: TextStyle(
                                color: Color(0xFFBFD3F5),
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── RIGHT PANEL ──────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // First Name
                              _buildField(
                                label: 'First Name',
                                hint: 'Enter first name',
                                controller: _fnameController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'First name is required'
                                    : null,
                              ),

                              // Last Name
                              _buildField(
                                label: 'Last Name',
                                hint: 'Enter last name',
                                controller: _lnameController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Last name is required'
                                    : null,
                              ),

                              // Email
                              _buildField(
                                label: 'Email',
                                hint: 'Enter email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Email is required';
                                  if (!RegExp(
                                         r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                      .hasMatch(v))
                                    return 'Please enter a valid email address';
                                  return null;
                                },
                              ),

                              // Password
                              _buildField(
                                label: 'Password',
                                hint: 'Enter password',
                                controller: _passwordController,
                                obscure: _obscurePassword,
                                showToggle: true,
                                onToggle: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Password is required';
                                  if (v.length < 8)
                                    return 'Min 8 characters';
                                  return null;
                                },
                              ),

                              // Confirm Password
                              _buildField(
                                label: 'Confirm Password',
                                hint: 'Confirm password',
                                controller: _confirmController,
                                obscure: _obscureConfirm,
                                showToggle: true,
                                onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Please confirm your password'
                                    : null,
                              ),

                              const SizedBox(height: 8),

                              // Create Account button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleRegistration,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _btnBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('Create Account'),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Sign in link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 13),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacementNamed(context, '/login');
                                    },
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: _linkBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }
}