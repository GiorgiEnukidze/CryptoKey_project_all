import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter_kryptokey_1/encryption_key_page.dart';
import 'config.dart';

class AddEncryptionKeyPage extends StatefulWidget {
  @override
  _AddEncryptionKeyPageState createState() => _AddEncryptionKeyPageState();
}

class _AddEncryptionKeyPageState extends State<AddEncryptionKeyPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final storage = const FlutterSecureStorage();

  Future<void> _addEncryptionKey() async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      print('Decoded token: $decodedToken');
      String? userId = decodedToken['user_id']?.toString();
      print('User ID: $userId');

      if (userId == null) {
        print('User ID not found in token');
        return;
      }

      Map<String, dynamic> data = {
        'user': userId,
        'titles': _titleController.text,
        'key': _keyController.text,
      };

      print('Data to send: $data');

      final response = await http.post(
        Uri.parse('$apiUrl/api/keys/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encryption key added successfully'),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EncryptionKeyPage()),
        );
      } else {
        print('Failed to add encryption key: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add encryption key'),
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
        title: Text('Add Encryption Key'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(labelText: 'Key'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isEmpty || _keyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All fields are required'),
                    ),
                  );
                } else {
                  _addEncryptionKey();
                }
              },
              child: Text('Add Encryption Key'),
            ),
          ],
        ),
      ),
    );
  }
}
