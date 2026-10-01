import 'package:nsecure/core/network/security_api_client.dart';
import 'package:nsecure/features/visitor/data/api/api_visitor_repository.dart';
import 'package:nsecure/features/visitor/domain/models/visitor_visit.dart';
import 'package:nsecure/features/visitor/domain/repositories/visitor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiVisitorRepository', () {
    test('decodes canonical Visitor wire values and nullable fields', () async {
      final client = _FakeClient();
      client.getResponses['/visitors/123'] = _success(_visitorPayload());
      final repository = ApiVisitorRepository(client);

      final visit = await repository.findByVisitId('123');

      expect(visit, isNotNull);
      expect(visit!.visitId, '123');
      expect(visit.visitorId, '123');
      expect(visit.status, VisitorStatus.approved);
      expect(visit.checkedInBy, isNull);
      expect(visit.identityPhotoUrl, contains('/identity-photo'));
    });


    test('backend action capabilities override Approved/Checked In status inference', () async {
      final client = _FakeClient();
      client.getResponses['/visitors/123'] = _success(
        _visitorPayload(
          status: 'Approved',
          canCheckIn: false,
          canCheckOut: false,
        ),
      );
      final repository = ApiVisitorRepository(client);

      final visit = await repository.findByVisitId('123');

      expect(visit, isNotNull);
      expect(visit!.status, VisitorStatus.approved);
      expect(visit.canCheckIn, isFalse);
      expect(visit.canCheckOut, isFalse);
    });

    test('QR validation sends opaque code unchanged and uses returned full payload', () async {
      final client = _FakeClient();
      client.postResponses['/visitor-access/validate'] = _success(
        <String, dynamic>{
          'is_valid': true,
          'reason': null,
          ..._visitorPayload(),
        },
      );
      final repository = ApiVisitorRepository(client);

      final visit = await repository.verifyQrPayload('Opaque-Code-Aa1');

      expect(visit.visitId, '123');
      expect(visit.visitorName, 'Budi Santoso');
      expect(client.lastPostBody?['code'], 'Opaque-Code-Aa1');
      expect(client.getPaths, isEmpty);
    });

    test('QR Check-In uses qr verification method and raw credential', () async {
      final client = _FakeClient();
      client.postResponses['/visitors/123/check-in'] = _success(
        _visitorPayload(
          status: 'Checked In',
          checkedInAt: '2026-08-12T10:20:05+07:00',
          checkedInBy: <String, dynamic>{'id': 12, 'name': 'Front Desk Security'},
        ),
      );
      final repository = ApiVisitorRepository(client);

      final visit = await repository.checkIn(
        '123',
        method: VisitorVerificationMethod.qr,
        qrPayload: 'CANONICAL_ACCESS_CODE',
      );

      expect(visit.status, VisitorStatus.checkedIn);
      expect(visit.checkedInBy, 'Front Desk Security');
      expect(client.lastPostBody?['verification_method'], 'qr');
      expect(client.lastPostBody?['code'], 'CANONICAL_ACCESS_CODE');
      expect(client.lastPostBody?.containsKey('access_card_number'), isFalse);
    });

    test('manual Check-In does not send a QR credential', () async {
      final client = _FakeClient();
      client.postResponses['/visitors/123/check-in'] = _success(
        _visitorPayload(status: 'Checked In'),
      );
      final repository = ApiVisitorRepository(client);

      await repository.checkIn('123');

      expect(client.lastPostBody?['verification_method'], 'manual');
      expect(client.lastPostBody?.containsKey('code'), isFalse);
    });

    test('ambiguous Check-In transport failure reconciles authoritative Visitor state', () async {
      final client = _FakeClient();
      client.postErrors['/visitors/123/check-in'] = const SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'Security API request timed out.',
      );
      client.getResponses['/visitors/123'] = _success(
        _visitorPayload(
          status: 'Checked In',
          checkedInAt: '2026-08-20T17:55:00+07:00',
          checkedInBy: <String, dynamic>{'id': 10, 'name': 'Security Officer'},
        ),
      );
      final repository = ApiVisitorRepository(client);

      final visit = await repository.checkIn('123');

      expect(visit.status, VisitorStatus.checkedIn);
      expect(client.getPaths, contains('/visitors/123'));
    });

    test('ambiguous Check-In transport failure stays retryable when state did not change', () async {
      final client = _FakeClient();
      client.postErrors['/visitors/123/check-in'] = const SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'Connection closed unexpectedly.',
      );
      client.getResponses['/visitors/123'] = _success(
        _visitorPayload(status: 'Approved'),
      );
      final repository = ApiVisitorRepository(client);

      await expectLater(
        repository.checkIn('123'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.network,
          ),
        ),
      );
    });

    test('ambiguous Check-Out transport failure reconciles authoritative Visitor state', () async {
      final client = _FakeClient();
      client.postErrors['/visitors/123/check-out'] = const SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'Security API request timed out.',
      );
      client.getResponses['/visitors/123'] = _success(
        _visitorPayload(status: 'Checked Out'),
      );
      final repository = ApiVisitorRepository(client);

      final visit = await repository.checkOut('123');

      expect(visit.status, VisitorStatus.checkedOut);
      expect(client.getPaths, contains('/visitors/123'));
    });

    test('network failures map to retryable frontend failure', () async {
      final client = _FakeClient();
      client.getErrors['/visitors/search'] = const SecurityApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'Security API request timed out.',
      );
      final repository = ApiVisitorRepository(client);

      await expectLater(
        repository.search('VST-01K'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.network,
          ),
        ),
      );
    });

    test('stable backend errors map to frontend repository failures', () async {
      final client = _FakeClient();
      client.postErrors['/visitors/123/check-in'] = const SecurityApiException(
        statusCode: 422,
        code: 'VISITOR_NOT_VALID_TODAY',
        message: 'Visit is not valid today.',
      );
      final repository = ApiVisitorRepository(client);

      await expectLater(
        repository.checkIn('123'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.notValidToday,
          ),
        ),
      );
    });

    test('blacklisted Visitor maps from stable backend code', () async {
      final client = _FakeClient();
      client.postErrors['/visitor-access/validate'] = const SecurityApiException(
        statusCode: 422,
        code: 'VISITOR_BLACKLISTED',
        message: 'Visitor is blacklisted.',
      );
      final repository = ApiVisitorRepository(client);

      await expectLater(
        repository.verifyQrPayload('BLACKLISTED-CODE'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.blacklisted,
          ),
        ),
      );
    });

    test('history follows backend has_more pagination', () async {
      final client = _FakeClient();
      client.pagedHistory = <Map<String, dynamic>>[
        <String, dynamic>{
          'status': 'success',
          'message': 'Verification history loaded.',
          'data': <Map<String, dynamic>>[_visitorPayload(status: 'Checked In')],
          'meta': <String, dynamic>{'has_more': true},
        },
        <String, dynamic>{
          'status': 'success',
          'message': 'Verification history loaded.',
          'data': <Map<String, dynamic>>[_visitorPayload(id: 124, status: 'Expired')],
          'meta': <String, dynamic>{'has_more': false},
        },
      ];
      final repository = ApiVisitorRepository(client);

      final history = await repository.history();

      expect(history, hasLength(2));
      expect(client.historyPagesRequested, <String>['1', '2']);
    });
  });
}

Map<String, dynamic> _success(dynamic data) => <String, dynamic>{
      'status': 'success',
      'message': 'OK',
      'data': data,
    };

Map<String, dynamic> _visitorPayload({
  int id = 123,
  String status = 'Approved',
  String? checkedInAt,
  Map<String, dynamic>? checkedInBy,
  bool? canCheckIn,
  bool? canCheckOut,
}) {
  return <String, dynamic>{
    'visit_id': id,
    'visit_code': 'VST-01K$id',
    'visitor_id': id,
    'visitor_name': 'Budi Santoso',
    'visitor_phone': '081234567890',
    'resident_name': 'Andi Pratama',
    'property_name': 'Aparthub Residence',
    'tower_name': 'Tower A',
    'unit_name': 'A-1205',
    'purpose': 'Personal Visit',
    'scheduled_at': '2026-08-12T10:15:00+07:00',
    'valid_from': '2026-08-12T00:00:00+07:00',
    'valid_until': '2026-08-12T23:59:59+07:00',
    'status': status,
    'checked_in_at': checkedInAt,
    'checked_out_at': null,
    'checked_in_by': checkedInBy,
    'checked_out_by': null,
    'identity_photo_url': 'https://example.test/api/security/visitors/$id/identity-photo',
    'can_check_in': canCheckIn ?? status == 'Approved',
    'can_check_out': canCheckOut ?? status == 'Checked In',
  };
}

class _FakeClient implements SecurityApiClient {
  @override
  String? bearerToken = 'token';

  final getResponses = <String, Map<String, dynamic>>{};
  final postResponses = <String, Map<String, dynamic>>{};
  final getErrors = <String, SecurityApiException>{};
  final postErrors = <String, SecurityApiException>{};
  List<Map<String, dynamic>>? pagedHistory;
  final historyPagesRequested = <String>[];
  final getPaths = <String>[];
  Map<String, dynamic>? lastPostBody;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) async {
    getPaths.add(path);
    final error = getErrors[path];
    if (error != null) throw error;
    if (path == '/verification-history' && pagedHistory != null) {
      historyPagesRequested.add(query['page'] ?? '');
      return pagedHistory!.removeAt(0);
    }
    return getResponses[path]!;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    bool authenticated = true,
  }) async {
    lastPostBody = body;
    final error = postErrors[path];
    if (error != null) throw error;
    return postResponses[path]!;
  }
}
