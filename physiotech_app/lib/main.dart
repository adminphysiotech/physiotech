import 'package:flutter/material.dart';
import 'package:physiotech_app/services/auth_service.dart'; // Import your auth service

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physiotech App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _message = '';

  Future<void> _login() async {
    final token = await _authService.login(_emailController.text, _passwordController.text);
    if (token != null) {
      setState(() {
        _message = 'Login successful! Token: ${token.substring(0, 10)}...';
      });
      // Navigate to home screen
    } else {
      setState(() {
        _message = 'Login failed.';
      });
    }
  }

  Future<void> _signup() async {
    final success = await _authService.signup(
      _emailController.text,
      _passwordController.text,
      _companyNameController.text,
      _addressController.text,
    );
    if (success) {
      setState(() {
        _message = 'Signup initiated. Check email/SMS for verification!';
      });
      // Navigate to MFA verification screen
    } else {
      setState(() {
        _message = 'Signup failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Physiotech Auth')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Company Name (for Signup)'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address (for Signup)'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
                ElevatedButton(
                  onPressed: _signup,
                  child: const Text('Signup'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
