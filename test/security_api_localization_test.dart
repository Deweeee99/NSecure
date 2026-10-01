import 'dart:convert';
import 'dart:io';

import 'package:aparthub_security/core/network/security_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Security API sends normalized Accept-Language and reads Content-Language', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? acceptLanguage;
    server.listen((request) async {
      acceptLanguage = request.headers.value('Accept-Language');
      request.response.headers.contentType = ContentType.json;
      request.response.headers.set('Content-Language', 'id');
      request.response.write(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Profil Security dimuat.',
          'data': <String, dynamic>{},
        }),
      );
      await request.response.close();
    });

    final client = IoSecurityApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}/api/security',
    )..requestLanguageCode = 'id-ID';

    final response = await client.get('/me', authenticated: false);

    expect(response['status'], 'success');
    expect(acceptLanguage, 'id');
    expect(client.requestLanguageCode, 'id');
    expect(client.lastContentLanguage, 'id');

    await server.close(force: true);
  });

  test('multipart Patrol request keeps auth locale and exact photo field', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'aparthub-patrol-multipart-',
    );
    final photo = File('${tempDirectory.path}/checkpoint.jpg');
    await photo.writeAsString('photo-bytes');

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? method;
    String? path;
    String? contentType;
    String? acceptLanguage;
    String? authorization;
    String? requestBody;
    server.listen((request) async {
      method = request.method;
      path = request.uri.path;
      contentType = request.headers.value(HttpHeaders.contentTypeHeader);
      acceptLanguage = request.headers.value('Accept-Language');
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      requestBody = await utf8.decoder.bind(request).join();

      request.response.headers.contentType = ContentType.json;
      request.response.headers.set('Content-Language', 'id');
      request.response.write(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Patrol checkpoint completed.',
          'data': <String, dynamic>{},
        }),
      );
      await request.response.close();
    });

    try {
      final client = IoSecurityApiClient(
        baseUrl: 'http://${server.address.host}:${server.port}/api/security',
      )
        ..bearerToken = 'security-token'
        ..requestLanguageCode = 'id-ID';

      final response = await client.postMultipart(
        '/patrol/checkpoint-visits/101/complete',
        fields: const <String, String>{'notes': 'Area clear.'},
        files: <SecurityMultipartFile>[
          SecurityMultipartFile(
            fieldName: 'photo',
            path: photo.path,
            fileName: 'checkpoint.jpg',
            contentType: 'image/jpeg',
          ),
        ],
      );

      expect(response['status'], 'success');
      expect(method, 'POST');
      expect(
        path,
        '/api/security/patrol/checkpoint-visits/101/complete',
      );
      expect(contentType, startsWith('multipart/form-data; boundary='));
      expect(acceptLanguage, 'id');
      expect(authorization, 'Bearer security-token');
      expect(requestBody, contains('name="notes"'));
      expect(requestBody, contains('Area clear.'));
      expect(
        requestBody,
        contains('name="photo"; filename="checkpoint.jpg"'),
      );
      expect(requestBody, contains('Content-Type: image/jpeg'));
      expect(requestBody, contains('photo-bytes'));
      expect(client.lastContentLanguage, 'id');
    } finally {
      await server.close(force: true);
      await tempDirectory.delete(recursive: true);
    }
  });

  test('unsupported API locale falls back to en and error code remains canonical', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? acceptLanguage;
    server.listen((request) async {
      acceptLanguage = request.headers.value('Accept-Language');
      request.response.statusCode = HttpStatus.unprocessableEntity;
      request.response.headers.contentType = ContentType.json;
      request.response.headers.set('Content-Language', 'en-US');
      request.response.write(
        jsonEncode(<String, dynamic>{
          'status': 'error',
          'code': 'VALIDATION_ERROR',
          'message': 'The given data was invalid.',
          'errors': <String, dynamic>{},
        }),
      );
      await request.response.close();
    });

    final client = IoSecurityApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}/api/security',
    )..requestLanguageCode = 'fr-FR';

    await expectLater(
      client.post('/login', authenticated: false),
      throwsA(
        isA<SecurityApiException>()
            .having((error) => error.code, 'code', 'VALIDATION_ERROR')
            .having(
              (error) => error.message,
              'message',
              'The given data was invalid.',
            ),
      ),
    );

    expect(acceptLanguage, 'en');
    expect(client.requestLanguageCode, 'en');
    expect(client.lastContentLanguage, 'en');

    await server.close(force: true);
  });
}
