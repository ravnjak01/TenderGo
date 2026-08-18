import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/routes/routes.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/utils/validators/validators.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/mobile/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/mobile/widgets/common/auth_scaffold.dart';
import 'package:tendergo/mobile/widgets/inputs/custom_auth_field.dart';

const _passwordRequirementMessage =
    'Use 8+ chars with upper, lower, \n number, and symbol.';

String? _validatePasswordRequirements(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
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

class MobileRegistrationScreen extends StatefulWidget {
  const MobileRegistrationScreen({super.key});

  @override
  State<MobileRegistrationScreen> createState() =>
      _MobileRegistrationScreenState();
}

class _MobileRegistrationScreenState extends State<MobileRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final request = RegisterRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    final success = await authProvider.registerUser(request);

    if (!mounted) return;

    if (success) {
      SnackbarHelper.show(context, 'Account created successfully!');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    SnackbarHelper.show(
      context,
      'Registration failed. Please try again.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                      return;
                    }
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 40),
                    child: Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'First Name',
              hint: 'Enter first name',
              controller: _firstNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            CustomTextField(
              label: 'Last Name',
              hint: 'Enter last name',
              controller: _lastNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),
            CustomTextField(
              label: 'Email',
              hint: 'Enter email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!isValidEmail(value)) {
                  return 'Enter a valid email address\n(e.g., example@gmail.com)';
                }
                return null;
              },
            ),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter password',
              isPasswordField: true,
              validator: _validatePasswordRequirements,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                _passwordRequirementMessage,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            CustomTextField(
              controller: _confirmController,
              label: 'Confirm Password',
              hint: 'Confirm password',
              isPasswordField: true,
              prefixIcon: Icons.lock_clock_outlined,
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
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegistration,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.login,
                  ),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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
