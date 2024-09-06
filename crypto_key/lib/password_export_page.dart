import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html; 
import 'config.dart';


class PasswordExportPage extends StatefulWidget {
  @override
  _PasswordExportPageState createState() => _PasswordExportPageState();
}

class _PasswordExportPageState extends State<PasswordExportPage> {
  String _selectedFormat = 'json';
  final storage = FlutterSecureStorage();

  Future<void> _exportPasswords() async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      final response = await http.post(
        Uri.parse('$apiUrl/api/export/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'format': _selectedFormat}),
      );

      if (response.statusCode == 200) {
        print('Passwords exported successfully');

        // Handle the download in the web browser
        final content = response.bodyBytes;
        final blob = html.Blob([content]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'passwords.$_selectedFormat')
          ..click();
        html.Url.revokeObjectUrl(url); // Cleanup the object URL after download
      } else {
        print('Failed to export passwords. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error exporting passwords: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Passwords'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: _selectedFormat,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFormat = newValue!;
                });
              },
              items: <String>['json', 'csv']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: _exportPasswords,
              child: Text('Export'),
            ),
          ],
        ),
      ),
    );
  }
}
