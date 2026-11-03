import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT in the platform secure store.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'kayflix.auth.token';

  final FlutterSecureStorage _storage;

  Future<String?> read() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == null || value.isEmpty) return null;
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      // Storage can be unavailable on some desktop/web setups; the session
      // still works for the current run.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Ignore.
    }
  }
}
