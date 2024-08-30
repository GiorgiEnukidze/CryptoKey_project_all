import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'password_list_page.dart';

class TwoFactorPage extends StatefulWidget {
  final String code2FA;

  TwoFactorPage({required this.code2FA});

  @override
  _TwoFactorPageState createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  final TextEditingController _codeController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  void _verifyCode(BuildContext context) async {
    if (_codeController.text == widget.code2FA) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('2FA verification successful'),
      ));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PasswordListPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invalid 2FA code'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 2FA code sent to your email',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(labelText: '2FA Code'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter the 2FA code';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _verifyCode(context),
              child: Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
