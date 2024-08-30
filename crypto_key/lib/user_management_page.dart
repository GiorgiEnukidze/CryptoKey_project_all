import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class UserManagementPage extends StatefulWidget {
  final String token;

  UserManagementPage({required this.token});

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<dynamic> _users = [];
  String _selectedPassword = '';
  List<String> _passwords = []; // Store passwords fetched from API

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(
      Uri.parse('$apiUrl/users/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _users = json.decode(response.body);
      });
    } else {
      _handleError(response.body);
    }
  }

  void _handleError(String responseBody) {
    final decodedMessage = jsonDecode(responseBody);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(decodedMessage['error'] ?? 'An error occurred')),
    );
  }

  Future<void> _deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('h$apiUrl/users/$userId/delete/'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 204) {
      _fetchUsers(); // Re-fetch users after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    } else {
      _handleError(response.body);
    }
  }

  void _editUserDialog(int userId) {
    final user = _users.firstWhere((u) => u['id'] == userId, orElse: () => null);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
      return;
    }

    TextEditingController usernameController = TextEditingController(text: user['username']);
    TextEditingController emailController = TextEditingController(text: user['email']);
    TextEditingController firstNameController = TextEditingController(text: user['first_name']);
    TextEditingController lastNameController = TextEditingController(text: user['last_name']);
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit User'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final response = await http.patch(
                  Uri.parse('$apiUrl/users/$userId/update/'),
                  headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer ${widget.token}',
                  },
                  body: jsonEncode({
                    'username': usernameController.text,
                    'email': emailController.text,
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'password': passwordController.text.isNotEmpty ? passwordController.text : null,
                  }),
                );

                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  _fetchUsers(); // Re-fetch users after update
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User updated successfully')),
                  );
                } else {
                  Navigator.of(context).pop();
                  _handleError(response.body);
                }
              },
            ),
          ],
        );
      },
    );
  }

Future<List<Map<String, String>>> _fetchUserPasswords(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$apiUrl/users/$userId/passwords/'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      
      // Correction de la structure des données
      List<Map<String, String>> passwords = List<Map<String, String>>.from(
        data['passwords'].map<Map<String, String>>((item) => {
          'site_name': item['site_name'].toString(),  // Conversion explicite en String
          'password': item['password'].toString(),  // Conversion explicite en String
        })
      );
      
      return passwords;
    } else {
      throw Exception('Failed to load passwords. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching passwords: $e');
  }
}






void _notifyUserDialog(int userId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<List<Map<String, String>>>(
        future: _fetchUserPasswords(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: Text('Récupération des données...'),
              content: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: Text('Erreur'),
              content: Text('Erreur lors de la récupération des mots de passe: ${snapshot.error}'),
              actions: <Widget>[
                TextButton(
                  child: Text('Fermer'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          } else if (snapshot.hasData) {
            return AlertDialog(
              title: Text('Sélectionnez un site à notifier'),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    var entry = snapshot.data![index];
                    return ListTile(
                      title: Text(entry['site_name'] ?? 'Site inconnu'),  // Affiche 'Site inconnu' si site_name est null
                      onTap: () {
                        Navigator.of(context).pop();
                        _notifyUser(userId, entry['site_name'] ?? 'Site inconnu');  // Utilise 'Site inconnu' si site_name est null
                      },
                    );
                  },
                ),
              ),
            );
          } else {
            return AlertDialog(
              title: Text('Aucune donnée'),
              content: Text('Aucun site trouvé.'),
              actions: <Widget>[
                TextButton(
                  child: Text('Fermer'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        },
      );
    },
  );
}







void _notifyUser(int userId, String siteName) async {
  print('Notifying user $userId about site: $siteName');
  try {
    final response = await http.post(
      Uri.parse('$apiUrl/users/$userId/notify_password_leak/'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'site_name': siteName}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User notified successfully')),
      );
    } else {
      print('Failed to notify user, status code: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to notify user')),
      );
    }
  } catch (e) {
    print('Error: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_users[index]['username']),
            subtitle: Text('Email: ${_users[index]['email']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editUserDialog(_users[index]['id']),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteUser(_users[index]['id']),
                ),
                IconButton(
                  icon: Icon(Icons.warning),
                  onPressed: () => _notifyUserDialog(_users[index]['id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
