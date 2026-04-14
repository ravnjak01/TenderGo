import 'package:flutter/material.dart';
import 'package:tendergo_admin/services/auth_service.dart'; // Prilagodi putanju
import 'package:tendergo_admin/models/ui/auth_result.dart';   // Prilagodi putanju
import 'package:tendergo_admin/widgets/common/app_text_field.dart';
import 'package:tendergo_admin/widgets/common/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthService authService;

  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Poziv metode iz servisa koju si naveo
    AuthResult result = await widget.authService.forgotPassword(email);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Prikazujemo poruku korisniku (bez obzira na success, jer je poruka generička)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      // Ako je uspješno (200 OK), vraćamo ga na login nakon kratke pauze
      if (result.success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forgot Password',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your email and we will send you a link to reset your password.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 25),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF2a5298),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
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
    );
  }
}