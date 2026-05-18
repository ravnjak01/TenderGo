import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/validators/validators.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/widgets/inputs/auth_widget.dart';
import 'package:tendergo/shared/widgets/inputs/custom_auth_field.dart';
import 'package:tendergo/shared/widgets/common/auth_scaffold.dart';
import 'package:tendergo/shared/widgets/common/error_banner_widget.dart';

class AdminLoginScreen extends StatefulWidget {

  const AdminLoginScreen({super.key,});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

 Future<void> _handleLogin() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() => _errorMessage = null);

  final success = await context.read<AuthProvider>().login(
    _emailController.text.trim(),
    _passwordController.text,
  );

  if (!mounted) return;

  if (!success) {
    setState(() {
      _errorMessage = 'Sign in not successful. Please check your credentials.';
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
            CustomTextField(
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
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter password',
              isPasswordField: true,
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
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.forgotPassword),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<AuthProvider>(
              builder: (context, auth, _) => AuthSubmitButton(
                label: 'Sign In',
                isLoading: auth.isLoading,
                onPressed: _handleLogin,
              ),
            ),
            const SizedBox(height: 16),
            AuthNavLink(
              prompt: "Don't have an account? ",
              linkText: 'Sign up',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.registration),
            ),
          ],
        ),
      ),
    );
  }
}