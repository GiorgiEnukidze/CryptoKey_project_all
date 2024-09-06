import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class AuthenticationService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$apiUrl/api/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String accessToken = data['access'];
      String refreshToken = data['refresh'];

      await _secureStorage.write(key: 'auth_token', value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);

      return accessToken;
    } else {
      return null;
    }
  }

  Future<void> send2FACode(String username, String code2FA) async {
    await http.post(
      Uri.parse('$apiUrl/api/send_2fa/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'code': code2FA}),
    );
  }
}
