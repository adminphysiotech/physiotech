import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Use your Cloud Run URL for development, or your custom domain for production
  final String _baseUrl = 'https://physiotech-auth-service-305880139024.us-central1.run.app';
  // Once your custom domain is set up and working, you'd switch to:
  // final String _baseUrl = 'https://physiotech.app';

  final _storage = const FlutterSecureStorage();

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];
        await _storage.write(key: 'jwt_token', value: token);
        return token;
      } else {
        // Handle login errors (e.g., invalid credentials)
        print('Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  Future<bool> signup(String email, String password, String companyName, String address) async {
    final url = Uri.parse('$_baseUrl/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'company_name': companyName,
          'address': address,
          // Add subscription plan here later
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Signup successful, backend will handle MFA and DB provisioning
        print('Signup initiated successfully: ${response.body}');
        return true;
      } else {
        print('Signup failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during signup: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}
