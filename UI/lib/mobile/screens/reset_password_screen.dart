import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ili paket koji koristiš za context.read
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/widgets/common/auth_scaffold.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/inputs/auth_widget.dart';
import 'package:tendergo/shared/widgets/inputs/custom_auth_field.dart'; // Uvezi fajl sa dugmićima

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

  // VIŠEKRATNE VARIJABLE ZA HIDE/SHOW SU UKLONJENE JER IM STANJEM SADA UPRAVLJA WIDGET INTERNO
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
    final auth = context.watch<AuthProvider>(); // Pretpostavka za loading stanje dugmeta

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

            // 1. NOVO POLJE ZA NOVU LOZINKU
            CustomTextField(
              label: 'New Password',
              hint: 'Enter new password',
              controller: _newPasswordController,
              isPasswordField: true,
              prefixIcon: Icons.lock_outline,
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

            // 2. NOVO POLJE ZA POTVRDU LOZINKE
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

            const SizedBox(height: 8),

            // 3. DOVRŠENO INPUT DUGME (Dodano pošto je falio kraj u tvom kodu)
            AuthSubmitButton(
              label: 'Reset Password',
              isLoading: auth.isLoading,
              onPressed: hasValidContext ? _handleResetPassword : null,
            ),
          ],
        ),
      ),
    );
  }
}