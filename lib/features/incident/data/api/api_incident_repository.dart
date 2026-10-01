import '../../../../core/network/security_api_client.dart';
import '../../domain/models/incident_models.dart';
import '../../domain/repositories/incident_repository.dart';
import 'incident_api_decoder.dart';

class ApiIncidentRepository implements IncidentRepository {
  ApiIncidentRepository(this._client);

  final SecurityApiClient _client;

  @override
  Future<IncidentDashboard> dashboard() async {
    try {
      final envelope = await _client.get('/incidents/dashboard');
      return IncidentApiDecoder.decodeDashboard(_requiredObject(envelope['data']));
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw IncidentRepositoryException(
        IncidentRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<List<IncidentRecord>> incidents({
    IncidentScope scope = IncidentScope.mine,
    IncidentStatus? status,
    IncidentSeverity? severity,
    String? query,
  }) {
    final search = _nonEmpty(query);
    return _pagedIncidents(
      '/incidents',
      query: <String, String?>{
        'scope': _scopeWireValue(scope),
        if (status != null) 'status': _statusWireValue(status),
        if (severity != null) 'severity': _severityWireValue(severity),
        'q': ?search,
      },
    );
  }

  @override
  Future<List<IncidentRecord>> history({
    IncidentScope scope = IncidentScope.mine,
    IncidentStatus? status,
    IncidentSeverity? severity,
    String? query,
  }) {
    if (status != null &&
        status != IncidentStatus.resolved &&
        status != IncidentStatus.closed &&
        status != IncidentStatus.cancelled) {
      return Future<List<IncidentRecord>>.error(
        const IncidentRepositoryException(
          IncidentRepositoryFailureCode.validation,
          message: 'Incident history status must be Resolved, Closed, or Cancelled.',
        ),
      );
    }
    final search = _nonEmpty(query);
    return _pagedIncidents(
      '/incidents/history',
      query: <String, String?>{
        'scope': _scopeWireValue(scope),
        if (status != null) 'status': _statusWireValue(status),
        if (severity != null) 'severity': _severityWireValue(severity),
        'q': ?search,
      },
    );
  }

  @override
  Future<IncidentRecord?> findById(int incidentId) async {
    try {
      final envelope = await _client.get('/incidents/$incidentId');
      return IncidentApiDecoder.decodeIncident(_requiredObject(envelope['data']));
    } on SecurityApiException catch (error) {
      if (error.code == 'INCIDENT_NOT_FOUND') return null;
      throw _mapError(error);
    } on FormatException catch (error) {
      throw IncidentRepositoryException(
        IncidentRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<void> createIncident(IncidentCreateInput input) async {
    final title = input.title.trim();
    final description = input.description.trim();
    final category = input.category.trim();
    final location = _nonEmpty(input.location);
    if (title.isEmpty || description.isEmpty || category.isEmpty) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.validation,
        message: 'Title, description, and category are required.',
      );
    }

    final body = <String, dynamic>{
      if (input.propertyId != null) 'property_id': input.propertyId,
      if (input.patrolCheckpointVisitId != null)
        'patrol_checkpoint_visit_id': input.patrolCheckpointVisitId,
      'title': title,
      'description': description,
      'category': category,
      'severity': _severityWireValue(input.severity),
      'location': ?location,
    };

    try {
      await _client.post('/incidents', body: body);
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<IncidentRecord> acknowledge(
    int incidentId, {
    String? notes,
  }) {
    return _mutateAndReload(
      incidentId,
      '/incidents/$incidentId/acknowledge',
      notes: notes,
    );
  }

  @override
  Future<IncidentRecord> start(
    int incidentId, {
    String? notes,
  }) {
    return _mutateAndReload(
      incidentId,
      '/incidents/$incidentId/start',
      notes: notes,
    );
  }

  @override
  Future<IncidentRecord> resolve(
    int incidentId, {
    required String notes,
  }) async {
    final value = notes.trim();
    if (value.isEmpty) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.validation,
        message: 'Resolution notes are required.',
      );
    }
    return _mutateAndReload(
      incidentId,
      '/incidents/$incidentId/resolve',
      notes: value,
    );
  }

  @override
  Future<IncidentRecord> addNote(
    int incidentId, {
    required String notes,
  }) async {
    final value = notes.trim();
    if (value.isEmpty) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.validation,
        message: 'Incident note is required.',
      );
    }
    return _mutateAndReload(
      incidentId,
      '/incidents/$incidentId/notes',
      notes: value,
    );
  }

  Future<IncidentRecord> _mutateAndReload(
    int incidentId,
    String path, {
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    final value = _nonEmpty(notes);
    if (value != null) body['notes'] = value;

    try {
      await _client.post(path, body: body);
      final incident = await findById(incidentId);
      if (incident == null) {
        throw const IncidentRepositoryException(
          IncidentRepositoryFailureCode.incidentNotFound,
        );
      }
      return incident;
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<IncidentRecord>> _pagedIncidents(
    String path, {
    required Map<String, String?> query,
  }) async {
    final incidents = <IncidentRecord>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      try {
        final envelope = await _client.get(
          path,
          query: <String, String?>{
            ...query,
            'per_page': '100',
            'page': '$page',
          },
        );
        incidents.addAll(_decodeList(envelope['data']));
        final meta = envelope['meta'];
        hasMore = meta is Map<String, dynamic> && meta['has_more'] == true;
        page += 1;
        if (page > 100) {
          throw const FormatException('Incident pagination exceeded safety limit.');
        }
      } on SecurityApiException catch (error) {
        throw _mapError(error);
      } on FormatException catch (error) {
        throw IncidentRepositoryException(
          IncidentRepositoryFailureCode.unknown,
          message: error.message,
        );
      }
    }

    return incidents;
  }

  static List<IncidentRecord> _decodeList(dynamic data) {
    if (data is! List) {
      throw const FormatException('Incident list data must be an array.');
    }
    return data
        .map(
          (item) => IncidentApiDecoder.decodeIncident(_requiredObject(item)),
        )
        .toList(growable: false);
  }

  static Map<String, dynamic> _requiredObject(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Incident response data must be an object.');
    }
    return value;
  }

  static String _scopeWireValue(IncidentScope scope) => switch (scope) {
        IncidentScope.mine => 'mine',
        IncidentScope.assigned => 'assigned',
        IncidentScope.reported => 'reported',
        IncidentScope.all => 'all',
      };

  static String _statusWireValue(IncidentStatus status) => switch (status) {
        IncidentStatus.open => 'Open',
        IncidentStatus.acknowledged => 'Acknowledged',
        IncidentStatus.inProgress => 'In Progress',
        IncidentStatus.resolved => 'Resolved',
        IncidentStatus.closed => 'Closed',
        IncidentStatus.cancelled => 'Cancelled',
      };

  static String _severityWireValue(IncidentSeverity severity) => switch (severity) {
        IncidentSeverity.low => 'Low',
        IncidentSeverity.medium => 'Medium',
        IncidentSeverity.high => 'High',
        IncidentSeverity.critical => 'Critical',
      };

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static IncidentRepositoryException _mapError(SecurityApiException error) {
    final code = switch (error.code) {
      'UNAUTHENTICATED' || 'SECURITY_INVALID_CREDENTIALS' =>
        IncidentRepositoryFailureCode.unauthorized,
      'FORBIDDEN' || 'SECURITY_PROPERTY_UNAVAILABLE' =>
        IncidentRepositoryFailureCode.forbidden,
      'INCIDENT_NOT_FOUND' => IncidentRepositoryFailureCode.incidentNotFound,
      'PATROL_CHECKPOINT_NOT_FOUND' =>
        IncidentRepositoryFailureCode.patrolCheckpointNotFound,
      'PATROL_NOT_IN_PROGRESS' =>
        IncidentRepositoryFailureCode.patrolNotInProgress,
      'PATROL_CHECKPOINT_ALREADY_PROCESSED' =>
        IncidentRepositoryFailureCode.patrolCheckpointAlreadyProcessed,
      'INCIDENT_ALREADY_ACKNOWLEDGED' =>
        IncidentRepositoryFailureCode.alreadyAcknowledged,
      'INCIDENT_ALREADY_IN_PROGRESS' =>
        IncidentRepositoryFailureCode.alreadyInProgress,
      'INCIDENT_ALREADY_RESOLVED' =>
        IncidentRepositoryFailureCode.alreadyResolved,
      'INCIDENT_CLOSED' => IncidentRepositoryFailureCode.closed,
      'INCIDENT_CANCELLED' => IncidentRepositoryFailureCode.cancelled,
      'INCIDENT_INVALID_STATE' => IncidentRepositoryFailureCode.invalidState,
      'VALIDATION_ERROR' => IncidentRepositoryFailureCode.validation,
      'NETWORK_ERROR' || 'NETWORK_TIMEOUT' => IncidentRepositoryFailureCode.network,
      _ => IncidentRepositoryFailureCode.unknown,
    };
    return IncidentRepositoryException(
      code,
      message: error.message,
      fieldErrors: error.errors,
    );
  }
}
