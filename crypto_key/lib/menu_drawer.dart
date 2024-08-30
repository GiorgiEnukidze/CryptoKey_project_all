import 'package:flutter/material.dart';
import 'password_list_page.dart';
import 'bank_card_page.dart';
import 'id_card_page.dart';
import 'encryption_key_page.dart';
import 'secure_note_page.dart';
import 'profile_page.dart';

class MenuDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('CryptoKey Menu'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text('Profile'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          ListTile(
            title: Text('Password'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PasswordListPage()),
              );
            },
          ),
          ListTile(
            title: Text('Secure Note'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SecureNotePage()),
              );
            },
          ),
          ListTile(
            title: Text('Bank Card'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BankCardPage()),
              );
            },
          ),
          ListTile(
            title: Text('ID Card'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => IdCardPage()),
              );
            },
          ),
          ListTile(
            title: Text('Encryption Key'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EncryptionKeyPage()),
              );
            },
          ),
          
        ],
      ),
    );
  }
}
