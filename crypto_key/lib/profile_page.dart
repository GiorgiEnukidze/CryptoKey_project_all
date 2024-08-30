import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  late int userId = -1;
  late String username = '';
  late String email = '';
  late String firstName = '';
  late String lastName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      String? token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      final response = await http.get(
        Uri.parse('$apiUrl/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var userData = json.decode(response.body);
        setState(() {
          userId = userData.containsKey('id') ? userData['id'] : -1;
          username = userData.containsKey('username') ? userData['username'] : '';
          email = userData.containsKey('email') ? userData['email'] : '';
          firstName = userData.containsKey('first_name') ? userData['first_name'] : '';
          lastName = userData.containsKey('last_name') ? userData['last_name'] : '';
        });
      } else {
        print('Failed to load user profile');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _usernameController.text = username;
    _emailController.text = email;
    _firstNameController.text = firstName;
    _lastNameController.text = lastName;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: ${userId}'),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfileChanges,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    try {
      String? token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      var userData = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
      };

      // Ajouter le nouveau mot de passe uniquement si le champ n'est pas vide
      if (_newPasswordController.text.isNotEmpty) {
        userData['password'] = _newPasswordController.text;
      }

      var jsonData = jsonEncode(userData);

      final response = await http.patch(
        Uri.parse('$apiUrl/profile/update/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonData,
      );

      if (response.statusCode == 200) {
        print('Profile updated successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        print('Failed to update profile');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
