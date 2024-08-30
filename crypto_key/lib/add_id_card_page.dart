import 'package:flutter/material.dart';
import 'package:flutter_kryptokey_1/id_card_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'config.dart';

class AddIdCardPage extends StatefulWidget {
  @override
  _AddIdCardPageState createState() => _AddIdCardPageState();
}

class _AddIdCardPageState extends State<AddIdCardPage> {
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final TextEditingController _expiryDateController = TextEditingController();


  DateTime? _selectedDateOfBirth;
  DateTime? _selectedDateOfIssue;
  DateTime? _selectedExpiryDate;

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _selectDateOfIssue(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfIssue = picked;
      });
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  Future<void> _saveIdCard(String idNumber, String name, String surname, String nationality, DateTime dateOfBirth, DateTime dateOfIssue, DateTime expiryDate) async {
    String? token = await _secureStorage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    print('ID Number: $idNumber');
    print('Name: $name');
    print('Surname: $surname');
    print('Nationality: $nationality');
    print('Date of Birth: $dateOfBirth');
    print('Date of Issue: $dateOfIssue');
    print('Expiry Date: $expiryDate');

    var url = Uri.parse('$apiUrl/identities/add/');
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'id_number': idNumber,
        'name': name,
        'surname': surname,
        'nationality': nationality,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'date_of_issue': dateOfIssue.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      print('ID card saved successfully');
      // Implementer la navigation vers la page d'affichage de la carte d'identité
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => IdCardPage()),
        );
    } else {
      print('Failed to save ID card');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save ID card'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ID Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idNumberController,
              decoration: InputDecoration(labelText: 'ID Number'),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _surnameController,
              decoration: InputDecoration(labelText: 'Surname'),
            ),
            TextField(
              controller: _nationalityController,
              decoration: InputDecoration(labelText: 'Nationality'),
            ),
            InkWell(
              onTap: () => _selectDateOfBirth(context),
              child: IgnorePointer(
                child: TextField(
                  controller: _selectedDateOfBirth != null
                      ? TextEditingController(
                          text: DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!))
                      : TextEditingController(),
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Date of Birth'),
                ),
              ),
            ),
            InkWell(              onTap: () => _selectDateOfIssue(context),
              child: IgnorePointer(
                child: TextField(
                  controller: _selectedDateOfIssue != null
                      ? TextEditingController(
                          text: DateFormat('dd/MM/yyyy').format(_selectedDateOfIssue!))
                      : TextEditingController(),
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Date of Issue'),
                ),
              ),
            ),
            InkWell(
              onTap: () => _selectExpiryDate(context),
              child: IgnorePointer(
                child: TextField(
                  controller: _selectedExpiryDate != null
                      ? TextEditingController(
                          text: DateFormat('dd/MM/yyyy').format(_selectedExpiryDate!))
                      : TextEditingController(),
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Expiry Date'),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String idNumber = _idNumberController.text;
                String name = _nameController.text;
                String surname = _surnameController.text;
                String nationality = _nationalityController.text;

                if (idNumber.isEmpty ||
                    name.isEmpty ||
                    surname.isEmpty ||
                    nationality.isEmpty ||
                    _selectedDateOfBirth == null ||
                    _selectedDateOfIssue == null ||
                    _selectedExpiryDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('All fields are required'),
                  ));
                } else {
                  _saveIdCard(idNumber, name, surname, nationality, _selectedDateOfBirth!, _selectedDateOfIssue!, _selectedExpiryDate!);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

