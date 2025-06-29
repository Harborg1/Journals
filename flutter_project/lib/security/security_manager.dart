class SessionKeyManager {
  static final SessionKeyManager _instance = SessionKeyManager._internal();
  factory SessionKeyManager() => _instance;
  SessionKeyManager._internal();

  List<int>? _key;
  void setKey(List<int> key) => _key = key;
  List<int>? get key => _key;
  void clear() => _key = null;
}
