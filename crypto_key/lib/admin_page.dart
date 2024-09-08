import 'package:flutter/material.dart';
import 'user_management_page.dart';
import 'statistics_logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminPage extends StatelessWidget {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<void> _logout(BuildContext context) async {
    await _secureStorage.delete(key: 'auth_token'); // Efface le token pour déconnexion
    Navigator.pushReplacementNamed(context, '/login'); // Redirige vers la page de connexion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        centerTitle: true, // Centre le titre de la page
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context), // Bouton de déconnexion dans l'AppBar
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenue sur la page Admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 30.0),
            ElevatedButton.icon(
              onPressed: () async {
                final token = await _getToken();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserManagementPage(token: token),
                    ),
                  );
                }
              },
              icon: Icon(Icons.people), // Icône ajoutée
              label: Text('Gérer les Utilisateurs'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16.0),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Boutons arrondis
                ),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton.icon(
              onPressed: () async {
                final token = await _getToken();
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatisticsPage(token: token),
                    ),
                  );
                }
              },
              icon: Icon(Icons.bar_chart), // Icône ajoutée
              label: Text('Voir les Statistiques'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16.0),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 40.0),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: Icon(Icons.logout), // Icône de déconnexion ajoutée
              label: Text('Se Déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Couleur de déconnexion
                padding: EdgeInsets.all(16.0),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
