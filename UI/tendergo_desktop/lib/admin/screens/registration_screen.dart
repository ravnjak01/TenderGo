import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/inputs/auth_widget.dart';
import 'package:tendergo/shared/widgets/inputs/custom_auth_field.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});

  @override
  State<AdminRegistrationScreen> createState() => _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _fnameController   = TextEditingController();
  final _lnameController   = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _confirmController    = TextEditingController();

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
  
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  final request = RegisterRequest(
    email: _emailController.text.trim(),
    password: _passwordController.text,
    firstName: _fnameController.text.trim(),
    lastName: _lnameController.text.trim(),
  );

  final success = await authProvider.registerUser(request);

  if (!mounted) return;

  if (success) {
    SnackbarHelper.show(context, "Account created successfully!");
    Navigator.pushReplacementNamed(context, '/login');
  } else {
    SnackbarHelper.show(
      context,
      "Registration failed. Please try again.",
      isError: true,
    );
  }
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
                              CustomTextField(
                                label: 'First Name',
                                hint: 'Enter first name',
                                controller: _fnameController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'First name is required'
                                    : null,
                              ),

                              // Last Name
                              CustomTextField(
                                label: 'Last Name',
                                hint: 'Enter last name',
                                controller: _lnameController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Last name is required'
                                    : null,
                              ),

                              // Email
                              CustomTextField(
                                label: 'Email',
                                hint: 'Enter email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                  {
                                    return 'Email is required';
                                  }
                                  if (!RegExp(
                                         r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                      .hasMatch(v))
                                      {
                                    return 'Please enter a valid email address';
                                      }
                                  return null;
                                },
                              ),

                              // Password
                              CustomTextField(
                                label: 'Password',
                                hint: 'Enter password',
                                controller: _passwordController,
                                isPasswordField: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty){
                                    return 'Password is required';
                                  }
                                  if (v.length < 8)
                                  {
                                    return 'Min 8 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Confirm Password
                              CustomTextField(
                                label: 'Confirm Password',
                                hint: 'Confirm password',
                                controller: _confirmController,
                                isPasswordField: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (v != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 8),

                              Consumer<AuthProvider>(
                                builder: (context, auth, _) =>
                                    AuthSubmitButton(
                                  label: 'Create Account',
                                  isLoading: auth.isLoading,
                                  onPressed: _handleRegistration,
                                ),
                              ),

                              const SizedBox(height: 20),

                              AuthNavLink(
                                prompt: 'Already have an account? ',
                                linkText: 'Sign in',
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, '/login'),
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