import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter_kryptokey_1/secure_note_page.dart';
import 'package:cryptography/cryptography.dart'; // Ajouté pour le chiffrement
import 'config.dart';

class AddNotePage extends StatefulWidget {
  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final storage = const FlutterSecureStorage(); // Initialisation du stockage sécurisé
  final String _encryptionKey = 'vO1IpBzkzAjN9It1dOh8h0d9g1T9R9cYGKwBdpxB21g=';
  final algorithm = AesGcm.with256bits();

  // Fonction pour chiffrer les données
  Future<String> encryptData(String content) async {
    try {
      final keyBytes = base64.decode(_encryptionKey);
      final secretKey = SecretKey(keyBytes);

      final nonce = algorithm.newNonce(); // Générer un nonce
      final secretBox = await algorithm.encrypt(
        content.codeUnits, // Convertir le contenu en liste d'unités de code
        secretKey: secretKey,
        nonce: nonce,
      );

      // Concaténer le nonce et les données chiffrées pour les envoyer au backend
      return base64.encode(nonce + secretBox.cipherText);
    } catch (e) {
      print('Encryption error: $e');
      throw Exception('Error encrypting data');
    }
  }

  Future<void> _saveNote() async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      // Récupérer l'ID utilisateur à partir du token JWT
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      String? userId = decodedToken['user_id']?.toString();
      if (userId == null) {
        print('User ID not found in token');
        return;
      }

      // Chiffrer le contenu de la note avant de l'envoyer
      String encryptedContent = await encryptData(_contentController.text);

      // Construire les données à envoyer
      Map<String, dynamic> data = {
        'user': userId,
        'title': _titleController.text,
        'content': encryptedContent, // Utiliser le contenu chiffré
      };

      // Envoyer les données au backend
      final response = await http.post(
        Uri.parse('$apiUrl/api/notes/add/'), // Assurez-vous que l'URL de l'API est correcte
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note saved successfully'),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SecureNotePage()),
        );
      } else {
        print('Failed to save note: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note'),
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
        title: Text('Add Note'),
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
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 8,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('All fields are required'),
                  ));
                } else {
                  _saveNote();
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
