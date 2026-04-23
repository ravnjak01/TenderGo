import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/widgets/common/auth_scaffold.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/inputs/auth_widget.dart';

class MobileResetPasswordScreen extends StatefulWidget {
  const MobileResetPasswordScreen({super.key});

  @override
  State<MobileResetPasswordScreen> createState() =>
      _MobileResetPasswordScreenState();
}

class _MobileResetPasswordScreenState extends State<MobileResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _hasResolvedContext = false;

  String _token = '';
  String _email = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasResolvedContext) return;
    _hasResolvedContext = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _token = (args['token'] ?? '').toString();
      _email = (args['email'] ?? '').toString();
    }

    if (_token.isEmpty || _email.isEmpty) {
      final uri = Uri.base;
      _token = _token.isEmpty
          ? Uri.decodeComponent(uri.queryParameters['token'] ?? '')
          : _token;
      _email = _email.isEmpty ? (uri.queryParameters['email'] ?? '') : _email;
    }
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_token.isEmpty || _email.isEmpty) {
      SnackbarHelper.show(
        context,
        'Reset link is invalid or missing required data.',
        isError: true,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.resetPassword(
      ResetPasswordRequest(
        email: _email,
        token: _token,
        newPassword: _newPasswordController.text,
      ),
    );

    if (!mounted) return;

    if (result.success) {
      SnackbarHelper.show(context, 'Password successfully reset.');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      return;
    }

    SnackbarHelper.show(context, result.message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final hasValidContext = _token.isNotEmpty && _email.isNotEmpty;

    return AuthScaffold(
      maxWidth: 460,
      cardPadding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Enter your new password below.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
            if (!hasValidContext) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error),
                ),
                child: const Text(
                  'Missing token or email. Open reset password from the link sent to your inbox.',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AuthField(
              label: 'New Password',
              hint: 'Enter new password',
              controller: _newPasswordController,
              obscure: _hideNewPassword,
              showToggle: true,
              onToggle: () => setState(() {
                _hideNewPassword = !_hideNewPassword;
              }),
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
            AuthField(
              label: 'Confirm Password',
              hint: 'Confirm new password',
              controller: _confirmPasswordController,
              obscure: _hideConfirmPassword,
              showToggle: true,
              onToggle: () => setState(() {
                _hideConfirmPassword = !_hideConfirmPassword;
              }),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                ),
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
