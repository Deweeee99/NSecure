import '../../../../core/network/security_api_client.dart';
import '../../../../core/session/security_session_store.dart';
import '../../domain/models/security_user.dart';
import '../../domain/repositories/security_auth_repository.dart';

class ApiSecurityAuthRepository implements SecurityAuthRepository {
  ApiSecurityAuthRepository(
    this._client, {
    SecuritySessionStore? sessionStore,
  }) : _sessionStore =
            sessionStore ?? FlutterSecureSecuritySessionStore();

  final SecurityApiClient _client;
  final SecuritySessionStore _sessionStore;

  @override
  bool get hasSession => _client.bearerToken?.isNotEmpty ?? false;

  @override
  Future<SecurityUser> login({
    required String username,
    required String password,
  }) async {
    try {
      final envelope = await _client.post(
        '/login',
        authenticated: false,
        body: <String, dynamic>{
          'username': username,
          'password': password,
        },
      );
      final data = _requiredData(envelope);
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const FormatException('Login response data.token is required.');
      }

      final user = _decodeUser(data);
      await _sessionStore.writeToken(token);
      _client.bearerToken = token;
      return user;
    } on SecurityApiException catch (error) {
      throw _mapAuthError(error);
    } on FormatException catch (error) {
      throw SecurityAuthException(
        SecurityAuthFailureCode.unknown,
        message: error.message,
      );
    } on Object catch (error) {
      await _clearLocalSession();
      throw SecurityAuthException(
        SecurityAuthFailureCode.unknown,
        message: 'Unable to protect the Security session: $error',
      );
    }
  }

  @override
  Future<SecurityUser?> restoreSession() async {
    String? token;
    try {
      token = await _sessionStore.readToken();
    } on Object {
      await _clearLocalSession();
      return null;
    }

    if (token == null || token.isEmpty) {
      await _clearLocalSession();
      return null;
    }

    _client.bearerToken = token;
    try {
      return await me();
    } on SecurityAuthException catch (error) {
      if (error.code == SecurityAuthFailureCode.unauthenticated ||
          error.code == SecurityAuthFailureCode.forbidden) {
        await _clearLocalSession();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<SecurityUser> me() async {
    try {
      final envelope = await _client.get('/me');
      return _decodeUser(_requiredData(envelope));
    } on SecurityApiException catch (error) {
      throw _mapAuthError(error);
    } on FormatException catch (error) {
      throw SecurityAuthException(
        SecurityAuthFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (hasSession) {
        await _client.post('/logout');
      }
    } on SecurityApiException {
      // Fail closed locally even when the remote token is already invalid.
    } finally {
      await _clearLocalSession();
    }
  }

  Future<void> _clearLocalSession() async {
    _client.bearerToken = null;
    try {
      await _sessionStore.clearToken();
    } on Object {
      // The in-memory token is already cleared. The next restore attempt will
      // fail closed if the platform secure store remains unavailable.
    }
  }

  static SecurityUser _decodeUser(Map<String, dynamic> data) {
    final defaultPropertyRaw = data['default_property'];
    final defaultProperty = defaultPropertyRaw is Map<String, dynamic>
        ? _decodeProperty(defaultPropertyRaw)
        : null;
    final propertiesRaw = data['properties'];
    final properties = propertiesRaw is List
        ? propertiesRaw
            .whereType<Map<String, dynamic>>()
            .map(_decodeProperty)
            .toList(growable: false)
        : defaultProperty == null
            ? const <SecurityProperty>[]
            : <SecurityProperty>[defaultProperty];
    return SecurityUser(
      id: '${data['id']}',
      name: data['name'] as String? ?? 'Security User',
      username: data['username'] as String? ?? '',
      postName: data['role'] as String? ?? 'Security',
      propertyName: defaultProperty?.name ?? 'Property unavailable',
      active: data['is_active'] == true,
      defaultPropertyId: defaultProperty?.id,
      properties: properties,
    );
  }

  static SecurityProperty _decodeProperty(Map<String, dynamic> data) {
    final id = data['id'];
    if (id is! num) {
      throw const FormatException('Security property id is required.');
    }
    final code = data['code'];
    final name = data['name'];
    if (code is! String || code.isEmpty || name is! String || name.isEmpty) {
      throw const FormatException('Security property code/name is required.');
    }
    return SecurityProperty(
      id: id.toInt(),
      code: code,
      name: name,
      isDefault: data['is_default'] == true,
    );
  }

  static Map<String, dynamic> _requiredData(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Security API data must be an object.');
    }
    return data;
  }

  static SecurityAuthException _mapAuthError(SecurityApiException error) {
    final code = switch (error.code) {
      'SECURITY_INVALID_CREDENTIALS' =>
        SecurityAuthFailureCode.invalidCredentials,
      'UNAUTHENTICATED' => SecurityAuthFailureCode.unauthenticated,
      'FORBIDDEN' => SecurityAuthFailureCode.forbidden,
      'SECURITY_PROPERTY_UNAVAILABLE' => SecurityAuthFailureCode.forbidden,
      'VALIDATION_ERROR' => SecurityAuthFailureCode.validation,
      'NETWORK_ERROR' || 'NETWORK_TIMEOUT' => SecurityAuthFailureCode.network,
      _ => SecurityAuthFailureCode.unknown,
    };
    return SecurityAuthException(code, message: error.message);
  }
}
