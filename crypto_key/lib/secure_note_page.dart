import 'package:flutter/material.dart';
import 'package:flutter_kryptokey_1/add_note_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'config.dart';

class SecureNotePage extends StatefulWidget {
  @override
  _SecureNotePageState createState() => _SecureNotePageState();
}

class _SecureNotePageState extends State<SecureNotePage> {
  List<dynamic> notes = [];
  bool isLoading = true; // Indicateur de chargement
  final storage = const FlutterSecureStorage(); // Stockage sécurisé
  final String _encryptionKey = 'vO1IpBzkzAjN9It1dOh8h0d9g1T9R9cYGKwBdpxB21g=';
  final algorithm = AesGcm.with256bits();

  // Fonction pour déchiffrer les données
  Future<String> decryptData(String? encryptedData) async {
  if (encryptedData == null || encryptedData.isEmpty) {
    return 'No content to decrypt';  // Gérer les données nulles ou vides
  }

  try {
    final keyBytes = base64.decode(_encryptionKey);
    final ivBytes = base64.decode(encryptedData.substring(0, 16));
    final encryptedBytes = base64.decode(encryptedData.substring(16));

    final secretBox = SecretBox(
      encryptedBytes,
      nonce: ivBytes,
      mac: Mac.empty,
    );

    final secretKey = SecretKey(keyBytes);
    final decrypted = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decrypted);
  } catch (e) {
    print('Decryption error: $e');
    return 'Error decrypting data';
  }
}



  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  // Charger les notes et les déchiffrer avant d'afficher
  Future<void> loadNotes() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Auth token is null');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/api/notes/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> decryptedNotes = [];

        // Déchiffrer toutes les notes
        for (var note in data) {
          String decryptedContent = await decryptData(note['encrypted_content']);
          decryptedNotes.add({
            'id': note['id'],
            'title': note['title'],
            'content': decryptedContent,
          });
        }

        setState(() {
          notes = decryptedNotes;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      print('Error loading notes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveNote(int noteId, String title, String content) async {
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Auth token is null');
      }

      final response = await http.patch(
        Uri.parse('$apiUrl/api/notes/update/$noteId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note updated successfully')));
        await loadNotes(); // Rafraîchir les notes après mise à jour
        Navigator.of(context).pop(); // Fermer le dialogue
      } else {
        throw Exception('Failed to update note');
      }
    } catch (e) {
      print('Error saving note: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update note')));
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Auth token is null');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/api/notes/delete/$noteId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note deleted successfully')));
        await loadNotes(); // Rafraîchir les notes après suppression
        Navigator.of(context).pop(); // Fermer le dialogue
      } else {
        throw Exception('Failed to delete note');
      }
    } catch (e) {
      print('Error deleting note: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete note')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Secure Notes'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? Center(child: Text('No notes available'))
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    var note = notes[index];
                    var title = note['title'] ?? 'Untitled';
                    var content = note['content'] ?? 'No content';

                    return ListTile(
                      title: Text(title),
                      subtitle: Text(content),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController titleController = TextEditingController(text: title);
                            TextEditingController contentController = TextEditingController(text: content);

                            return AlertDialog(
                              title: Text('Note Details'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: titleController,
                                      decoration: InputDecoration(labelText: 'Title'),
                                    ),
                                    TextField(
                                      controller: contentController,
                                      maxLines: 8,
                                      decoration: InputDecoration(labelText: 'Content'),
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
                                    var newContent = contentController.text;
                                    var noteId = note['id'] as int?;
                                    if (noteId == null) {
                                      print('Error: Note ID is null or invalid');
                                      return;
                                    }
                                    await _saveNote(noteId, newTitle, newContent);
                                  },
                                  child: Text('Save'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Delete Note?'),
                                          content: Text('Are you sure you want to delete this note?'),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                var noteId = note['id'] as int?;
                                                if (noteId == null) {
                                                  print('Error: Note ID is null or invalid');
                                                  return;
                                                }
                                                await _deleteNote(noteId);
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
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
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNotePage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
