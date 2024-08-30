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
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadEncryptionKeys();
  }

  Future<void> loadEncryptionKeys() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/keys/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        encryptionKeys = data;
      });
    } else {
      throw Exception('Failed to load encryption keys');
    }
  }

  Future<void> _updateEncryptionKey(int keyId, String title, String key) async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.patch(
      Uri.parse('$apiUrl/keys/update/$keyId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'key': key,
      }),
    );

    if (response.statusCode == 200) {
      print('Encryption key updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Encryption key updated successfully')));
      await loadEncryptionKeys();
      Navigator.of(context).pop();
    } else {
      print('Failed to update encryption key');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update encryption key')));
    }
  }

  Future<void> _deleteEncryptionKey(int keyId) async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/keys/delete/$keyId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Encryption key deleted successfully')));
        await loadEncryptionKeys();
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
      body: encryptionKeys.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: encryptionKeys.length,
              itemBuilder: (context, index) {
                var encryptionKey = encryptionKeys[index];
                var keyId = encryptionKey['id'];
                var title = encryptionKey['titles'] ?? 'Unknown title';
                var key = encryptionKey['key'] ?? 'Unknown key';

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
