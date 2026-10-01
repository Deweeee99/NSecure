import 'package:nsecure/core/network/security_api_client.dart';
import 'package:nsecure/core/session/security_session_store.dart';
import 'package:nsecure/features/security/data/api/api_security_auth_repository.dart';
import 'package:nsecure/features/security/domain/repositories/security_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login stores Sanctum token securely and maps Security user', () async {
    final client = _FakeClient();
    final store = MemorySecuritySessionStore();
    client.postResponse = <String, dynamic>{
      'status': 'success',
      'message': 'Login security berhasil.',
      'data': _profileData(token: '1|secret-token'),
    };
    final repository = ApiSecurityAuthRepository(
      client,
      sessionStore: store,
    );

    final user = await repository.login(
      username: 'security.frontdesk',
      password: 'secret-pass',
    );

    expect(client.bearerToken, '1|secret-token');
    expect(await store.readToken(), '1|secret-token');
    expect(user.id, '12');
    expect(user.name, 'Front Desk Security');
    expect(user.propertyName, 'Aparthub SITE-A');
    expect(user.defaultPropertyId, 1);
    expect(user.properties, hasLength(1));
    expect(user.properties.single.code, 'SITE-A');
    expect(repository.hasSession, isTrue);
  });

  test('restoreSession loads secure token then validates it through /me', () async {
    final client = _FakeClient()
      ..getResponse = <String, dynamic>{
        'status': 'success',
        'message': 'Security profile loaded.',
        'data': _profileData(),
      };
    final store = MemorySecuritySessionStore(token: '1|persisted-token');
    final repository = ApiSecurityAuthRepository(
      client,
      sessionStore: store,
    );

    final user = await repository.restoreSession();

    expect(user?.username, 'security.frontdesk');
    expect(client.bearerToken, '1|persisted-token');
    expect(client.lastGetPath, '/me');
  });

  test('invalid persisted token fails closed and is removed', () async {
    final client = _FakeClient()
      ..getError = const SecurityApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Unauthenticated.',
      );
    final store = MemorySecuritySessionStore(token: 'expired-token');
    final repository = ApiSecurityAuthRepository(
      client,
      sessionStore: store,
    );

    final user = await repository.restoreSession();

    expect(user, isNull);
    expect(client.bearerToken, isNull);
    expect(await store.readToken(), isNull);
  });

  test('logout clears local secure session even if remote logout fails', () async {
    final client = _FakeClient()
      ..bearerToken = '1|persisted-token'
      ..postError = const SecurityApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Unauthenticated.',
      );
    final store = MemorySecuritySessionStore(token: '1|persisted-token');
    final repository = ApiSecurityAuthRepository(
      client,
      sessionStore: store,
    );

    await repository.logout();

    expect(client.bearerToken, isNull);
    expect(await store.readToken(), isNull);
  });

  test('invalid credentials map to stable auth failure', () async {
    final client = _FakeClient()
      ..postError = const SecurityApiException(
        statusCode: 401,
        code: 'SECURITY_INVALID_CREDENTIALS',
        message: 'Kredensial security tidak valid.',
      );
    final repository = ApiSecurityAuthRepository(
      client,
      sessionStore: MemorySecuritySessionStore(),
    );

    await expectLater(
      repository.login(username: 'x', password: 'y'),
      throwsA(
        isA<SecurityAuthException>().having(
          (error) => error.code,
          'code',
          SecurityAuthFailureCode.invalidCredentials,
        ),
      ),
    );
  });

  test('network timeout maps to network auth failure', () async {
    final client = _FakeClient()
      ..postError = const SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'Security API request timed out.',
      );
    final repository = ApiSecurityAuthRepository(
      client,
      sessionStore: MemorySecuritySessionStore(),
    );

    await expectLater(
      repository.login(username: 'x', password: 'y'),
      throwsA(
        isA<SecurityAuthException>().having(
          (error) => error.code,
          'code',
          SecurityAuthFailureCode.network,
        ),
      ),
    );
  });
}

Map<String, dynamic> _profileData({String? token}) {
  final data = <String, dynamic>{
    'id': 12,
    'name': 'Front Desk Security',
    'username': 'security.frontdesk',
    'role': 'Security',
    'is_active': true,
    'default_property': <String, dynamic>{
      'id': 1,
      'code': 'SITE-A',
      'name': 'Aparthub SITE-A',
      'is_default': true,
    },
    'properties': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'code': 'SITE-A',
        'name': 'Aparthub SITE-A',
        'is_default': true,
      },
    ],
  };
  if (token != null) {
    data['token'] = token;
    data['token_type'] = 'Bearer';
  }
  return data;
}

class _FakeClient implements SecurityApiClient {
  @override
  String? bearerToken;
  Map<String, dynamic>? getResponse;
  Map<String, dynamic>? postResponse;
  SecurityApiException? getError;
  SecurityApiException? postError;
  String? lastGetPath;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) async {
    lastGetPath = path;
    final error = getError;
    if (error != null) throw error;
    return getResponse!;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    bool authenticated = true,
  }) async {
    final error = postError;
    if (error != null) throw error;
    return postResponse!;
  }
}
