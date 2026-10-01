import 'package:nsecure/core/network/security_api_client.dart';
import 'package:nsecure/features/patrol/data/api/api_patrol_repository.dart';
import 'package:nsecure/features/patrol/domain/models/patrol_models.dart';
import 'package:nsecure/features/patrol/domain/repositories/patrol_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiPatrolRepository', () {
    test('dashboard decodes canonical patrol summary and next patrol', () async {
      final client = _FakePatrolClient();
      client.getResponses['/patrol/dashboard'] = _success(<String, dynamic>{
        'scheduled': 2,
        'in_progress': 1,
        'completed_today': 3,
        'cancelled_today': 0,
        'next_patrol': _sessionPayload(includeCheckpoints: false),
      });
      final repository = ApiPatrolRepository(client);

      final dashboard = await repository.dashboard();

      expect(dashboard.scheduled, 2);
      expect(dashboard.inProgress, 1);
      expect(dashboard.nextPatrol?.patrolSessionId, 41);
      expect(dashboard.nextPatrol?.status, PatrolSessionStatus.inProgress);
    });

    test('detail decodes checkpoint capabilities and exact wire statuses', () async {
      final client = _FakePatrolClient();
      client.getResponses['/patrol/sessions/41'] = _success(
        _sessionPayload(includeCheckpoints: true),
      );
      final repository = ApiPatrolRepository(client);

      final session = await repository.findById(41);

      expect(session, isNotNull);
      expect(session!.checkpoints, hasLength(2));
      expect(session.checkpoints.first.status, PatrolCheckpointStatus.completed);
      expect(session.checkpoints.first.photoEvidence?.originalName, 'checkpoint.jpg');
      expect(session.checkpoints.first.photoEvidence?.mimeType, 'image/jpeg');
      expect(session.checkpoints.first.photoEvidence?.fileSize, 123456);
      expect(session.checkpoints.last.status, PatrolCheckpointStatus.pending);
      expect(session.checkpoints.last.photoEvidence, isNull);
      expect(session.checkpoints.last.canComplete, isTrue);
      expect(session.route.expectedDurationMinutes, 45);
    });

    test('assigned list follows has_more pagination', () async {
      final client = _FakePatrolClient();
      client.pagedResponses['/patrol/sessions'] = <Map<String, dynamic>>[
        _listEnvelope(<Map<String, dynamic>>[_sessionPayload(includeCheckpoints: false)], true),
        _listEnvelope(<Map<String, dynamic>>[
          _sessionPayload(id: 42, status: 'Scheduled', includeCheckpoints: false),
        ], false),
      ];
      final repository = ApiPatrolRepository(client);

      final sessions = await repository.assignedSessions();

      expect(sessions, hasLength(2));
      expect(client.pagesRequested, <String>['1', '2']);
      expect(client.lastGetQuery?['per_page'], '100');
    });

    test('checkpoint complete uploads required photo with visit_id route then reloads', () async {
      final client = _FakePatrolClient();
      client.multipartResponses['/patrol/checkpoint-visits/102/complete'] =
          _success(null);
      client.getResponses['/patrol/sessions/41'] = _success(
        _sessionPayload(includeCheckpoints: true, pending: 0, completed: 2),
      );
      final repository = ApiPatrolRepository(client);

      final session = await repository.completeCheckpoint(
        41,
        102,
        photo: _validPhoto,
        notes: '  Area clear  ',
      );

      expect(client.lastMultipartPath, '/patrol/checkpoint-visits/102/complete');
      expect(client.lastMultipartFields, <String, String>{'notes': 'Area clear'});
      expect(client.lastMultipartFiles, hasLength(1));
      expect(client.lastMultipartFiles.single.fieldName, 'photo');
      expect(client.lastMultipartFiles.single.fileName, 'checkpoint.jpg');
      expect(client.lastMultipartFiles.single.contentType, 'image/jpeg');
      expect(client.lastMultipartPath, isNot(contains('/checkpoints/9/')));
      expect(session.checkpointSummary.pending, 0);
    });

    test('start patrol uses Security-relative route and reloads canonical detail', () async {
      final client = _FakePatrolClient();
      client.postResponses['/patrol/sessions/41/start'] = _success(null);
      client.getResponses['/patrol/sessions/41'] = _success(
        _sessionPayload(includeCheckpoints: true),
      );
      final repository = ApiPatrolRepository(client);

      final session = await repository.startPatrol(41);

      expect(client.lastPostPath, '/patrol/sessions/41/start');
      expect(client.lastPostBody, isEmpty);
      expect(session.patrolSessionId, 41);
      expect(client.lastPostPath, isNot(contains('/api/security/api/security')));
    });

    test('skip sends only the canonical notes reason', () async {
      final client = _FakePatrolClient();
      client.postResponses['/patrol/checkpoint-visits/102/skip'] = _success(null);
      client.getResponses['/patrol/sessions/41'] = _success(
        _sessionPayload(includeCheckpoints: true),
      );
      final repository = ApiPatrolRepository(client);

      await repository.skipCheckpoint(41, 102, reason: '  Area inaccessible  ');

      expect(client.lastPostPath, '/patrol/checkpoint-visits/102/skip');
      expect(client.lastPostBody, <String, dynamic>{'notes': 'Area inaccessible'});
      expect(client.lastPostBody, isNot(containsPair('property_id', anything)));
      expect(client.lastPostBody, isNot(containsPair('scan_token', anything)));
    });

    test('skip with optional photo switches to multipart and keeps notes required', () async {
      final client = _FakePatrolClient();
      client.multipartResponses['/patrol/checkpoint-visits/102/skip'] = _success(null);
      client.getResponses['/patrol/sessions/41'] = _success(
        _sessionPayload(includeCheckpoints: true),
      );
      final repository = ApiPatrolRepository(client);

      await repository.skipCheckpoint(
        41,
        102,
        reason: '  Area temporarily inaccessible.  ',
        photo: _validPhoto,
      );

      expect(client.lastMultipartPath, '/patrol/checkpoint-visits/102/skip');
      expect(
        client.lastMultipartFields,
        <String, String>{'notes': 'Area temporarily inaccessible.'},
      );
      expect(client.lastMultipartFiles.single.fieldName, 'photo');
    });

    test('complete rejects unsupported or oversized photo before upload', () async {
      final repository = ApiPatrolRepository(_FakePatrolClient());

      await expectLater(
        repository.completeCheckpoint(
          41,
          102,
          photo: const PatrolPhotoInput(
            path: '/tmp/checkpoint.gif',
            originalName: 'checkpoint.gif',
            mimeType: 'image/gif',
            fileSize: 1024,
          ),
        ),
        throwsA(
          isA<PatrolRepositoryException>().having(
            (error) => error.code,
            'code',
            PatrolRepositoryFailureCode.validation,
          ),
        ),
      );
    });


    test('checkpoint validation surfaces backend field error detail', () async {
      final client = _FakePatrolClient();
      client.multipartErrors['/patrol/checkpoint-visits/102/complete'] =
          const SecurityApiException(
        statusCode: 422,
        code: 'VALIDATION_ERROR',
        message: 'The given data was invalid.',
        errors: <String, dynamic>{
          'photo': <String>['The photo field is required.'],
        },
      );
      final repository = ApiPatrolRepository(client);

      await expectLater(
        repository.completeCheckpoint(
          41,
          102,
          photo: _validPhoto,
        ),
        throwsA(
          isA<PatrolRepositoryException>()
              .having(
                (error) => error.code,
                'code',
                PatrolRepositoryFailureCode.validation,
              )
              .having(
                (error) => error.message,
                'message',
                'The photo field is required.',
              ),
        ),
      );
    });

    test('processed checkpoint conflict is surfaced without automatic retry', () async {
      final client = _FakePatrolClient();
      client.multipartErrors['/patrol/checkpoint-visits/102/complete'] =
          const SecurityApiException(
        statusCode: 409,
        code: 'PATROL_CHECKPOINT_ALREADY_PROCESSED',
        message: 'Checkpoint already processed.',
      );
      final repository = ApiPatrolRepository(client);

      await expectLater(
        repository.completeCheckpoint(
          41,
          102,
          photo: _validPhoto,
        ),
        throwsA(
          isA<PatrolRepositoryException>().having(
            (error) => error.code,
            'code',
            PatrolRepositoryFailureCode.checkpointAlreadyProcessed,
          ),
        ),
      );

      expect(client.lastMultipartPath, '/patrol/checkpoint-visits/102/complete');
      expect(client.getCallCount, 0);
    });

    test('skip requires reason before network call', () async {
      final repository = ApiPatrolRepository(_FakePatrolClient());

      await expectLater(
        repository.skipCheckpoint(41, 102, reason: '   '),
        throwsA(
          isA<PatrolRepositoryException>().having(
            (error) => error.code,
            'code',
            PatrolRepositoryFailureCode.validation,
          ),
        ),
      );
    });

    test('stable patrol conflict exposes pending_count', () async {
      final client = _FakePatrolClient();
      client.postErrors['/patrol/sessions/41/complete'] = const SecurityApiException(
        statusCode: 409,
        code: 'PATROL_CHECKPOINTS_PENDING',
        message: 'Pending checkpoints remain.',
        data: <String, dynamic>{'pending_count': 2},
      );
      final repository = ApiPatrolRepository(client);

      await expectLater(
        repository.completePatrol(41),
        throwsA(
          isA<PatrolRepositoryException>()
              .having(
                (error) => error.code,
                'code',
                PatrolRepositoryFailureCode.checkpointsPending,
              )
              .having((error) => error.pendingCount, 'pendingCount', 2),
        ),
      );
    });

    test('unknown Patrol wire status fails closed', () async {
      final client = _FakePatrolClient();
      client.getResponses['/patrol/sessions/41'] = _success(
        _sessionPayload(status: 'Running', includeCheckpoints: true),
      );
      final repository = ApiPatrolRepository(client);

      await expectLater(
        repository.findById(41),
        throwsA(
          isA<PatrolRepositoryException>().having(
            (error) => error.code,
            'code',
            PatrolRepositoryFailureCode.unknown,
          ),
        ),
      );
    });

    test('unauthenticated maps to session-expiry failure', () async {
      final client = _FakePatrolClient();
      client.getErrors['/patrol/dashboard'] = const SecurityApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Unauthenticated.',
      );
      final repository = ApiPatrolRepository(client);

      await expectLater(
        repository.dashboard(),
        throwsA(
          isA<PatrolRepositoryException>().having(
            (error) => error.code,
            'code',
            PatrolRepositoryFailureCode.unauthorized,
          ),
        ),
      );
    });
  });
}

const PatrolPhotoInput _validPhoto = PatrolPhotoInput(
  path: '/tmp/checkpoint.jpg',
  originalName: 'checkpoint.jpg',
  mimeType: 'image/jpeg',
  fileSize: 123456,
);

Map<String, dynamic> _success(dynamic data) => <String, dynamic>{
      'status': 'success',
      'message': 'OK',
      'data': data,
    };

Map<String, dynamic> _listEnvelope(List<Map<String, dynamic>> data, bool hasMore) {
  return <String, dynamic>{
    'status': 'success',
    'message': 'OK',
    'data': data,
    'meta': <String, dynamic>{'has_more': hasMore},
  };
}

Map<String, dynamic> _sessionPayload({
  int id = 41,
  String status = 'In Progress',
  bool includeCheckpoints = true,
  int pending = 1,
  int completed = 1,
}) {
  return <String, dynamic>{
    'patrol_session_id': id,
    'session_number': 'PAT-20260812-${id.toString().padLeft(6, '0')}',
    'status': status,
    'property': <String, dynamic>{
      'id': 1,
      'code': 'SITE-A',
      'name': 'Aparthub Residence',
    },
    'route': <String, dynamic>{
      'id': 4,
      'code': 'NIGHT-A',
      'name': 'Tower A — Night Patrol',
      'description': 'Night perimeter patrol.',
      'expected_duration_minutes': 45,
    },
    'officer': <String, dynamic>{'id': 12, 'name': 'Security Officer A'},
    'scheduled_start_at': '2026-08-12T22:00:00+07:00',
    'started_at': status == 'Scheduled' ? null : '2026-08-12T22:02:14+07:00',
    'completed_at': status == 'Completed' ? '2026-08-12T22:45:00+07:00' : null,
    'cancelled_at': null,
    'notes': 'Night shift.',
    'checkpoint_summary': <String, dynamic>{
      'total': pending + completed,
      'pending': pending,
      'completed': completed,
      'skipped': 0,
      'issue': 0,
    },
    'can_start': status == 'Scheduled',
    'can_complete': status == 'In Progress' && pending == 0,
    if (includeCheckpoints)
      'checkpoints': <Map<String, dynamic>>[
        <String, dynamic>{
          'visit_id': 101,
          'checkpoint_id': 8,
          'code': 'CP-01',
          'name': 'Main Lobby',
          'location_label': 'Ground Floor',
          'sequence': 1,
          'status': 'Completed',
          'checked_at': '2026-08-12T22:07:00+07:00',
          'checked_by': <String, dynamic>{'id': 12, 'name': 'Security Officer A'},
          'notes': 'Area clear.',
          'photo_evidence': <String, dynamic>{
            'url': 'https://example.invalid/api/files/security-patrol-checkpoint-visits/101/photo?expires=1&signature=test',
            'original_name': 'checkpoint.jpg',
            'mime_type': 'image/jpeg',
            'file_size': 123456,
            'uploaded_at': '2026-08-12T22:07:00+07:00',
          },
          'can_complete': false,
          'can_skip': false,
        },
        if (pending > 0)
          <String, dynamic>{
            'visit_id': 102,
            'checkpoint_id': 9,
            'code': 'CP-02',
            'name': 'Lift Lobby',
            'location_label': 'Tower A',
            'sequence': 2,
            'status': 'Pending',
            'checked_at': null,
            'checked_by': null,
            'notes': null,
            'photo_evidence': null,
            'can_complete': true,
            'can_skip': true,
          },
      ],
  };
}

class _FakePatrolClient implements SecurityApiClient, SecurityMultipartApiClient {
  @override
  String? bearerToken = 'token';

  final getResponses = <String, Map<String, dynamic>>{};
  final postResponses = <String, Map<String, dynamic>>{};
  final getErrors = <String, SecurityApiException>{};
  final postErrors = <String, SecurityApiException>{};
  final multipartResponses = <String, Map<String, dynamic>>{};
  final multipartErrors = <String, SecurityApiException>{};
  final pagedResponses = <String, List<Map<String, dynamic>>>{};
  final pagesRequested = <String>[];
  Map<String, String?>? lastGetQuery;
  int getCallCount = 0;
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;
  String? lastMultipartPath;
  Map<String, String>? lastMultipartFields;
  List<SecurityMultipartFile> lastMultipartFiles = const <SecurityMultipartFile>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) async {
    getCallCount += 1;
    lastGetQuery = query;
    final error = getErrors[path];
    if (error != null) throw error;
    final pages = pagedResponses[path];
    if (pages != null) {
      pagesRequested.add(query['page'] ?? '');
      return pages.removeAt(0);
    }
    final response = getResponses[path];
    if (response == null) {
      throw StateError('No fake GET response for $path');
    }
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
    if (response == null) {
      throw StateError('No fake POST response for $path');
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const <String, String>{},
    List<SecurityMultipartFile> files = const <SecurityMultipartFile>[],
    bool authenticated = true,
  }) async {
    lastMultipartPath = path;
    lastMultipartFields = Map<String, String>.from(fields);
    lastMultipartFiles = List<SecurityMultipartFile>.from(files);
    final error = multipartErrors[path];
    if (error != null) throw error;
    final response = multipartResponses[path];
    if (response == null) {
      throw StateError('No fake multipart response for $path');
    }
    return response;
  }
}
