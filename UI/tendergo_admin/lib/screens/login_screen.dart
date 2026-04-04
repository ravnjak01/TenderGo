import 'package:flutter/material.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/screens/tenders_list_screen.dart';
import 'package:tendergo_admin/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  void _handleLogin() async {

if(_formKey.currentState!.validate()){
  
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = await widget.authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
  if (mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TenderListScreen(tenderService: Provider.of<TenderProvider>(context, listen: false).service)),
    );
  }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Sign in not successful. Please check your credentials.";
      });
    }
  }
  }

 bool _isValidEmail(String email) {
  return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
      .hasMatch(email);
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLoginAndRegister, 
      body: Center(
        child: SingleChildScrollView( 
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), 
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Zauzima samo koliko mu treba prostora
              children: [
                const Text(
                  "Login",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary,),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction, 
                  decoration:  InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    enabledBorder: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                       borderSide: BorderSide(
                        color: _isValidEmail(_emailController.text) ? Colors.green : Colors.blue,
                     ),
                     ),
                  ),
                  onChanged: (value) {
                 setState(() {});
                    },

                  validator: (value){
                    if(value == null || value.isEmpty){
                      return "Please enter your email";
                    }
                    if(!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)){
                      return "Please enter a valid email address";
                    }
                    return null;  
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return "Please enter your password";
                      }
                      if(value.length < 8){
                        return "Password must be at least 8 characters";
                      }
                      return null;  
                    },
                  obscureText: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 15),
                  Text(_errorMessage!, 
                       style: const TextStyle( color: AppColors.error, fontSize: 13)),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    }  ,
                    child: const Text("Forgot Password?", style: TextStyle(fontSize: 14,color:Colors.blue)),
                  ),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D4DB5),

                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Sign In", style: TextStyle(fontSize: 16)),
                      ),
                      Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? "),
                        GestureDetector(
                         onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/registration',
                        );
                      },
                      child: Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                        ),
                      ],
                      )
              ],
            ),),
          ),
        ),
      ),
    );
  }
}