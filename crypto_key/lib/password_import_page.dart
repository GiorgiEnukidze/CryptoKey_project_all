import 'package:flutter_kryptokey_1/password_list_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'config.dart';

class PasswordImportPage extends StatefulWidget {
  @override
  _PasswordImportPageState createState() => _PasswordImportPageState();
}

class _PasswordImportPageState extends State<PasswordImportPage> {
  final storage = FlutterSecureStorage();
  String? _selectedFileName;

  Future<void> _importPasswords() async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result != null) {
        String fileName = result.files.single.name;
        String? fileContent;

        if (result.files.single.bytes != null) {
          fileContent = utf8.decode(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          fileContent = await File(result.files.single.path!).readAsString();
        }

        if (fileContent != null) {
          setState(() {
            _selectedFileName = fileName;
          });

          final request = http.MultipartRequest(
            'POST',
            Uri.parse('$apiUrl/import/'),
          );

          request.headers['Authorization'] = 'Bearer $token';

          if (fileName.endsWith('csv')) {
            request.fields['format'] = 'csv';
            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                utf8.encode(fileContent),
                filename: fileName,
                contentType: MediaType('text', 'csv'),
              ),
            );
          } else {
            request.fields['format'] = 'json';
            request.fields['data'] = fileContent;
          }

          final response = await request.send();

          if (response.statusCode == 200) {
            print('Passwords imported successfully');
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Passwords imported successfully')));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PasswordListPage()),
            );
          } else {
            print('Failed to import passwords. Status code: ${response.statusCode}');
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to import passwords')));
          }
        } else {
          print('Failed to read file content');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to read file content')));
        }
      } else {
        print('No file selected');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file selected')));
      }
    } catch (e) {
      print('Error importing passwords: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing passwords')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Passwords'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _importPasswords,
              child: Text('Import Passwords'),
            ),
            if (_selectedFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Selected file: $_selectedFileName'),
              ),
          ],
        ),
      ),
    );
  }
}
