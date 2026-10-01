import '../../../../core/network/security_api_client.dart';
import '../../domain/models/patrol_models.dart';
import '../../domain/repositories/patrol_repository.dart';
import 'patrol_api_decoder.dart';

class ApiPatrolRepository implements PatrolRepository {
  ApiPatrolRepository(this._client);

  final SecurityApiClient _client;

  @override
  Future<PatrolDashboard> dashboard() async {
    try {
      final envelope = await _client.get('/patrol/dashboard');
      return PatrolApiDecoder.decodeDashboard(_requiredObject(envelope['data']));
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw PatrolRepositoryException(
        PatrolRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<List<PatrolSession>> assignedSessions({
    PatrolSessionStatus? status,
    DateTime? date,
  }) {
    return _pagedSessions(
      '/patrol/sessions',
      query: <String, String?>{
        if (status != null) 'status': _sessionWireValue(status),
        if (date != null) 'date': _dateOnly(date),
      },
    );
  }

  @override
  Future<PatrolSession?> findById(int patrolSessionId) async {
    try {
      final envelope = await _client.get('/patrol/sessions/$patrolSessionId');
      return PatrolApiDecoder.decodeSession(_requiredObject(envelope['data']));
    } on SecurityApiException catch (error) {
      if (error.code == 'PATROL_NOT_FOUND') return null;
      throw _mapError(error);
    } on FormatException catch (error) {
      throw PatrolRepositoryException(
        PatrolRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<PatrolSession> startPatrol(int patrolSessionId) async {
    return _mutateAndReload(
      patrolSessionId,
      '/patrol/sessions/$patrolSessionId/start',
    );
  }

  @override
  Future<PatrolSession> completeCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required PatrolPhotoInput photo,
    String? notes,
  }) async {
    _validatePhoto(photo);
    final note = _validatedOptionalNotes(notes);
    return _mutateMultipartAndReload(
      patrolSessionId,
      '/patrol/checkpoint-visits/$checkpointVisitId/complete',
      fields: <String, String>{'notes': ?note},
      photo: photo,
    );
  }

  @override
  Future<PatrolSession> skipCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required String reason,
    PatrolPhotoInput? photo,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty || trimmed.length > 2000) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
        message: 'Skip reason is required and must be at most 2000 characters.',
      );
    }
    if (photo == null) {
      return _mutateAndReload(
        patrolSessionId,
        '/patrol/checkpoint-visits/$checkpointVisitId/skip',
        body: <String, dynamic>{'notes': trimmed},
      );
    }

    _validatePhoto(photo);
    return _mutateMultipartAndReload(
      patrolSessionId,
      '/patrol/checkpoint-visits/$checkpointVisitId/skip',
      fields: <String, String>{'notes': trimmed},
      photo: photo,
    );
  }

  @override
  Future<PatrolSession> completePatrol(
    int patrolSessionId, {
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    final note = _nonEmpty(notes);
    if (note != null) body['notes'] = note;
    return _mutateAndReload(
      patrolSessionId,
      '/patrol/sessions/$patrolSessionId/complete',
      body: body,
    );
  }

  @override
  Future<List<PatrolSession>> history({PatrolSessionStatus? status}) {
    if (status != null &&
        status != PatrolSessionStatus.completed &&
        status != PatrolSessionStatus.cancelled) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
        message: 'Patrol history only accepts Completed or Cancelled status.',
      );
    }
    return _pagedSessions(
      '/patrol/history',
      query: <String, String?>{
        if (status != null) 'status': _sessionWireValue(status),
      },
    );
  }

  Future<PatrolSession> _mutateMultipartAndReload(
    int patrolSessionId,
    String path, {
    required Map<String, String> fields,
    required PatrolPhotoInput photo,
  }) async {
    if (_client is! SecurityMultipartApiClient) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.unknown,
        message: 'Security API client does not support multipart uploads.',
      );
    }
    final multipartClient = _client as SecurityMultipartApiClient;
    try {
      await multipartClient.postMultipart(
        path,
        fields: fields,
        files: <SecurityMultipartFile>[
          SecurityMultipartFile(
            fieldName: 'photo',
            path: photo.path,
            fileName: photo.originalName,
            contentType: photo.mimeType.trim().toLowerCase(),
          ),
        ],
      );
      final refreshed = await findById(patrolSessionId);
      if (refreshed == null) {
        throw const PatrolRepositoryException(
          PatrolRepositoryFailureCode.patrolNotFound,
        );
      }
      return refreshed;
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    }
  }

  Future<PatrolSession> _mutateAndReload(
    int patrolSessionId,
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
  }) async {
    try {
      await _client.post(path, body: body);
      final refreshed = await findById(patrolSessionId);
      if (refreshed == null) {
        throw const PatrolRepositoryException(
          PatrolRepositoryFailureCode.patrolNotFound,
        );
      }
      return refreshed;
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<PatrolSession>> _pagedSessions(
    String path, {
    Map<String, String?> query = const <String, String?>{},
  }) async {
    final sessions = <PatrolSession>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      try {
        final envelope = await _client.get(
          path,
          query: <String, String?>{
            ...query,
            'page': '$page',
            'per_page': '100',
          },
        );
        sessions.addAll(_decodeList(envelope['data']));
        final meta = envelope['meta'];
        hasMore = meta is Map<String, dynamic> && meta['has_more'] == true;
        page += 1;
        if (page > 100) {
          throw const FormatException('Patrol pagination exceeded safety limit.');
        }
      } on SecurityApiException catch (error) {
        throw _mapError(error);
      } on FormatException catch (error) {
        throw PatrolRepositoryException(
          PatrolRepositoryFailureCode.unknown,
          message: error.message,
        );
      }
    }

    return sessions;
  }

  static List<PatrolSession> _decodeList(dynamic data) {
    if (data is! List) {
      throw const FormatException('Patrol list data must be an array.');
    }
    return data
        .map(
          (item) => PatrolApiDecoder.decodeSession(_requiredObject(item)),
        )
        .toList(growable: false);
  }

  static Map<String, dynamic> _requiredObject(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Patrol response data must be an object.');
    }
    return value;
  }

  static String _sessionWireValue(PatrolSessionStatus status) {
    return switch (status) {
      PatrolSessionStatus.scheduled => 'Scheduled',
      PatrolSessionStatus.inProgress => 'In Progress',
      PatrolSessionStatus.completed => 'Completed',
      PatrolSessionStatus.cancelled => 'Cancelled',
    };
  }

  static String _dateOnly(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static void _validatePhoto(PatrolPhotoInput photo) {
    final mime = photo.mimeType.trim().toLowerCase();
    if (!PatrolPhotoInput.allowedMimeTypes.contains(mime)) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
        message: 'Photo must be JPG, JPEG, PNG, or WEBP.',
      );
    }
    if (photo.fileSize <= 0 ||
        photo.fileSize > PatrolPhotoInput.maxFileSizeBytes) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
        message: 'Photo must be no larger than 5 MB.',
      );
    }
  }

  static String? _validatedOptionalNotes(String? value) {
    final note = _nonEmpty(value);
    if (note != null && note.length > 2000) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
        message: 'Notes must be at most 2000 characters.',
      );
    }
    return note;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static PatrolRepositoryException _mapError(SecurityApiException error) {
    final code = switch (error.code) {
      'UNAUTHENTICATED' || 'SECURITY_INVALID_CREDENTIALS' =>
        PatrolRepositoryFailureCode.unauthorized,
      'FORBIDDEN' || 'SECURITY_PROPERTY_UNAVAILABLE' =>
        PatrolRepositoryFailureCode.forbidden,
      'PATROL_NOT_FOUND' => PatrolRepositoryFailureCode.patrolNotFound,
      'PATROL_CHECKPOINT_NOT_FOUND' =>
        PatrolRepositoryFailureCode.checkpointNotFound,
      'PATROL_ALREADY_STARTED' => PatrolRepositoryFailureCode.alreadyStarted,
      'PATROL_ALREADY_COMPLETED' =>
        PatrolRepositoryFailureCode.alreadyCompleted,
      'PATROL_CANCELLED' => PatrolRepositoryFailureCode.cancelled,
      'PATROL_INVALID_STATE' => PatrolRepositoryFailureCode.invalidState,
      'PATROL_NOT_IN_PROGRESS' => PatrolRepositoryFailureCode.notInProgress,
      'PATROL_CHECKPOINT_INVALID_STATE' =>
        PatrolRepositoryFailureCode.checkpointInvalidState,
      'PATROL_CHECKPOINT_ALREADY_PROCESSED' =>
        PatrolRepositoryFailureCode.checkpointAlreadyProcessed,
      'PATROL_CHECKPOINTS_PENDING' =>
        PatrolRepositoryFailureCode.checkpointsPending,
      'VALIDATION_ERROR' => PatrolRepositoryFailureCode.validation,
      'NETWORK_ERROR' || 'NETWORK_TIMEOUT' => PatrolRepositoryFailureCode.network,
      _ => PatrolRepositoryFailureCode.unknown,
    };
    return PatrolRepositoryException(
      code,
      message: _mappedMessage(error),
      pendingCount: _pendingCount(error.data),
    );
  }

  static String _mappedMessage(SecurityApiException error) {
    if (error.code != 'VALIDATION_ERROR' || error.errors.isEmpty) {
      return error.message;
    }

    for (final value in error.errors.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is List) {
        for (final item in value) {
          if (item is String && item.trim().isNotEmpty) {
            return item.trim();
          }
        }
      }
    }
    return error.message;
  }

  static int? _pendingCount(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final value = data['pending_count'];
    return value is num ? value.toInt() : null;
  }
}
