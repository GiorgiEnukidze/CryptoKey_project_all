import 'package:flutter/material.dart';
import 'user_management_page.dart';
import 'statistics_logs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminPage extends StatelessWidget {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
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
              child: Text('Manage Users'),
            ),
            ElevatedButton(
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
              child: Text('View Statistics'),
            ),
          ],
        ),
      ),
    );
  }
}
