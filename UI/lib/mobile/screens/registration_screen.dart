import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/utils/validators/validators.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/common/auth_scaffold.dart';
import 'package:tendergo/shared/widgets/inputs/custom_auth_field.dart';

class MobileRegistrationScreen extends StatefulWidget {
  const MobileRegistrationScreen({super.key});

  @override
  State<MobileRegistrationScreen> createState() => _MobileRegistrationScreenState();
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
            const Center(
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          CustomTextField(
                controller: _confirmController,
                label: 'Confirm Password',
                hint: 'Confirm password',
                isPasswordField: true, // <- Ovo mijenja obscure, showToggle i onToggle
                prefixIcon: Icons.lock_clock_outlined, // Opcionalno, dodaj ikonicu ako želiš
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