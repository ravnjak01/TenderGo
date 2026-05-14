import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/utils/validators/validators.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/admin/widgets/common/auth_scaffold.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/inputs/auth_widget.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() =>
      _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  Future<void> _handleForgotPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await context.read<AuthProvider>().sendForgotPasswordEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    SnackbarHelper.show(context, result.message, isError: !result.success);

    if (!result.success) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
              'Forgot Password',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your email and we will send you a link to reset your password.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            AuthField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                if (!isValidEmail(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, auth, _) => AuthSubmitButton(
                label: 'Send Reset Link',
                isLoading: auth.isLoading,
                onPressed: _handleForgotPassword,
              ),
            ),
            const SizedBox(height: 15),
            AuthNavLink(
              linkText: 'Back to Login',
              onTap: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
