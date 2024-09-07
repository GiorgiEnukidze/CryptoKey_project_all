import 'package:flutter/material.dart';
import 'password_list_page.dart';
import 'bank_card_page.dart';
import 'id_card_page.dart';
import 'encryption_key_page.dart';
import 'secure_note_page.dart';
import 'profile_page.dart';
import 'login_page.dart';  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MenuDrawer extends StatelessWidget {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();  // Stockage sécurisé pour la session

  Future<void> _logout(BuildContext context) async {
    // Supprime les données de session (token d'authentification)
    await secureStorage.delete(key: 'auth_token');

    // Redirige vers la page de connexion et empêche de revenir en arrière
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()), 
      (Route<dynamic> route) => false,  // Supprime toutes les pages précédentes de la pile de navigation
    );
  }

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
          Divider(),  // Séparation avant le bouton de déconnexion
          ListTile(
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _logout(context);  // Appel à la fonction de déconnexion
            },
          ),
        ],
      ),
    );
  }
}
