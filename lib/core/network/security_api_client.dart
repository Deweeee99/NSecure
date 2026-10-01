import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class SecurityApiException implements Exception {
  const SecurityApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.errors = const <String, dynamic>{},
    this.data,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic> errors;
  final dynamic data;

  @override
  String toString() => 'SecurityApiException($statusCode, $code): $message';
}

abstract interface class SecurityApiLocalization {
  String get requestLanguageCode;

  set requestLanguageCode(String value);

  String? get lastContentLanguage;
}

class SecurityMultipartFile {
  const SecurityMultipartFile({
    required this.fieldName,
    required this.path,
    required this.fileName,
    required this.contentType,
  });

  final String fieldName;
  final String path;
  final String fileName;
  final String contentType;
}

abstract interface class SecurityMultipartApiClient {
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const <String, String>{},
    List<SecurityMultipartFile> files = const <SecurityMultipartFile>[],
    bool authenticated = true,
  });
}

abstract interface class SecurityApiClient {
  String? get bearerToken;

  set bearerToken(String? value);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  });

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    bool authenticated = true,
  });
}

class IoSecurityApiClient
    implements SecurityApiClient, SecurityApiLocalization, SecurityMultipartApiClient {
  IoSecurityApiClient({
    required String baseUrl,
    HttpClient? httpClient,
    this.requestTimeout = const Duration(seconds: 20),
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _httpClient = httpClient ?? HttpClient();

  final String _baseUrl;
  final HttpClient _httpClient;
  final Duration requestTimeout;
  String? _bearerToken;
  String _requestLanguageCode = 'en';
  String? _lastContentLanguage;

  @override
  String? get bearerToken => _bearerToken;

  @override
  String get requestLanguageCode => _requestLanguageCode;

  @override
  set requestLanguageCode(String value) {
    _requestLanguageCode = _normalizeLanguageCode(value);
  }

  @override
  String? get lastContentLanguage => _lastContentLanguage;

  @override
  set bearerToken(String? value) {
    _bearerToken = value;
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) {
    return _send(
      'GET',
      path,
      query: query,
      authenticated: authenticated,
    );
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    bool authenticated = true,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const <String, String>{},
    List<SecurityMultipartFile> files = const <SecurityMultipartFile>[],
    bool authenticated = true,
  }) {
    return _sendMultipart(
      path,
      fields: fields,
      files: files,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> _sendMultipart(
    String path, {
    required Map<String, String> fields,
    required List<SecurityMultipartFile> files,
    required bool authenticated,
  }) async {
    _lastContentLanguage = null;
    try {
      final multipartFiles = <(SecurityMultipartFile, Uint8List)>[];
      for (final part in files) {
        final file = File(part.path);
        if (!await file.exists()) {
          throw const SecurityApiException(
            statusCode: 0,
            code: 'VALIDATION_ERROR',
            message: 'Selected photo is no longer available.',
          );
        }
        multipartFiles.add((part, await file.readAsBytes()));
      }

      final boundary =
          '----AparthubSecurity${DateTime.now().microsecondsSinceEpoch}';
      final body = BytesBuilder(copy: false);

      void addText(String value) {
        body.add(utf8.encode(value));
      }

      for (final entry in fields.entries) {
        addText('--$boundary\r\n');
        addText(
          'Content-Disposition: form-data; '
          'name="${_multipartHeaderValue(entry.key)}"\r\n\r\n',
        );
        addText(entry.value);
        addText('\r\n');
      }

      for (final item in multipartFiles) {
        final part = item.$1;
        final bytes = item.$2;
        addText('--$boundary\r\n');
        addText(
          'Content-Disposition: form-data; '
          'name="${_multipartHeaderValue(part.fieldName)}"; '
          'filename="${_multipartHeaderValue(part.fileName)}"\r\n',
        );
        addText(
          'Content-Type: ${_multipartContentType(part.contentType)}\r\n\r\n',
        );
        body.add(bytes);
        addText('\r\n');
      }
      addText('--$boundary--\r\n');

      final payload = body.takeBytes();
      final uri = _uri(path, const <String, String?>{});
      final request = await _httpClient.postUrl(uri).timeout(requestTimeout);

      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('Accept-Language', _requestLanguageCode);
      _applyAuthorization(request, authenticated);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      // The evidence contract is capped at 5 MB. Buffering the multipart body
      // lets us send a deterministic Content-Length instead of relying on
      // chunked transfer encoding, which is safer for PHP/Laravel multipart
      // parsing behind reverse proxies.
      request.contentLength = payload.length;
      request.add(payload);

      final response = await request.close().timeout(requestTimeout);
      return await _decodeResponse(response);
    } on SecurityApiException {
      rethrow;
    } on TimeoutException {
      throw const SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'Security API request timed out.',
      );
    } on FileSystemException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'VALIDATION_ERROR',
        message: error.message,
      );
    } on SocketException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: error.message,
      );
    } on HttpException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: error.message,
      );
    } on HandshakeException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: error.message,
      );
    } on FormatException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'SERVER_ERROR',
        message: error.message,
      );
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String?> query = const <String, String?>{},
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    _lastContentLanguage = null;
    try {
      final uri = _uri(path, query);
      final request = await (method == 'GET'
              ? _httpClient.getUrl(uri)
              : _httpClient.postUrl(uri))
          .timeout(requestTimeout);

      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('Accept-Language', _requestLanguageCode);
      _applyAuthorization(request, authenticated);

      // HttpClientRequest headers become immutable once request body bytes are
      // written. Authorization therefore has to be applied before write().
      // Previously POST requests with JSON bodies attempted to set the Bearer
      // header after write(), which surfaced as HttpException/NETWORK_ERROR on
      // real devices while GET requests continued to work.
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(requestTimeout);
      return await _decodeResponse(response);
    } on SecurityApiException {
      rethrow;
    } on TimeoutException {
      throw const SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'Security API request timed out.',
      );
    } on SocketException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: error.message,
      );
    } on HttpException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: error.message,
      );
    } on HandshakeException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: error.message,
      );
    } on FormatException catch (error) {
      throw SecurityApiException(
        statusCode: 0,
        code: 'SERVER_ERROR',
        message: error.message,
      );
    }
  }

  void _applyAuthorization(HttpClientRequest request, bool authenticated) {
    if (!authenticated) return;
    final token = _bearerToken;
    if (token == null || token.isEmpty) {
      throw const SecurityApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Security session is not authenticated.',
      );
    }
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }

  Future<Map<String, dynamic>> _decodeResponse(
    HttpClientResponse response,
  ) async {
    _lastContentLanguage = _normalizeContentLanguage(
      response.headers.value('Content-Language'),
    );
    final raw = await utf8.decoder.bind(response).join().timeout(requestTimeout);
    final payload = _decodeJsonObject(raw);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    throw SecurityApiException(
      statusCode: response.statusCode,
      code: payload['code'] as String? ?? 'SERVER_ERROR',
      message: payload['message'] as String? ?? 'Security API request failed.',
      errors: _mapOrEmpty(payload['errors']),
      data: payload['data'],
    );
  }

  static String _multipartContentType(String value) {
    final sanitized = value
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .trim();
    return sanitized.isEmpty ? 'application/octet-stream' : sanitized;
  }

  static String _multipartHeaderValue(String value) {
    return value
        .replaceAll('\\', '_')
        .replaceAll('"', '_')
        .replaceAll('\r', '')
        .replaceAll('\n', '');
  }

  Uri _uri(String path, Map<String, String?> query) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final filteredQuery = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null) filteredQuery[entry.key] = value;
    }
    return Uri.parse('$_baseUrl/$normalizedPath').replace(
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }

  static String _normalizeLanguageCode(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    final primary = normalized.split('-').first;
    return primary == 'id' || primary == 'en' ? primary : 'en';
  }

  static String? _normalizeContentLanguage(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    final primary = normalized.split('-').first;
    return primary == 'id' || primary == 'en' ? primary : null;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'baseUrl', 'must not be empty');
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'must be an absolute http/https URL',
      );
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'must not contain query parameters or a fragment',
      );
    }

    const isReleaseBuild = bool.fromEnvironment('dart.vm.product');
    if (isReleaseBuild && uri.scheme != 'https') {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'release builds require HTTPS',
      );
    }

    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static Map<String, dynamic> _decodeJsonObject(String raw) {
    if (raw.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Security API response must be a JSON object.',
      );
    }
    return decoded;
  }

  static Map<String, dynamic> _mapOrEmpty(dynamic value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }
}
