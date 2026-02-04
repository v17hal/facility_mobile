import "package:flutter_secure_storage/flutter_secure_storage.dart";

class SecureStore {
  SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  static SecureStore create() {
    const storage = FlutterSecureStorage();
    return SecureStore(storage);
  }

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);
}
