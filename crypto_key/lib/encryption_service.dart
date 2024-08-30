import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final _storage = FlutterSecureStorage();
  final _key = encrypt.Key.fromSecureRandom(32); // Adjust the length based on your needs
  final _iv = encrypt.IV.fromLength(16);         // 16 bytes IV for AES

  late final encrypt.Encrypter _encrypter;

  EncryptionService() {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  Future<String> encryptText(String text) async {
    final encrypted = _encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  Future<String> decryptText(String encryptedText) async {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }

  // Storing the encrypted data securely
  Future<void> storeEncryptedData(String key, String value) async {
    final encryptedValue = await encryptText(value);
    await _storage.write(key: key, value: encryptedValue);
  }

  // Retrieving the encrypted data and decrypting it
  Future<String?> retrieveEncryptedData(String key) async {
    final encryptedValue = await _storage.read(key: key);
    if (encryptedValue != null) {
      return await decryptText(encryptedValue);
    }
    return null;
  }

  // Encrypt and store a note
  Future<void> storeEncryptedNote(String key, String note) async {
    await storeEncryptedData(key, note);
  }

  // Retrieve and decrypt a note
  Future<String?> retrieveDecryptedNote(String key) async {
    return await retrieveEncryptedData(key);
  }

  // Encrypt and store an identity card
  Future<void> storeEncryptedIdentityCard(String key, String cardData) async {
    await storeEncryptedData(key, cardData);
  }

  // Retrieve and decrypt an identity card
  Future<String?> retrieveDecryptedIdentityCard(String key) async {
    return await retrieveEncryptedData(key);
  }

  // Encrypt and store a bank card
  Future<void> storeEncryptedBankCard(String key, String cardData) async {
    await storeEncryptedData(key, cardData);
  }

  // Retrieve and decrypt a bank card
  Future<String?> retrieveDecryptedBankCard(String key) async {
    return await retrieveEncryptedData(key);
  }
}
