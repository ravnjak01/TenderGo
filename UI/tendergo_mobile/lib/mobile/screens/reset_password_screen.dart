import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/routes/routes.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/mobile/widgets/common/auth_scaffold.dart';
import 'package:tendergo/mobile/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/mobile/widgets/inputs/auth_widget.dart';
import 'package:tendergo/mobile/widgets/inputs/custom_auth_field.dart';

const _passwordRequirementMessage =
    'Use 8+ chars with upper, lower, number, and symbol.';

String? _validatePasswordRequirements(String? value) {
  if (value == null || value.isEmpty) {
    return 'New password is required';
  }
  final hasRequiredLength = value.length >= 8;
  final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
  final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
  final hasDigit = RegExp(r'\d').hasMatch(value);
  final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  if (!hasRequiredLength ||
      !hasUppercase ||
      !hasLowercase ||
      !hasDigit ||
      !hasSymbol) {
    return _passwordRequirementMessage;
  }
  return null;
}

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
  final _codeController = TextEditingController();

  bool _hasResolvedContext = false;
  String _email = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _codeController.dispose();
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
      _email = (args['email'] ?? '').toString();
    }
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final codeInput = _codeController.text.trim();

    if (codeInput.isEmpty || _email.isEmpty) {
      SnackbarHelper.show(
        context,
        'Missing required data. Please try again.',
        isError: true,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.resetPassword(
      ResetPasswordRequest(
        email: _email,
        code: codeInput,
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
    final hasValidEmail = _email.isNotEmpty;
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      maxWidth: 460,
      cardPadding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomBackButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 36.0),
                    child: Center(
                      child: Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Enter the code sent to your email and your new password.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            
            if (!hasValidEmail) ...[
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
                  'Missing email address. Please go back and request a new code.',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: 24),

            CustomTextField(
              label: 'Verification Code',
              hint: 'Enter 6-digit code',
              controller: _codeController,
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
              label: 'New Password',
              hint: 'Enter new password',
              controller: _newPasswordController,
              isPasswordField: true,
              prefixIcon: Icons.lock_outline,
              validator: _validatePasswordRequirements,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                _passwordRequirementMessage,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

            CustomTextField(
              label: 'Confirm Password',
              hint: 'Confirm new password',
              controller: _confirmPasswordController,
              isPasswordField: true,
              prefixIcon: Icons.lock_clock_outlined,
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

            const SizedBox(height: 24),

            AuthSubmitButton(
              label: 'Reset Password',
              isLoading: auth.isLoading,
              onPressed: hasValidEmail ? _handleResetPassword : null,
            ),
          ],
        ),
      ),
    );
  }
}
