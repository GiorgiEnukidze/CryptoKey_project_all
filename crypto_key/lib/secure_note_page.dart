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
  final storage = FlutterSecureStorage(); // Initialisez le stockage sécurisé

  final String _encryptionKey = 'vO1IpBzkzAjN9It1dOh8h0d9g1T9R9cYGKwBdpxB21g=';
  final algorithm = AesGcm.with256bits(); 

  // Fonction pour déchiffrer les données
  Future<String> decryptData(String encryptedData) async {
    // Convertir la clé de déchiffrement en bytes
    final keyBytes = base64.decode(_encryptionKey); 

    // Convertir l'IV (vecteur d'initialisation) en bytes
    final ivBytes = base64.decode(encryptedData.substring(0, 16)); 

    // Convertir les données chiffrées en bytes
    final encryptedBytes = base64.decode(encryptedData.substring(16));

    // Créer le SecretBox
    final secretBox = SecretBox(
      encryptedBytes,
      nonce: ivBytes,
      mac: Mac.empty, // Le MAC peut être vide si non utilisé
    );

    // Déchiffrer les données
    final secretKey = SecretKey(keyBytes);
    final decrypted = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    // Convertir les bytes déchiffrés en chaîne de caractères
    return utf8.decode(decrypted);
  }

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/secure_notes/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print(data);
      setState(() {
        notes = data;
      });
    } else {
      throw Exception('Failed to load notes');
    }
  }

  Future<void> _saveNote(int noteId, String title, String content) async {
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.patch(
      Uri.parse('$apiUrl/secure_notes/update/$noteId/'),
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
      print('Note updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note updated successfully')));
      await loadNotes(); // Rafraîchir les notes après une mise à jour réussie
      Navigator.of(context).pop(); // Fermer le dialogue après la mise à jour
    } else {
      print('Failed to update note');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update note')));
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/secure_notes/delete/$noteId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note deleted successfully'),
          ),
        );
        await loadNotes(); // Rafraîchir les notes après une mise à jour réussie
        Navigator.of(context).pop(); // Fermer le dialogue après la mise à jour
        await loadNotes();
      } else {
        print('Failed to delete note: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note'),
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
        title: Text('My Secure Notes'),
      ),

      body: notes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                var note = notes[index];
                var title = note['title'] ?? 'Untitled';
                // changement ici aussi
                var encryptedContent = note['content'] ?? '';
                String content = '';

                // Déchiffrer le contenu de la note
                decryptData(encryptedContent).then((decrypted) {
                  setState(() {
                    content = decrypted;
                  });
                });

                return ListTile(
                  title: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          TextEditingController titleController =
                              TextEditingController(text: title);
                          TextEditingController contentController =
                              TextEditingController(text: content);

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text('Note Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: titleController,
                                        decoration: InputDecoration(
                                          labelText: 'Title',
                                        ),
                                      ),
                                      TextField(
                                        controller: contentController,
                                        maxLines: 8,
                                        decoration: InputDecoration(
                                          labelText: 'Content',
                                        ),
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

                                      // Vérifier si note contient l'ID de la note et qu'il n'est pas null
                                      var noteId = note['id'] as int?;
                                      if (noteId == null) {
                                        print('Error: Note ID is null or invalid');
                                        return;
                                      }

                                      // Envoie des nouvelles données au backend et ferme le dialogue
                                      await _saveNote(
                                          noteId, newTitle, newContent);
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
                                    child: Text('Delete Note'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Text(title),
                  ),
                  subtitle: Text(content),
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
