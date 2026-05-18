import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
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

  late String token;
  late String email;

  final _isLoading = false;

  @override
  void initState() {
    super.initState();

    final uri = Uri.base; 
    token = Uri.decodeComponent(uri.queryParameters['token'] ?? '');
    email = uri.queryParameters['email'] ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Pozivamo providera
    final result = await authProvider.resetPassword(
      ResetPasswordRequest(
        token: token,
        newPassword: _passwordController.text,
        email: email,
      ),
    );

    if (!mounted) return;

    if (result.success) {
      SnackbarHelper.show(context, "Password successfully reset");
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      // Koristimo tvoj shared snackbar za grešku
      SnackbarHelper.show(context, result.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
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
              'Enter your new password below.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            CustomTextField(
              controller: _passwordController,
              label: 'New Password',
              showLabel: false,
              prefixIcon: Icons.lock_outline,
              isPasswordField: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF2a5298),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reset Password'),
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
    );
  }
}
