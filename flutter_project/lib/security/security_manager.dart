import 'dart:typed_data';

class SessionKeyManager {
  static final SessionKeyManager _instance = SessionKeyManager._internal();
  factory SessionKeyManager() => _instance;
  SessionKeyManager._internal();

  Uint8List? _key;
  void setKey(Uint8List key) => _key = key;
  Uint8List? get key => _key;
  void clear() => _key = null;
}
