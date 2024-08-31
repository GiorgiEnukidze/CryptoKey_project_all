import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_kryptokey_1/add_id_card_page.dart';
import 'config.dart';

class IdCardPage extends StatefulWidget {
  @override
  _IdCardPageState createState() => _IdCardPageState();
}

class _IdCardPageState extends State<IdCardPage> {
  List<dynamic> idCards = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadIdCards();
  }

  Future<void> loadIdCards() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/identities/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        idCards = data;
      });
    } else {
      throw Exception('Failed to load ID cards');
    }
  }

  Future<void> _updateIdCard(
      int cardId,
      String idNumber,
      String name,
      String surname,
      String nationality,
      String dateOfBirth,
      String dateOfIssue,
      String expiryDate) async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.patch(
      Uri.parse('$apiUrl/identities/update/$cardId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'id_number': idNumber,
        'name': name,
        'surname': surname,
        'nationality': nationality,
        'date_of_birth': dateOfBirth,
        'date_of_issue': dateOfIssue,
        'expiry_date': expiryDate,
      }),
    );

    if (response.statusCode == 200) {
      print('ID card updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID card updated successfully')));
      await loadIdCards();
      Navigator.of(context).pop();
      await loadIdCards();
    } else {
      print('Failed to update ID card');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update ID card')));
    }
  }

  Future<void> _deleteIdCard(int cardId) async {
    try {
      String? token = await storage.read(key: 'auth_token');
      if (token == null) {
        print('Auth token is null');
        return;
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/identities/delete/$cardId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID card deleted successfully')));
        await loadIdCards();
        Navigator.of(context).pop();
        await loadIdCards();
      } else {
        print('Failed to delete ID card: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete ID card')));
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My ID Cards'),
      ),
      body: idCards.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: idCards.length,
              itemBuilder: (context, index) {
                var card = idCards[index];
                var cardId = card['id'];
                var idNumber = card['id_number'] ?? 'Unknown ID number';
                var name = card['name'] ?? 'Unknown name';
                var surname = card['surname'] ?? 'Unknown surname';
                var nationality = card['nationality'] ?? 'Unknown nationality';
                var dateOfBirth = card['date_of_birth'] ?? 'Unknown date of birth';
                var dateOfIssue = card['date_of_issue'] ?? 'Unknown date of issue';
                var expiryDate = card['expiry_date'] ?? 'Unknown expiry date';

                return ListTile(
                  title: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          TextEditingController idNumberController = TextEditingController(text: idNumber);
                          TextEditingController nameController = TextEditingController(text: name);
                          TextEditingController surnameController = TextEditingController(text: surname);
                          TextEditingController nationalityController = TextEditingController(text: nationality);
                          TextEditingController dateOfBirthController = TextEditingController(text: dateOfBirth);
                          TextEditingController dateOfIssueController = TextEditingController(text: dateOfIssue);
                          TextEditingController expiryDateController = TextEditingController(text: expiryDate);

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text('ID Card Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: idNumberController,
                                        decoration: InputDecoration(labelText: 'ID Number'),
                                      ),
                                      TextField(
                                        controller: nameController,
                                        decoration: InputDecoration(labelText: 'Name'),
                                      ),
                                      TextField(
                                        controller: surnameController,
                                        decoration: InputDecoration(labelText: 'Surname'),
                                      ),
                                      TextField(
                                        controller: nationalityController,
                                        decoration: InputDecoration(labelText: 'Nationality'),
                                      ),
                                      TextField(
                                        controller: dateOfBirthController,
                                        decoration: InputDecoration(labelText: 'Date of Birth'),
                                      ),
                                      TextField(
                                        controller: dateOfIssueController,
                                        decoration: InputDecoration(labelText: 'Date of Issue'),
                                      ),
                                      TextField(
                                        controller: expiryDateController,
                                        decoration: InputDecoration(labelText: 'Expiry Date'),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      var newIdNumber = idNumberController.text;
                                      var newName = nameController.text;
                                      var newSurname = surnameController.text;
                                      var newNationality = nationalityController.text;
                                      var newDateOfBirth = dateOfBirthController.text;
                                      var newDateOfIssue = dateOfIssueController.text;
                                      var newExpiryDate = expiryDateController.text;

                                      await _updateIdCard(cardId, newIdNumber, newName, newSurname, newNationality, newDateOfBirth, newDateOfIssue, newExpiryDate);
                                    },
                                    child: Text('Save'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await _deleteIdCard(cardId);
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Text('Name: $name, Surname: $surname'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddIdCardPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
