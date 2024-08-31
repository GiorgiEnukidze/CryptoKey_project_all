// http_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class HttpService {

  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/token/'),
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['access'];
        return token;
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> fetchData(String token) async {

    final response = await http.get(
      Uri.parse('$apiUrl/passwords//token/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Traitement des données ici
      print(json.decode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }
}