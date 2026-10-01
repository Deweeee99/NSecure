import 'dart:convert';
import 'dart:io';

import 'package:aparthub_security/core/network/security_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authenticated JSON POST sends Bearer and locale before body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    String? authorization;
    String? acceptLanguage;
    String? contentType;
    String? body;

    final handled = server.first.then((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      acceptLanguage = request.headers.value('Accept-Language');
      contentType = request.headers.value(HttpHeaders.contentTypeHeader);
      body = await utf8.decoder.bind(request).join();

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..headers.set('Content-Language', 'id')
        ..write(jsonEncode({
          'status': 'success',
          'message': 'ok',
          'data': {'accepted': true},
        }));
      await request.response.close();
    });

    final client = IoSecurityApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}/api/security',
    )
      ..bearerToken = 'test-token'
      ..requestLanguageCode = 'id';

    final response = await client.post(
      '/visitor-access/validate',
      body: const {'code': 'RAW-QR-CODE'},
    );

    await handled;

    expect(authorization, 'Bearer test-token');
    expect(acceptLanguage, 'id');
    expect(contentType, contains('application/json'));
    expect(body, jsonEncode(const {'code': 'RAW-QR-CODE'}));
    expect(response['status'], 'success');
    expect(client.lastContentLanguage, 'id');
  });

  test('authenticated empty JSON POST also preserves Bearer header', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    String? authorization;

    final handled = server.first.then((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      await request.drain<void>();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'status': 'success',
          'message': 'ok',
          'data': null,
        }));
      await request.response.close();
    });

    final client = IoSecurityApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}/api/security',
    )..bearerToken = 'test-token';

    await client.post('/visitors/1/check-out');
    await handled;

    expect(authorization, 'Bearer test-token');
  });
}
