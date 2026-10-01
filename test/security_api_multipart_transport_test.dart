import 'dart:convert';
import 'dart:io';

import 'package:nsecure/core/network/security_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multipart checkpoint upload sends Content-Length and canonical photo part',
      () async {
    final temp = await Directory.systemTemp.createTemp(
      'aparthub-security-multipart-test',
    );
    addTearDown(() => temp.delete(recursive: true));

    final photo = File('${temp.path}${Platform.pathSeparator}checkpoint.jpg');
    await photo.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    String? authorization;
    String? contentType;
    int? contentLength;
    String? rawBody;

    final handled = server.first.then((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      contentType = request.headers.value(HttpHeaders.contentTypeHeader);
      contentLength = request.contentLength;
      final bytes = await request.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      rawBody = latin1.decode(bytes, allowInvalid: true);

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'OK',
          'data': <String, dynamic>{},
        }));
      await request.response.close();
    });

    final client = IoSecurityApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}/api/security',
    )
      ..bearerToken = 'token'
      ..requestLanguageCode = 'en';

    await client.postMultipart(
      '/patrol/checkpoint-visits/102/complete',
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
    await handled;

    expect(authorization, 'Bearer token');
    expect(contentType, startsWith('multipart/form-data; boundary='));
    expect(contentLength, greaterThan(0));
    expect(rawBody, contains('name="notes"'));
    expect(rawBody, contains('Area clear.'));
    expect(rawBody, contains('name="photo"; filename="checkpoint.jpg"'));
    expect(rawBody, contains('Content-Type: image/jpeg'));
  });
}
