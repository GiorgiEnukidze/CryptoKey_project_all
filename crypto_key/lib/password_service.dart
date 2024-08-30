import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordService {
  List<Map<String, String>> _passwords = [];

  // Ajouter un mot de passe
  void addPassword(String site, String username, String password) {
    final hashedPassword = _hashPassword(password);
    _passwords.add({
      'site': site,
      'username': username,
      'password': hashedPassword,
    });
  }

  // Supprimer un mot de passe
  void deletePassword(String site, String username) {
    _passwords.removeWhere((password) =>
        password['site'] == site && password['username'] == username);
  }

  // Liste des mots de passe
  List<Map<String, String>> getPasswords() {
    return _passwords;
  }

  // Vérifier la robustesse d'un mot de passe
  bool isPasswordStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#\$&*~]').hasMatch(password);
  }

  // Générer un mot de passe aléatoire
  String generatePassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$&*~';
    Random rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join('');
  }

  // Hacher un mot de passe
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Importer des mots de passe à partir d'un gestionnaire tiers
  void importPasswords(List<Map<String, String>> importedPasswords) {
    _passwords.addAll(importedPasswords);
  }
}
