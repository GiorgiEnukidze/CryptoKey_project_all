import 'package:flutter/material.dart';
import 'package:flutter_kryptokey_1/bank_card_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class AddBankCardPage extends StatefulWidget {
  @override
  _AddBankCardPageState createState() => _AddBankCardPageState();
}

class _AddBankCardPageState extends State<AddBankCardPage> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardholderNameController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _expirationDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveBankCard(String cardNumber, String cardholderName, String expirationDate, String cvv) async {
    String? token = await _secureStorage.read(key: 'auth_token');
    if (token == null) {
      print('Auth token is null');
      return;
    }

    // Convertir la date d'expiration au format attendu par le backend (DateField)
    List<String> dateParts = expirationDate.split('/');
    String formattedExpirationDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

    var url = Uri.parse('$apiUrl/api/cards/add/');
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'card_number': cardNumber,
        'cardholder_name': cardholderName,
        'expiry_date': formattedExpirationDate, // Utiliser la date formatée
        'cvv': cvv,
      }),
    );

    if (response.statusCode == 201) {
      print('Bank card saved successfully');
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BankCardPage()),
        );
    } else {
      print('Failed to save bank card');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save bank card'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Bank Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Card Number'),
            ),
            TextField(
              controller: _cardholderNameController,
              decoration: InputDecoration(labelText: 'Cardholder Name'),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: IgnorePointer(
                child: TextField(
                  controller: _expirationDateController,
                  decoration: InputDecoration(labelText: 'Expiration Date'),
                ),
              ),
            ),
            TextField(
              controller: _cvvController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'CVV'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String cardNumber = _cardNumberController.text;
                String cardholderName = _cardholderNameController.text;
                String expirationDate = _expirationDateController.text;
                String cvv = _cvvController.text;

                print('Card Number: $cardNumber (String)');
                print('Cardholder Name: $cardholderName (String)');
                print('Expiration Date: $expirationDate (String)');
                print('CVV: $cvv (String)');

                if (cardNumber.isEmpty ||
                    cardholderName.isEmpty ||
                    expirationDate.isEmpty ||
                    cvv.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('All fields are required'),
                  ));
                } else if (!isNumeric(cardNumber)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Card number must be a number'),
                  ));
                } else if (!isNumeric(cvv) || cvv.length != 3) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('CVV must be a 3-digit number'),
                  ));
                } else {
                  _saveBankCard(cardNumber, cardholderName, expirationDate, cvv);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  bool isNumeric(String? str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }
}