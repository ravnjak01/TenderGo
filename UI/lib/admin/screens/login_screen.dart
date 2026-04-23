import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/validators/validators.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/admin/widgets/common/auth_scaffold.dart';
import 'package:tendergo/admin/widgets/error_banner.widget.dart';
import 'package:tendergo/shared/widgets/inputs/auth_widget.dart';

class AdminLoginScreen extends StatefulWidget {

  const AdminLoginScreen({super.key,});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _hidePassword = true;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

 void _handleLogin() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  if (!mounted) return;
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final success = await context.read<AuthProvider>().login(
    _emailController.text.trim(),
    _passwordController.text,
  );

  if (!mounted) return;

  if (!success) {
    setState(() {
      _isLoading = false;
      _errorMessage =
          'Sign in not successful. Please check your credentials.';
    });
    return;
  }
  Navigator.of(context).pushReplacementNamed(AppRoutes.tenderList);
}
 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      maxWidth: 420,
      cardPadding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 30),
            AuthField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!isValidEmail(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            AuthField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter password',
              obscure: _hidePassword,
              showToggle: true,
              onToggle: () => setState(() => _hidePassword = !_hidePassword),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 15),
              ErrorBannerWidget(
                message: _errorMessage!,
                onClose: () => setState(() => _errorMessage = null),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D4DB5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/registration'),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}