import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecuritySessionStore {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> clearToken();
}

class FlutterSecureSecuritySessionStore implements SecuritySessionStore {
  FlutterSecureSecuritySessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? FlutterSecureStorage();

  static const _tokenKey = 'aparthub_security_sanctum_token_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

class MemorySecuritySessionStore implements SecuritySessionStore {
  MemorySecuritySessionStore({String? token}) {
    _token = token;
  }

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}
