import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/inputs/custom_auth_field.dart';
import 'package:tendergo/shared/widgets/common/auth_scaffold.dart';

class AdminResetPasswordScreen extends StatefulWidget {
  const AdminResetPasswordScreen({super.key});

  @override
  State<AdminResetPasswordScreen> createState() =>
      _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState extends State<AdminResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _hasResolvedContext = false;
  String _email = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasResolvedContext) return;
    _hasResolvedContext = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _email = (args['email'] ?? '').toString();
    }
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final codeInput = _codeController.text.trim();

    if (codeInput.isEmpty || _email.isEmpty) {
      SnackbarHelper.show(
        context,
        'Missing required data. Please request a new code.',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.resetPassword(
      ResetPasswordRequest(
        email: _email,
        code: codeInput,
        newPassword: _passwordController.text,
      ),
    );

    if (!mounted) return;

    if (result.success) {
      SnackbarHelper.show(context, "Password successfully reset");
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      SnackbarHelper.show(context, result.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidEmail = _email.isNotEmpty;
    final auth = context.watch<AuthProvider>();

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Stack(
      children: [
        // 1. Glavni sadržaj (tvoja kartica i pozadina)
        AuthScaffold(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [   
                const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter the verification code sent to your email and your new password.',
                  style: TextStyle(color: Colors.grey),
                ),
                
                if (!hasValidEmail) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'Missing email address. Please go back and try again.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 25),

                CustomTextField(
                  controller: _codeController,
                  label: 'Verification Code',
                  hint: 'Enter your code',
                  showLabel: false,
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Verification code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'Enter new password',
                  showLabel: false,
                  prefixIcon: Icons.lock_outline,
                  isPasswordField: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'New password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm new password',
                  showLabel: false,
                  prefixIcon: Icons.lock_clock_outlined,
                  isPasswordField: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (hasValidEmail && !auth.isLoading) ? _resetPassword : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF2a5298),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Color(0xFF2a5298),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. DUGME VAN KARTICE: Pozicionirano skroz gore lijevo na ekranu
        Positioned(
          top: isDesktop ? 40 : 20,  // Veći razmak na desktopu, manji na mobilnom zbog status bara
          left: isDesktop ? 40 : 20,
          child: CustomBackButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}