import 'package:flutter/material.dart';
import 'package:flutter_kryptokey_1/add_bank_card_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class BankCardPage extends StatefulWidget {
  @override
  _BankCardPageState createState() => _BankCardPageState();
}

class _BankCardPageState extends State<BankCardPage> {
  List<dynamic> bankCards = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadBankCards();
  }

  Future<void> loadBankCards() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/api/cards/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        bankCards = data;
      });
    } else {
      throw Exception('Failed to load bank cards');
    }
  }

  Future<void> _saveBankCard(int cardId, String cardNumber, String cardholderName, String expiryDate, String cvv) async {
    if (cardNumber.isEmpty || cardholderName.isEmpty || expiryDate.isEmpty || cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.patch(
      Uri.parse('$apiUrl/api/cards/update/$cardId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'card_number': cardNumber,
        'cardholder_name': cardholderName,
        'expiry_date': expiryDate,
        'cvv': cvv,
      }),
    );

    if (response.statusCode == 200) {
      print('Bank card updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bank card updated successfully')));
      await loadBankCards();
      Navigator.of(context).pop();
      await loadBankCards();

    } else {
      print('Failed to update bank card');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update bank card')));
    }
  }


  Future<void> _deleteBankCard(int cardId) async {
  try {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    final response = await http.delete(
      Uri.parse('$apiUrl/api/cards/delete/$cardId/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bank card deleted successfully'),
        ),
      );
      await loadBankCards();
      Navigator.of(context).pop();
      await loadBankCards();
    } else {
      print('Failed to delete bank card: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete bank card'),
        ),
      );
    }
  } catch (e) {
    print('Error occurred: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred. Please try again.'),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bank Cards'),
      ),
      body: bankCards.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: bankCards.length,
              itemBuilder: (context, index) {
                var card = bankCards[index];
                var cardId = card['id'];
                var cardNumber = card['card_number'] ?? 'Unknown card number';
                var cardholderName = card['cardholder_name'] ?? 'Unknown cardholder name';
                var expiryDate = card['expiry_date'] ?? 'Unknown expiry date';
                var cvv = card['cvv'] ?? 'Unknown cvv';

                return ListTile(
                  title: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          TextEditingController cardNumberController =
                              TextEditingController(text: cardNumber);
                          TextEditingController cardholderNameController =
                              TextEditingController(text: cardholderName);
                          TextEditingController expiryDateController =
                              TextEditingController(text: expiryDate);
                          TextEditingController cvvController =
                              TextEditingController(text: cvv);

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text('Bank Card Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: cardNumberController,
                                        decoration: InputDecoration(
                                          labelText: 'Card Number',
                                        ),
                                      ),
                                      TextField(
                                        controller: cardholderNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Cardholder Name',
                                        ),
                                      ),
                                      TextField(
                                        controller: expiryDateController,
                                        decoration: InputDecoration(
                                          labelText: 'Expiry Date',
                                        ),
                                      ),
                                      TextField(
                                        controller: cvvController,
                                        decoration: InputDecoration(
                                          labelText: 'CVV',
                                        ),
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
                                      var newCardNumber = cardNumberController.text;
                                      var newCardholderName = cardholderNameController.text;
                                      var newExpiryDate = expiryDateController.text;
                                      var newCvv = cvvController.text;

                                      await _saveBankCard(cardId, newCardNumber, newCardholderName, newExpiryDate, newCvv);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Save'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await _deleteBankCard(cardId);
                                      Navigator.of(context).pop();
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
                    child: Text('Cardholder Name: $cardholderName'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddBankCardPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}