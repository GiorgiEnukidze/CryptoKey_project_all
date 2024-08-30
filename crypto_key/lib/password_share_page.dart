import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class PasswordSharePage extends StatefulWidget {
  @override
  _PasswordSharePageState createState() => _PasswordSharePageState();
}

class _PasswordSharePageState extends State<PasswordSharePage> {
  final storage = FlutterSecureStorage(); // Initialisation du stockage sécurisé
  List<dynamic> passwords = [];
  List<dynamic> sharedPasswords = [];
  bool isLoading = true; // Indicateur de chargement

  @override
  void initState() {
    super.initState();
    loadPasswords();
    fetchSharedPasswords();
  }

  Future<void> loadPasswords() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/passwords/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        passwords = data;
        isLoading = false;
      });
    } else {
      print('Failed to load passwords');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchSharedPasswords() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/share/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var sharedData = json.decode(response.body) as List<dynamic>;
      
      // Filtrer les mots de passe expirés
      var nonExpiredPasswords = sharedData.where((password) {
        var expirationDate = DateTime.parse(password['expiration_date']);
        return expirationDate.isAfter(DateTime.now());
      }).toList();
      
      setState(() {
        sharedPasswords = nonExpiredPasswords;
      });
    } else {
      print('Failed to load shared passwords');
    }
  }

  Future<void> sharePassword(int passwordId, int sharedWithUserId, DateTime expirationDate) async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.post(
      Uri.parse('$apiUrl/share/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'password_entry_id': passwordId,
        'shared_with_user_id': sharedWithUserId,
        'expiration_date': expirationDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password shared successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share password')),
      );
    }
  }

  Future<void> _sharePasswordDialog(int passwordId) async {
    TextEditingController userIdController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: InputDecoration(
                  labelText: 'Enter user ID to share with',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Text('Select expiration date:'),
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != selectedDate)
                    setState(() {
                      selectedDate = pickedDate;
                    });
                },
                child: Text("${selectedDate.toLocal()}".split(' ')[0]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                var sharedWithUserId = int.parse(userIdController.text);
                await sharePassword(passwordId, sharedWithUserId, selectedDate);
                Navigator.of(context).pop();
              },
              child: Text('Share'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Passwords'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: Text('My Passwords', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...passwords.map((passwordEntry) {
                  var site = passwordEntry['site_name'] ?? 'Unknown site';
                  var username = passwordEntry['username'] ?? 'Unknown username';
                  var password = passwordEntry['password'] ?? 'Unknown password'; // Fetching the password

                  return ListTile(
                    title: Text(site),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: $username'),
                        Text('Password: $password'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        _sharePasswordDialog(passwordEntry['id']);
                      },
                    ),
                  );
                }).toList(),
                if (sharedPasswords.isNotEmpty)
                  ListTile(
                    title: Text('Shared Passwords', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (sharedPasswords.isNotEmpty)
                  ...sharedPasswords.map((sharedPassword) {
                    var site = sharedPassword['site_name'] ?? 'Unknown site';
                    var username = sharedPassword['username'] ?? 'Unknown username';
                    var password = sharedPassword['password'] ?? 'Unknown password'; // Displaying shared password
                    var expirationDate = DateTime.parse(sharedPassword['expiration_date'] ?? DateTime.now().toString());
                    var remainingTime = expirationDate.difference(DateTime.now());

                    String formatRemainingTime(Duration duration) {
                      int days = duration.inDays;
                      int hours = duration.inHours.remainder(24);
                      int minutes = duration.inMinutes.remainder(60);
                      return '$days days, $hours hours, $minutes minutes';
                    }

                    return ListTile(
                      tileColor: Colors.green[100], // Fond vert pour les mots de passe partagés
                      title: Text(site),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: $username'),
                          Text('Password: $password'), // Displaying the shared password
                          Text('Expires in: ${formatRemainingTime(remainingTime)}'),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
    );
  }
}
