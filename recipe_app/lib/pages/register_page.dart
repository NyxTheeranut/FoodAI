import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:ui';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  String? _emailErrorMessage;
  bool _showEmailError = false;
  String? _passwordErrorMessage;
  bool _showPasswordError = false;
  bool _isPasswordVisible = false;

  // Email validation
  bool isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _validateEmail(String email) {
    setState(() {
      if (email.isEmpty) {
        _isEmailValid = false;
        _showEmailError = false;
        _emailErrorMessage = null;
      } else if (!isEmailValid(email)) {
        _isEmailValid = false;
        _showEmailError = true;
        _emailErrorMessage = 'Please enter a valid email';
      } else {
        _isEmailValid = true;
        _showEmailError = false;
        _emailErrorMessage = null;
      }
    });
  }

  // Password validation criteria (aligned with Rules\Password::defaults())
  bool hasUppercase(String password) => password.contains(RegExp(r'[A-Z]'));
  bool hasLowercase(String password) => password.contains(RegExp(r'[a-z]'));
  bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
  bool hasMinLength(String password) => password.length >= 8;

  String? validatePassword(String password) {
    if (!hasMinLength(password)) {
      return 'Password must be at least 8 characters';
    }
    if (!hasUppercase(password)) {
      return 'Password needs an uppercase letter';
    }
    if (!hasLowercase(password)) {
      return 'Password needs a lowercase letter';
    }
    if (!hasNumber(password)) {
      return 'Password needs a number';
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _register() async {
    if (!_isEmailValid || !_isPasswordValid) return; // Prevent registration if email or password is invalid
    setState(() {
      _isLoading = true;
    });
    try {
      await _apiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Registration failed - $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      _validateEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      final password = _passwordController.text;
      final error = validatePassword(password);
      setState(() {
        _isPasswordValid = error == null;
        if (error != null && password.isNotEmpty) {
          _showPasswordError = true;
          _passwordErrorMessage = error;
        } else {
          _showPasswordError = false;
          _passwordErrorMessage = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 24,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildTextField(_nameController, 'Name'),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, 'Email'),
                    if (_showEmailError)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _emailErrorMessage ?? '',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      _passwordController,
                      'Password',
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password must contain uppercase, lowercase, and a number',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 113, 101, 101),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_showPasswordError)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _passwordErrorMessage ?? '',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.blue)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isEmailValid && _isPasswordValid) ? _register : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Already have an account? Login',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.grey[200]!.withOpacity(0.5),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: suffixIcon,
            ),
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ),
    );
  }
}