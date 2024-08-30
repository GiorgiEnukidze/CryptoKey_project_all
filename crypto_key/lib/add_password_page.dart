import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter_kryptokey_1/password_list_page.dart'; 
import 'config.dart';

class AddPasswordPage extends StatefulWidget {
  @override
  _AddPasswordPageState createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final TextEditingController _sitenameController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordLengthController =
      TextEditingController(text: '12');

  final storage = const FlutterSecureStorage(); // Initialisez le stockage sécurisé

  String _generateRandomPassword(int length) {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+[]{}|;:,.<>?';
    final Random rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _savePassword() async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      print('hello1');
      // Récupérer l'ID utilisateur à partir du token JWT
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      print('Decoded token: $decodedToken'); // Ajouter ce print pour vérifier le token
      String? userId = decodedToken['user_id']?.toString(); // Modification ici
      print('User ID: $userId'); // Ajouter ce print pour vérifier l'ID utilisateur

      if (userId == null) {
        print('User ID not found in token');
        return;
      } else {
        print('User ID is also found in token');
      }

      // Vérifier si la longueur du mot de passe est valide
      final int? length = int.tryParse(_passwordLengthController.text);
      if (length == null || length <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid password length'),
          ),
        );
        return;
      }
      print('hello2');
      // Construire les données à envoyer
      Map<String, dynamic> data = {
        'user': userId,
        'site_name': _sitenameController.text,
        'site_url': _siteController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
      };

      // Afficher les données à envoyer à la console
      print('Data to send: $data');
      print('hello3');
      // Envoyer les données au backend
      final response = await http.post(
        Uri.parse('$apiUrl/passwords/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password saved successfully'),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PasswordListPage()),
        );
      } else {
        print('Failed to save password: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save password'),
          ),
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _sitenameController,
              decoration: InputDecoration(labelText: 'Site Name'),
            ),
            TextField(
              controller: _siteController,
              decoration: InputDecoration(labelText: 'Site URL'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordLengthController,
                    decoration:
                        InputDecoration(labelText: 'Password Length'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Vérifier et générer un mot de passe aléatoire
                    final int? length =
                        int.tryParse(_passwordLengthController.text);
                    if (length != null && length > 0) {
                      setState(() {
                        _passwordController.text =
                            _generateRandomPassword(length);
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Invalid password length'),
                      ));
                    }
                  },
                  child: Text('Generate'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_siteController.text.isEmpty ||
                    _usernameController.text.isEmpty ||
                    _passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('All fields are required'),
                  ));
                } else {
                  _savePassword();
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
