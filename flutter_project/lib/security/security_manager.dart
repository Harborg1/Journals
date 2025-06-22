import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math';
import 'dart:typed_data';
class KeyManager {
  static final _storage = FlutterSecureStorage();
  static const _keyName = 'user_aes_key';

  static Future<encrypt.Key> getUserKey() async {
    String? base64Key = await _storage.read(key: _keyName);

    if (base64Key == null) {
      // Generate a new random 32-byte key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final key = encrypt.Key(Uint8List.fromList(keyBytes));

      base64Key = key.base64;
      await _storage.write(key: _keyName, value: base64Key);
    }

    return encrypt.Key.fromBase64(base64Key);
  }
}
