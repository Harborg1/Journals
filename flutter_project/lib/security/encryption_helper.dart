import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:math';
import 'security_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EncryptionHelper {
  
  static String encryptText(String plainText) {
    final keyBytes = SessionKeyManager().key;
    if (keyBytes == null) {
      throw Exception('Encryption key is not set in SessionKeyManager.');
    }

    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptText(String encryptedText) {
    final keyBytes = SessionKeyManager().key;
    if (keyBytes == null) {
      throw Exception('Encryption key is not set in SessionKeyManager.');
    }

    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid encrypted format. Expected "iv:encryptedText".');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

String generateSalt() {
  final rand = Random.secure();
  final saltBytes = List<int>.generate(16, (_) => rand.nextInt(256)); // 128-bit salt
  final salt = base64UrlEncode(saltBytes);

 return salt;
}

Future<List<int>> deriveKeyFromPasswordAndSalt(String password, String base64Salt) async {
  final saltBytes = base64Url.decode(base64Salt);

  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  final secretKey = await pbkdf2.deriveKeyFromPassword(
    password: password,
    nonce: saltBytes,
  );

  return await secretKey.extractBytes(); // 256-bit AES key
}

Future<String> fetchSaltFromFirestore(String userId) async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (!docSnapshot.exists) {
    throw Exception('User not found: $userId');
  }

  final data = docSnapshot.data();
  if (data == null || !data.containsKey('salt')) {
    throw Exception('Salt not found for user: $userId');
  }

  return data['salt'] as String;
}

