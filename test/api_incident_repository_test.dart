import 'package:aparthub_security/core/network/security_api_client.dart';
import 'package:aparthub_security/features/incident/data/api/api_incident_repository.dart';
import 'package:aparthub_security/features/incident/domain/models/incident_models.dart';
import 'package:aparthub_security/features/incident/domain/repositories/incident_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiIncidentRepository', () {
    test('dashboard decodes canonical incident counters', () async {
      final client = _FakeIncidentClient();
      client.getResponses['/incidents/dashboard'] = _success(<String, dynamic>{
        'open': 3,
        'critical': 1,
        'escalated': 1,
        'assigned_to_me': 1,
        'reported_by_me': 4,
        'resolved_today': 2,
      });
      final repository = ApiIncidentRepository(client);

      final dashboard = await repository.dashboard();

      expect(dashboard.open, 3);
      expect(dashboard.critical, 1);
      expect(dashboard.resolvedToday, 2);
      expect(client.lastGetPath, '/incidents/dashboard');
    });

    test('detail decodes exact statuses severity capability and timeline', () async {
      final client = _FakeIncidentClient();
      client.getResponses['/incidents/91'] = _success(
        _incidentPayload(includeTimeline: true),
      );
      final repository = ApiIncidentRepository(client);

      final incident = await repository.findById(91);

      expect(incident, isNotNull);
      expect(incident!.status, IncidentStatus.open);
      expect(incident.severity, IncidentSeverity.high);
      expect(incident.canAcknowledge, isTrue);
      expect(incident.canStart, isTrue);
      expect(incident.timeline, hasLength(1));
      expect(incident.timeline.first.toStatus, IncidentStatus.acknowledged);
    });

    test('active list follows has_more pagination and canonical query', () async {
      final client = _FakeIncidentClient();
      client.pagedResponses['/incidents'] = <Map<String, dynamic>>[
        _listEnvelope(<Map<String, dynamic>>[_incidentPayload()], true),
        _listEnvelope(
          <Map<String, dynamic>>[
            _incidentPayload(id: 92, severity: 'Critical', status: 'In Progress'),
          ],
          false,
        ),
      ];
      final repository = ApiIncidentRepository(client);

      final incidents = await repository.incidents(
        severity: IncidentSeverity.high,
        query: 'exit',
      );

      expect(incidents, hasLength(2));
      expect(client.pagesRequested, <String>['1', '2']);
      expect(client.lastGetQuery?['scope'], 'mine');
      expect(client.lastGetQuery?['severity'], 'High');
      expect(client.lastGetQuery?['q'], 'exit');
      expect(client.lastGetQuery?['per_page'], '100');
    });

    test('create sends only documented context and incident fields', () async {
      final client = _FakeIncidentClient();
      client.postResponses['/incidents'] = _success(<String, dynamic>{});
      final repository = ApiIncidentRepository(client);

      await repository.createIncident(
        const IncidentCreateInput(
          propertyId: 3,
          title: ' Emergency exit obstructed ',
          description: ' Boxes block the emergency exit. ',
          category: ' Safety ',
          severity: IncidentSeverity.high,
          location: ' East Emergency Exit ',
        ),
      );

      expect(client.lastPostPath, '/incidents');
      expect(client.lastPostBody, <String, dynamic>{
        'property_id': 3,
        'title': 'Emergency exit obstructed',
        'description': 'Boxes block the emergency exit.',
        'category': 'Safety',
        'severity': 'High',
        'location': 'East Emergency Exit',
      });
      expect(client.lastPostBody, isNot(containsPair('status', anything)));
      expect(client.lastPostBody, isNot(containsPair('reported_at', anything)));
      expect(client.lastPostBody, isNot(containsPair('assigned_to_user_id', anything)));
    });

    test('create from Patrol sends checkpoint context without manufacturing proof', () async {
      final client = _FakeIncidentClient();
      client.postResponses['/incidents'] = _success(<String, dynamic>{});
      final repository = ApiIncidentRepository(client);

      await repository.createIncident(
        const IncidentCreateInput(
          patrolCheckpointVisitId: 14,
          title: 'Water leak found',
          description: 'Water leak observed during patrol.',
          category: 'Safety',
          severity: IncidentSeverity.medium,
        ),
      );

      expect(client.lastPostBody?['patrol_checkpoint_visit_id'], 14);
      expect(client.lastPostBody, isNot(containsPair('scan_token', anything)));
      expect(client.lastPostBody, isNot(containsPair('gps', anything)));
      expect(client.lastPostBody, isNot(containsPair('photo', anything)));
    });

    test('acknowledge posts optional notes then reloads canonical detail', () async {
      final client = _FakeIncidentClient();
      client.postResponses['/incidents/91/acknowledge'] = _success(null);
      client.getResponses['/incidents/91'] = _success(
        _incidentPayload(status: 'Acknowledged', canAcknowledge: false),
      );
      final repository = ApiIncidentRepository(client);

      final incident = await repository.acknowledge(
        91,
        notes: ' Front desk acknowledged. ',
      );

      expect(client.lastPostPath, '/incidents/91/acknowledge');
      expect(client.lastPostBody, <String, dynamic>{
        'notes': 'Front desk acknowledged.',
      });
      expect(incident.status, IncidentStatus.acknowledged);
    });

    test('resolve requires notes before network call', () async {
      final repository = ApiIncidentRepository(_FakeIncidentClient());

      await expectLater(
        repository.resolve(91, notes: '   '),
        throwsA(
          isA<IncidentRepositoryException>().having(
            (error) => error.code,
            'code',
            IncidentRepositoryFailureCode.validation,
          ),
        ),
      );
    });

    test('history rejects non-terminal status filter', () async {
      final repository = ApiIncidentRepository(_FakeIncidentClient());

      await expectLater(
        repository.history(status: IncidentStatus.open),
        throwsA(
          isA<IncidentRepositoryException>().having(
            (error) => error.code,
            'code',
            IncidentRepositoryFailureCode.validation,
          ),
        ),
      );
    });

    test('unknown Incident wire status fails closed', () async {
      final client = _FakeIncidentClient();
      client.getResponses['/incidents/91'] = _success(
        _incidentPayload(status: 'Handling'),
      );
      final repository = ApiIncidentRepository(client);

      await expectLater(
        repository.findById(91),
        throwsA(
          isA<IncidentRepositoryException>().having(
            (error) => error.code,
            'code',
            IncidentRepositoryFailureCode.unknown,
          ),
        ),
      );
    });

    test('stable incident conflict maps to frontend failure', () async {
      final client = _FakeIncidentClient();
      client.postErrors['/incidents/91/acknowledge'] = const SecurityApiException(
        statusCode: 409,
        code: 'INCIDENT_ALREADY_ACKNOWLEDGED',
        message: 'Already acknowledged.',
      );
      final repository = ApiIncidentRepository(client);

      await expectLater(
        repository.acknowledge(91),
        throwsA(
          isA<IncidentRepositoryException>().having(
            (error) => error.code,
            'code',
            IncidentRepositoryFailureCode.alreadyAcknowledged,
          ),
        ),
      );
    });

    test('unauthenticated maps to session-expiry failure', () async {
      final client = _FakeIncidentClient();
      client.getErrors['/incidents/dashboard'] = const SecurityApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Unauthenticated.',
      );
      final repository = ApiIncidentRepository(client);

      await expectLater(
        repository.dashboard(),
        throwsA(
          isA<IncidentRepositoryException>().having(
            (error) => error.code,
            'code',
            IncidentRepositoryFailureCode.unauthorized,
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

Map<String, dynamic> _listEnvelope(
  List<Map<String, dynamic>> data,
  bool hasMore,
) {
  return <String, dynamic>{
    'status': 'success',
    'message': 'OK',
    'data': data,
    'meta': <String, dynamic>{'has_more': hasMore},
  };
}

Map<String, dynamic> _incidentPayload({
  int id = 91,
  String status = 'Open',
  String severity = 'High',
  bool includeTimeline = false,
  bool canAcknowledge = true,
}) {
  return <String, dynamic>{
    'incident_id': id,
    'incident_number': 'INC-20260812-${id.toString().padLeft(6, '0')}',
    'property': <String, dynamic>{
      'id': 3,
      'code': 'APT-A',
      'name': 'Aparthub Residence',
    },
    'patrol_context': null,
    'reported_by': <String, dynamic>{'id': 22, 'name': 'Security Officer'},
    'assigned_to': null,
    'category': 'Safety',
    'severity': severity,
    'status': status,
    'title': 'Emergency exit obstructed',
    'description': 'Boxes block the emergency exit.',
    'location': 'East Emergency Exit',
    'reported_at': '2026-08-12T22:15:00+07:00',
    'acknowledged_at': status == 'Acknowledged' ? '2026-08-12T22:16:00+07:00' : null,
    'resolved_at': status == 'Resolved' ? '2026-08-12T22:30:00+07:00' : null,
    'closed_at': null,
    'escalated_at': null,
    'escalation_level': 0,
    'resolution_notes': status == 'Resolved' ? 'Area secured.' : null,
    'can_acknowledge': canAcknowledge,
    'can_start': status == 'Open' || status == 'Acknowledged',
    'can_resolve': status == 'Acknowledged' || status == 'In Progress',
    'can_add_note': status != 'Closed' && status != 'Cancelled',
    if (includeTimeline)
      'timeline': <Map<String, dynamic>>[
        <String, dynamic>{
          'event_id': 201,
          'event': 'status_changed',
          'from_status': 'Open',
          'to_status': 'Acknowledged',
          'notes': 'Acknowledged by front desk.',
          'metadata': <String, dynamic>{'source': 'security_mobile'},
          'actor': <String, dynamic>{'id': 22, 'name': 'Security Officer'},
          'created_at': '2026-08-12T22:16:00+07:00',
        },
      ],
  };
}

class _FakeIncidentClient implements SecurityApiClient {
  @override
  String? bearerToken = 'token';

  final getResponses = <String, Map<String, dynamic>>{};
  final postResponses = <String, Map<String, dynamic>>{};
  final getErrors = <String, SecurityApiException>{};
  final postErrors = <String, SecurityApiException>{};
  final pagedResponses = <String, List<Map<String, dynamic>>>{};
  final pagesRequested = <String>[];
  String? lastGetPath;
  Map<String, String?>? lastGetQuery;
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) async {
    lastGetPath = path;
    lastGetQuery = query;
    final error = getErrors[path];
    if (error != null) throw error;
    final pages = pagedResponses[path];
    if (pages != null) {
      pagesRequested.add(query['page'] ?? '');
      return pages.removeAt(0);
    }
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
