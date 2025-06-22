
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1'); // 32 chars
  static final _iv = encrypt.IV.fromLength(16);

  static String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));

    return encrypter.encrypt(plainText, iv: _iv).base64;
  }

  static String decryptText(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    
    return encrypter.decrypt64(encryptedText, iv:_iv);
  }
}
