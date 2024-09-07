import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'authentication_service.dart';
import 'register_page.dart';
import 'admin_page.dart';
import 'two_factor_page.dart';  // Importez la page pour la vérification 2FA

class LoginPage extends StatelessWidget {
  final AuthenticationService _authService = AuthenticationService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  void _login(BuildContext context) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    try {
      final String? token = await _authService.login(username, password);
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login successful'),
        ));

        // Vérifiez si les identifiants correspondent à ceux de l'administrateur
        if (username == 'admin' && password == 'GioTest123') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPage()),
          );
        } else {
          // Génération du code 2FA et envoi par email
          String code2FA = _generate2FACode();
          await _authService.send2FACode(username, code2FA);

          // Naviguez vers la page de vérification 2FA
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TwoFactorPage(code2FA: code2FA)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Invalid username or password'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to login: $e'),
      ));
    }
  }

  String _generate2FACode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => _navigateToRegister(context),
              child: Text('Don\'t have an account? Register here'),
            ),
          ],
        ),
      ),
    );
  }
}
