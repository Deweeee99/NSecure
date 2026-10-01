import 'package:aparthub_security/core/network/security_api_client.dart';
import 'package:aparthub_security/features/emergency/data/api/api_emergency_alert_repository.dart';
import 'package:aparthub_security/features/emergency/domain/models/emergency_alert_models.dart';
import 'package:aparthub_security/features/emergency/domain/repositories/emergency_alert_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiEmergencyAlertRepository', () {
    test('active queue uses canonical endpoint and Open status', () async {
      final client = _FakeEmergencyClient();
      client.getResponses['/emergency-alerts/active'] = _success(
        <Map<String, dynamic>>[_alertPayload()],
      );
      final repository = ApiEmergencyAlertRepository(client);

      final alerts = await repository.activeAlerts();

      expect(client.lastGetPath, '/emergency-alerts/active');
      expect(alerts, hasLength(1));
      expect(alerts.single.status, EmergencyAlertStatus.open);
      expect(alerts.single.modalRequired, isTrue);
      expect(alerts.single.takenByMe, isFalse);
    });

    test('acknowledge maps first-wins conflict without branching on message', () async {
      final client = _FakeEmergencyClient();
      client.postErrors['/emergency-alerts/12/acknowledge'] =
          const SecurityApiException(
        statusCode: 409,
        code: 'EMERGENCY_ALREADY_TAKEN',
        message: 'Alert SOS ini sudah diambil oleh security lain.',
      );
      final repository = ApiEmergencyAlertRepository(client);

      await expectLater(
        repository.acknowledge(12),
        throwsA(
          isA<EmergencyRepositoryException>().having(
            (error) => error.code,
            'code',
            EmergencyRepositoryFailureCode.alreadyTaken,
          ),
        ),
      );
    });

    test('resolve sends only optional notes and preserves server-owned state', () async {
      final client = _FakeEmergencyClient();
      client.postResponses['/emergency-alerts/12/resolve'] = _success(
        _alertPayload(
          status: 'Resolved',
          modalRequired: false,
          takenByMe: true,
        ),
      );
      final repository = ApiEmergencyAlertRepository(client);

      final alert = await repository.resolve(
        12,
        notes: ' Resident sudah aman. ',
      );

      expect(client.lastPostPath, '/emergency-alerts/12/resolve');
      expect(client.lastPostBody, <String, dynamic>{
        'notes': 'Resident sudah aman.',
      });
      expect(client.lastPostBody, isNot(containsPair('status', anything)));
      expect(client.lastPostBody, isNot(containsPair('resolved_at', anything)));
      expect(alert.status, EmergencyAlertStatus.resolved);
    });

    test('unknown wire status fails closed', () async {
      final client = _FakeEmergencyClient();
      client.getResponses['/emergency-alerts/12'] = _success(
        _alertPayload(status: 'Handling'),
      );
      final repository = ApiEmergencyAlertRepository(client);

      await expectLater(
        repository.findById(12),
        throwsA(
          isA<EmergencyRepositoryException>().having(
            (error) => error.code,
            'code',
            EmergencyRepositoryFailureCode.unknown,
          ),
        ),
      );
    });

    test('unauthenticated active queue maps to session-expiry failure', () async {
      final client = _FakeEmergencyClient();
      client.getErrors['/emergency-alerts/active'] = const SecurityApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Unauthenticated.',
      );
      final repository = ApiEmergencyAlertRepository(client);

      await expectLater(
        repository.activeAlerts(),
        throwsA(
          isA<EmergencyRepositoryException>().having(
            (error) => error.code,
            'code',
            EmergencyRepositoryFailureCode.unauthorized,
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _success(dynamic data) => <String, dynamic>{
      'status': 'success',
      'message': 'OK',
      'data': data,
    };

Map<String, dynamic> _alertPayload({
  String status = 'Open',
  bool modalRequired = true,
  bool takenByMe = false,
}) {
  return <String, dynamic>{
    'emergency_alert_id': 12,
    'alert_code': 'SOS-20260814-000012',
    'status': status,
    'message': 'Butuh bantuan segera.',
    'modal_required': modalRequired,
    'taken_by_me': takenByMe,
    'property': <String, dynamic>{
      'id': 1,
      'code': 'DEFAULT',
      'name': 'Aparthub Residence',
    },
    'resident': <String, dynamic>{
      'id': 101,
      'name': 'Budi Santoso',
      'mobile_no': '0812...',
    },
    'unit': <String, dynamic>{
      'id': 44,
      'code': 'A-101',
      'tower': 'Tower A',
      'floor': 1,
    },
    'triggered_at': '2026-08-14T13:15:00+07:00',
    'acknowledged_at': status == 'Open' ? null : '2026-08-14T13:16:00+07:00',
    'acknowledged_by': status == 'Open'
        ? null
        : <String, dynamic>{'id': 22, 'name': 'Security Officer'},
    'resolved_at': status == 'Resolved' ? '2026-08-14T13:25:00+07:00' : null,
    'resolved_by': status == 'Resolved'
        ? <String, dynamic>{'id': 22, 'name': 'Security Officer'}
        : null,
    'resolution_notes': status == 'Resolved' ? 'Resident sudah aman.' : null,
  };
}

class _FakeEmergencyClient implements SecurityApiClient {
  @override
  String? bearerToken = 'token';

  final getResponses = <String, Map<String, dynamic>>{};
  final postResponses = <String, Map<String, dynamic>>{};
  final getErrors = <String, SecurityApiException>{};
  final postErrors = <String, SecurityApiException>{};
  String? lastGetPath;
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) async {
    lastGetPath = path;
    final error = getErrors[path];
    if (error != null) throw error;
    final response = getResponses[path];
    if (response == null) throw StateError('No fake GET response for $path');
    return response;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    bool authenticated = true,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    final error = postErrors[path];
    if (error != null) throw error;
    final response = postResponses[path];
    if (response == null) throw StateError('No fake POST response for $path');
    return response;
  }
}
