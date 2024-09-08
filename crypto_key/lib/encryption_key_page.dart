import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_kryptokey_1/add_encryption_key_page.dart';
import 'config.dart';

class EncryptionKeyPage extends StatefulWidget {
  @override
  _EncryptionKeyPageState createState() => _EncryptionKeyPageState();
}

class _EncryptionKeyPageState extends State<EncryptionKeyPage> {
  List<dynamic> encryptionKeys = [];
  bool isLoading = true; // Indicateur de chargement
  final storage = FlutterSecureStorage(); // Initialisation du stockage sécurisé

  @override
  void initState() {
    super.initState();
    loadEncryptionKeys();
  }

  // Charger les clés de chiffrement
  Future<void> loadEncryptionKeys() async {
    setState(() {
      isLoading = true;
    });

    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/api/keys/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        encryptionKeys = data;
        isLoading = false;
      });
    } else {
      print('Failed to load encryption keys');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Mettre à jour une clé de chiffrement
  Future<void> _updateEncryptionKey(int keyId, String title, String key) async {
    if (title.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.patch(
      Uri.parse('$apiUrl/api/keys/update/$keyId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'titles': title,
        'key': key,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Encryption key updated successfully')));
      await loadEncryptionKeys(); // Rafraîchir les clés après mise à jour
      Navigator.of(context).pop(); // Fermer le dialogue après mise à jour
    } else {
      print('Failed to update encryption key');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update encryption key')));
    }
  }

  // Supprimer une clé de chiffrement
  Future<void> _deleteEncryptionKey(int keyId) async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/api/keys/delete/$keyId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Encryption key deleted successfully')));
        await loadEncryptionKeys(); // Rafraîchir les clés après suppression
        Navigator.of(context).pop();
      } else {
        print('Failed to delete encryption key: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete encryption key')));
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Encryption Keys'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : encryptionKeys.isEmpty
              ? Center(child: Text('No encryption keys available'))
              : ListView.builder(
                  itemCount: encryptionKeys.length,
                  itemBuilder: (context, index) {
                    var encryptionKey = encryptionKeys[index];
                    var keyId = encryptionKey['id'];
                    var title = encryptionKey['titles'] ?? 'Unknown title';
                    var key = encryptionKey['encrypted_key'] ?? 'Unknown key';

                    return ListTile(
                      title: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              TextEditingController titleController = TextEditingController(text: title);
                              TextEditingController keyController = TextEditingController(text: key);

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Text('Encryption Key Details'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: titleController,
                                            decoration: InputDecoration(labelText: 'Title'),
                                          ),
                                          TextField(
                                            controller: keyController,
                                            decoration: InputDecoration(labelText: 'Key'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          var newTitle = titleController.text;
                                          var newKey = keyController.text;
                                          await _updateEncryptionKey(keyId, newTitle, newKey);
                                        },
                                        child: Text('Save'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _deleteEncryptionKey(keyId);
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Text('Title: $title'),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEncryptionKeyPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
