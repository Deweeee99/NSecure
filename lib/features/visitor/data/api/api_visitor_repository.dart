import '../../../../core/network/security_api_client.dart';
import '../../domain/models/visitor_visit.dart';
import '../../domain/repositories/visitor_repository.dart';
import 'visitor_api_decoder.dart';

class ApiVisitorRepository implements VisitorRepository {
  ApiVisitorRepository(this._client);

  final SecurityApiClient _client;

  @override
  Future<List<VisitorVisit>> search(String query) async {
    try {
      final envelope = await _client.get(
        '/visitors/search',
        query: <String, String?>{
          'q': query,
          'limit': '20',
        },
      );
      return _decodeList(envelope['data']);
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw VisitorRepositoryException(
        VisitorRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<VisitorVisit> verifyQrPayload(String qrPayload) async {
    try {
      final envelope = await _client.post(
        '/visitor-access/validate',
        body: <String, dynamic>{'code': qrPayload},
      );
      final data = _requiredObject(envelope['data']);
      if (data['is_valid'] != true) {
        throw const VisitorRepositoryException(
          VisitorRepositoryFailureCode.invalidQr,
        );
      }

      // The current Security contract returns the full Visitor payload from
      // /visitor-access/validate. Decode that authoritative response directly
      // instead of introducing a second GET that can fail after a valid scan.
      return VisitorApiDecoder.decode(data);
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw VisitorRepositoryException(
        VisitorRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<VisitorVisit?> findByVisitId(String visitId) async {
    try {
      final envelope = await _client.get('/visitors/$visitId');
      return VisitorApiDecoder.decode(_requiredObject(envelope['data']));
    } on SecurityApiException catch (error) {
      if (error.code == 'VISITOR_NOT_FOUND') return null;
      throw _mapError(error);
    } on FormatException catch (error) {
      throw VisitorRepositoryException(
        VisitorRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<VisitorVisit> checkIn(
    String visitId, {
    VisitorVerificationMethod method = VisitorVerificationMethod.manual,
    String? qrPayload,
  }) async {
    if (method == VisitorVerificationMethod.qr && qrPayload == null) {
      throw const VisitorRepositoryException(
        VisitorRepositoryFailureCode.validation,
        message: 'QR payload is required for QR Check-In.',
      );
    }

    final body = <String, dynamic>{
      'verification_method':
          method == VisitorVerificationMethod.qr ? 'qr' : 'manual',
      if (method == VisitorVerificationMethod.qr) 'code': qrPayload,
    };

    try {
      final envelope = await _client.post(
        '/visitors/$visitId/check-in',
        body: body,
      );
      return VisitorApiDecoder.decode(_requiredObject(envelope['data']));
    } on SecurityApiException catch (error) {
      if (_isAmbiguousNetworkFailure(error)) {
        final reconciled = await _reconcileVisitorState(
          visitId,
          expectedStatus: VisitorStatus.checkedIn,
        );
        if (reconciled != null) return reconciled;
      }
      throw _mapError(error);
    } on FormatException catch (error) {
      throw VisitorRepositoryException(
        VisitorRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<VisitorVisit> checkOut(String visitId) async {
    try {
      final envelope = await _client.post(
        '/visitors/$visitId/check-out',
      );
      return VisitorApiDecoder.decode(_requiredObject(envelope['data']));
    } on SecurityApiException catch (error) {
      if (_isAmbiguousNetworkFailure(error)) {
        final reconciled = await _reconcileVisitorState(
          visitId,
          expectedStatus: VisitorStatus.checkedOut,
        );
        if (reconciled != null) return reconciled;
      }
      throw _mapError(error);
    } on FormatException catch (error) {
      throw VisitorRepositoryException(
        VisitorRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  Future<VisitorVisit?> _reconcileVisitorState(
    String visitId, {
    required VisitorStatus expectedStatus,
  }) async {
    try {
      final envelope = await _client.get('/visitors/$visitId');
      final current =
          VisitorApiDecoder.decode(_requiredObject(envelope['data']));
      return current.status == expectedStatus ? current : null;
    } on Object {
      // Never retry the mutation automatically. If read-back also fails,
      // preserve the original network failure so the UI can recover cleanly.
      return null;
    }
  }

  static bool _isAmbiguousNetworkFailure(SecurityApiException error) {
    return error.code == 'NETWORK_ERROR' || error.code == 'NETWORK_TIMEOUT';
  }

  @override
  Future<List<VisitorVisit>> history() async {
    final visits = <VisitorVisit>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      try {
        final envelope = await _client.get(
          '/verification-history',
          query: <String, String?>{
            'page': '$page',
            'per_page': '100',
          },
        );
        visits.addAll(_decodeList(envelope['data']));
        final meta = envelope['meta'];
        hasMore = meta is Map<String, dynamic> && meta['has_more'] == true;
        page += 1;
        if (page > 100) {
          throw const FormatException('Verification history pagination exceeded safety limit.');
        }
      } on SecurityApiException catch (error) {
        throw _mapError(error);
      } on FormatException catch (error) {
        throw VisitorRepositoryException(
          VisitorRepositoryFailureCode.unknown,
          message: error.message,
        );
      }
    }

    return visits;
  }

  static List<VisitorVisit> _decodeList(dynamic data) {
    if (data is! List) {
      throw const FormatException('Security Visitor list data must be an array.');
    }
    return data
        .map((item) => VisitorApiDecoder.decode(_requiredObject(item)))
        .toList(growable: false);
  }

  static Map<String, dynamic> _requiredObject(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Security Visitor data must be an object.');
    }
    return value;
  }

  static VisitorRepositoryException _mapError(SecurityApiException error) {
    final code = switch (error.code) {
      'UNAUTHENTICATED' => VisitorRepositoryFailureCode.unauthorized,
      'SECURITY_INVALID_CREDENTIALS' => VisitorRepositoryFailureCode.unauthorized,
      'FORBIDDEN' => VisitorRepositoryFailureCode.forbidden,
      'SECURITY_PROPERTY_UNAVAILABLE' => VisitorRepositoryFailureCode.forbidden,
      'VISITOR_NOT_FOUND' => VisitorRepositoryFailureCode.visitNotFound,
      'VISITOR_QR_INVALID' => VisitorRepositoryFailureCode.invalidQr,
      'VISITOR_EXPIRED' => VisitorRepositoryFailureCode.expiredVisit,
      'VISITOR_NOT_VALID_TODAY' => VisitorRepositoryFailureCode.notValidToday,
      'VISITOR_PENDING_APPROVAL' => VisitorRepositoryFailureCode.pendingApproval,
      'VISITOR_REJECTED' => VisitorRepositoryFailureCode.rejectedVisit,
      'VISITOR_BLACKLISTED' => VisitorRepositoryFailureCode.blacklisted,
      'VISITOR_CANCELLED' => VisitorRepositoryFailureCode.cancelledVisit,
      'VISITOR_ALREADY_CHECKED_IN' => VisitorRepositoryFailureCode.alreadyCheckedIn,
      'VISITOR_ALREADY_CHECKED_OUT' => VisitorRepositoryFailureCode.alreadyCheckedOut,
      'VISITOR_INVALID_STATE' => VisitorRepositoryFailureCode.invalidState,
      'VALIDATION_ERROR' => VisitorRepositoryFailureCode.validation,
      'NETWORK_ERROR' || 'NETWORK_TIMEOUT' => VisitorRepositoryFailureCode.network,
      _ => VisitorRepositoryFailureCode.unknown,
    };
    return VisitorRepositoryException(code, message: error.message);
  }
}
