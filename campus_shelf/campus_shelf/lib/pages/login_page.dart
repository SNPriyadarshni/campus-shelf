import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'landing_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  final AuthService _authService = AuthService();
  void forgotPassword() async {
  final email = emailController.text.trim();

  if (email.isEmpty) {
    _showError("Enter your email first");
    return;
  }

  String? error = await _authService.sendPasswordResetEmail(email);

  if (error != null) {
    _showError(error);
  } else {
    _showSuccess("Password reset link sent to your email");
  }
}

  void loginUser() async {
    setState(() => loading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      setState(() => loading = false);
      return;
    }

    // Sign in with Firebase
    String? error = await _authService.signInWithEmailAndPassword(email, password);
    
    if (error != null) {
      _showError(error);
    } else {
      _showSuccess('Login successful!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
    }

    setState(() => loading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          shadowColor: Colors.grey.shade300,
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App name creative
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Campus',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        TextSpan(
                          text: 'Shelf',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email TextField with icon
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'College Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'user@francisxavier.ac.in',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: forgotPassword,
    child: const Text(
      "Forgot Password?",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
),

                  // Password TextField with icon
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Signup link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
