import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kryptokey_1/add_password_page.dart';
import 'dart:math';
import 'package:flutter_kryptokey_1/bank_card_page.dart';
import 'package:flutter_kryptokey_1/encryption_key_page.dart';
import 'package:flutter_kryptokey_1/id_card_page.dart';
import 'package:flutter_kryptokey_1/secure_note_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_page.dart';
import 'package:flutter_kryptokey_1/password_export_page.dart';
import 'package:flutter_kryptokey_1/password_import_page.dart';
import 'package:flutter_kryptokey_1/password_share_page.dart';
import 'config.dart';
import 'login_page.dart';

// Fonction pour vérifier la solidité des mots de passe
List<dynamic> checkPasswordStrength(String password) {
  int length = password.length;
  bool hasDigit = RegExp(r'\d').hasMatch(password);
  bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
  bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
  bool hasSpecialChar = RegExp(r'[!@#\$%^&*()\-_+=~`\[\]{}|;:"\,.<>?/]').hasMatch(password);
  
  List<String> commonPasswords = [
    '123456', 'password', '123456789', 'guest', 'qwerty', '12345678', 
    '111111', '12345', 'abc123', '123qwe', 'password1'
  ];

  bool isNotCommonPassword = !commonPasswords.contains(password);

  int strength = 0;
  List<String> suggestions = [];

  // Critères de longueur
  if (length >= 8) strength += 1;
  if (length >= 12) strength += 1;
  if (length >= 16) strength += 1;
  else suggestions.add('Use at least 16 characters.');

  // Critères de caractère
  if (hasLowercase) strength += 1;
  else suggestions.add('Add lower-case letters.');
  if (hasUppercase) strength += 1;
  else suggestions.add('Add upper-case letters.');
  if (hasDigit) strength += 1;
  else suggestions.add('Add numbers.');
  if (hasSpecialChar) strength += 1;
  else suggestions.add('Add special characters.');

  // Critères de mots de passe communs
  if (isNotCommonPassword) strength += 3;
  else suggestions.add('Avoid common passwords.');

  return [strength, suggestions];
}

// Générer un mot de passe aléatoire avec une longueur choisie
String _generateRandomPassword(int length) {
  const String chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+[]{}|;:,.<>?';
  final Random rnd = Random.secure();
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

class PasswordListPage extends StatefulWidget {
  @override
  _PasswordListPageState createState() => _PasswordListPageState();
}

class _PasswordListPageState extends State<PasswordListPage> {
  List<dynamic> passwords = [];
  List<dynamic> sharedPasswords = [];
  final storage = FlutterSecureStorage(); // Initialisation du stockage sécurisé
  bool _hasSimilarPassword = false;
  List<String> similarSites = [];
  bool isLoading = true; // Indicateur de chargement
  int passwordLength = 12; // Valeur par défaut pour la longueur du mot de passe généré

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
      Uri.parse('$apiUrl/api/passwords/'),
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
      Uri.parse('$apiUrl/api/share/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var sharedData = json.decode(response.body) as List<dynamic>;
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

  Future<void> _savePassword(int passwordId, String sitename, String siteurl,
      String username, String password) async {
    if (sitename.isEmpty || siteurl.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.patch(
      Uri.parse('$apiUrl/api/passwords/update/$passwordId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'site_name': sitename,
        'site_url': siteurl,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('Password updated successfully');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Password updated successfully')));
      await loadPasswords();
      Navigator.of(context).pop();
    } else {
      print('Failed to update password');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update password')));
    }
  }

  Future<void> _deletePassword(int passwordId) async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.delete(
      Uri.parse('$apiUrl/api/passwords/delete/$passwordId/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password deleted successfully')),
      );
      await loadPasswords();
      Navigator.of(context).pop();
    } else {
      print('Failed to delete password: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete password')),
      );
    }
  }

  void _checkSimilarPasswords(
      BuildContext context, String site, String password, List passwords) {
    similarSites.clear();

    for (var entry in passwords) {
      var otherSite = entry['site_name'] ?? 'Unknown site';
      var otherPassword = entry['password'] ?? 'Unknown password';

      if (password == otherPassword && site != otherSite) {
        setState(() {
          _hasSimilarPassword = true;
          similarSites.add(otherSite);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Passwords')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('CryptoKey Menu'),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              title: Text('Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PasswordListPage()),
                );
              },
            ),
            ListTile(
              title: Text('Secure Note'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecureNotePage()),
                );
              },
            ),
            ListTile(
              title: Text('Bank Card'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BankCardPage()),
                );
              },
            ),
            ListTile(
              title: Text('ID Card'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IdCardPage()),
                );
              },
            ),
            ListTile(
              title: Text('Encryption Key'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EncryptionKeyPage()),
                );
              },
            ),
            ListTile(
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await storage.delete(key: 'auth_token');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
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
                  var url = passwordEntry['site_url'] ?? 'Unknown url';
                  var password = passwordEntry['password'] ?? 'Unknown password';

                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(site),
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: password));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password copied')));
                          },
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: $username'),
                        Text('URL: $url'),
                      ],
                    ),
                    onTap: () {
                      _checkSimilarPasswords(context, site, password, passwords);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          TextEditingController siteController =
                              TextEditingController(text: site);
                          TextEditingController usernameController =
                              TextEditingController(text: username);
                          TextEditingController urlController =
                              TextEditingController(text: url);
                          TextEditingController passwordController =
                              TextEditingController(text: password);

                          bool obscurePassword = true;

                          return StatefulBuilder(
                            builder: (context, setState) {
                              int passwordStrength = 0;
                              List<String> suggestions = [];
                              if (password.isNotEmpty) {
                                List<dynamic> result =
                                    checkPasswordStrength(password);
                                passwordStrength = result[0];
                                suggestions = result[1];
                              }
                              return AlertDialog(
                                title: Text('Password Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: siteController,
                                        decoration: InputDecoration(labelText: 'Site'),
                                      ),
                                      TextField(
                                        controller: usernameController,
                                        decoration: InputDecoration(labelText: 'Username'),
                                      ),
                                      TextField(
                                        controller: urlController,
                                        decoration: InputDecoration(labelText: 'URL'),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: passwordController,
                                              obscureText: obscurePassword,
                                              decoration: InputDecoration(labelText: 'Password'),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off),
                                            onPressed: () {
                                              setState(() {
                                                obscurePassword = !obscurePassword;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      Text('Password Strength: $passwordStrength'),
                                      if (suggestions.isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Suggestions:'),
                                            for (var suggestion in suggestions)
                                              Text('- $suggestion'),
                                          ],
                                        ),
                                      if (_hasSimilarPassword)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Similar passwords found:'),
                                            for (var similarSite in similarSites)
                                              Text('- $similarSite', style: TextStyle(color: Colors.red)),
                                          ],
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
                                      await _savePassword(
                                          passwordEntry['id'], siteController.text, urlController.text, usernameController.text, passwordController.text);
                                    },
                                    child: Text('Save'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      var newPassword = _generateRandomPassword(passwordLength);
                                      setState(() {
                                        passwordController.text = newPassword;
                                      });
                                    },
                                    child: Text('Generate Password'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Delete Password?'),
                                            content: Text(
                                                'Are you sure you want to delete this password?'),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await _deletePassword(passwordEntry['id']);
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
                  );
                }).toList(),
                if (sharedPasswords.isNotEmpty)
                  ListTile(title: Text('Shared Passwords', style: TextStyle(fontWeight: FontWeight.bold))),
                if (sharedPasswords.isNotEmpty)
                  ...sharedPasswords.map((sharedPassword) {
                    var site = sharedPassword['site_name'] ?? 'Unknown site';
                    var username = sharedPassword['username'] ?? 'Unknown username';
                    var url = sharedPassword['site_url'] ?? 'Unknown url';
                    var expirationDate = DateTime.parse(sharedPassword['expiration_date'] ?? DateTime.now().toString());
                    var remainingTime = expirationDate.difference(DateTime.now());

                    String formatRemainingTime(Duration duration) {
                      int days = duration.inDays;
                      int hours = duration.inHours.remainder(24);
                      int minutes = duration.inMinutes.remainder(60);
                      return '$days days, $hours hours, $minutes minutes';
                    }

                    return ListTile(
                      tileColor: Colors.green[100],
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(site),
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: sharedPassword['password'] ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shared password copied')));
                            },
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: $username'),
                          Text('URL: $url'),
                          Text('Expires in: ${formatRemainingTime(remainingTime)}'),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordExportPage()),
              );
            },
            child: Icon(Icons.file_upload),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordSharePage()),
              );
            },
            child: Icon(Icons.share),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordImportPage()),
              );
            },
            child: Icon(Icons.file_download),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPasswordPage()),
              );
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
