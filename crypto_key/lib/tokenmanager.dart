import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class TokenManager {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<String> getAccessToken() async {
    String? token = await _secureStorage.read(key: 'access_token');
    print('Access token from storage: $token');  // Debug: afficher le jeton d'accès

    if (token != null && await isTokenExpired(token)) {
      print('Access token expired, refreshing...');  // Debug: indiquer que le jeton est expiré
      return await refreshAccessToken();
    }

    if (token == null) {
      print('Access token is null');  // Debug: indiquer que le jeton est nul
    }

    return token ?? '';
  }

  static Future<bool> isTokenExpired(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid token structure');  // Debug: indiquer que la structure du jeton est invalide
        return true;
      }

      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      print('Token payload: $payload');  // Debug: afficher la charge utile du jeton

      final expiry = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      print('Token expiry: $expiry, Current time: $now');  // Debug: afficher l'expiration du jeton et l'heure actuelle

      return expiry < now;
    } catch (e) {
      print('Error decoding token: $e');  // Debug: afficher une erreur de décodage du jeton
      return true;
    }
  }

  static Future<String> refreshAccessToken() async {
    String? refreshToken = await _secureStorage.read(key: 'refresh_token');
    print('Refresh token from storage: $refreshToken');  // Debug: afficher le jeton de rafraîchissement

    if (refreshToken == null) {
      print('Refresh token is null');  // Debug: indiquer que le jeton de rafraîchissement est nul
      return '';
    }

    final response = await http.post(
      Uri.parse('$apiUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    print('Refresh token response: ${response.body}');  // Debug: afficher la réponse de la demande de rafraîchissement

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String newAccessToken = data['access'];
      await _secureStorage.write(key: 'access_token', value: newAccessToken);
      print('New access token: $newAccessToken');  // Debug: afficher le nouveau jeton d'accès
      return newAccessToken;
    } else {
      print('Failed to refresh access token, status code: ${response.statusCode}');  // Debug: indiquer que le rafraîchissement du jeton a échoué
      return '';
    }
  }
}
