import '../../domain/models/patrol_models.dart';

abstract final class PatrolApiDecoder {
  static PatrolDashboard decodeDashboard(Map<String, dynamic> data) {
    return PatrolDashboard(
      scheduled: _requiredInt(data, 'scheduled'),
      inProgress: _requiredInt(data, 'in_progress'),
      completedToday: _requiredInt(data, 'completed_today'),
      cancelledToday: _requiredInt(data, 'cancelled_today'),
      nextPatrol: data['next_patrol'] == null
          ? null
          : decodeSession(_requiredObject(data['next_patrol'], 'next_patrol')),
    );
  }

  static PatrolSession decodeSession(Map<String, dynamic> data) {
    final checkpointsRaw = data['checkpoints'];
    final checkpoints = checkpointsRaw == null
        ? const <PatrolCheckpointVisit>[]
        : _requiredList(checkpointsRaw, 'checkpoints')
            .map(
              (item) => decodeCheckpoint(
                _requiredObject(item, 'checkpoints[]'),
              ),
            )
            .toList(growable: false);

    return PatrolSession(
      patrolSessionId: _requiredInt(data, 'patrol_session_id'),
      sessionNumber: _requiredString(data, 'session_number'),
      status: decodeSessionStatus(_requiredString(data, 'status')),
      property: decodeProperty(_requiredObject(data['property'], 'property')),
      route: decodeRoute(_requiredObject(data['route'], 'route')),
      officer: decodeParty(_requiredObject(data['officer'], 'officer')),
      scheduledStartAt: _requiredDateTime(data, 'scheduled_start_at'),
      startedAt: _dateTime(data['started_at']),
      completedAt: _dateTime(data['completed_at']),
      cancelledAt: _dateTime(data['cancelled_at']),
      notes: _nullableString(data['notes']),
      checkpointSummary: decodeSummary(
        _requiredObject(data['checkpoint_summary'], 'checkpoint_summary'),
      ),
      canStart: _requiredBool(data, 'can_start'),
      canComplete: _requiredBool(data, 'can_complete'),
      checkpoints: checkpoints,
    );
  }

  static PatrolCheckpointVisit decodeCheckpoint(Map<String, dynamic> data) {
    return PatrolCheckpointVisit(
      visitId: _requiredInt(data, 'visit_id'),
      checkpointId: _requiredInt(data, 'checkpoint_id'),
      code: _requiredString(data, 'code'),
      name: _requiredString(data, 'name'),
      locationLabel: _nullableString(data['location_label']),
      sequence: _requiredInt(data, 'sequence'),
      status: decodeCheckpointStatus(_requiredString(data, 'status')),
      checkedAt: _dateTime(data['checked_at']),
      checkedBy: data['checked_by'] == null
          ? null
          : decodeParty(_requiredObject(data['checked_by'], 'checked_by')),
      notes: _nullableString(data['notes']),
      photoEvidence: data['photo_evidence'] == null
          ? null
          : decodePhotoEvidence(
              _requiredObject(data['photo_evidence'], 'photo_evidence'),
            ),
      canComplete: _requiredBool(data, 'can_complete'),
      canSkip: _requiredBool(data, 'can_skip'),
    );
  }

  static PatrolCheckpointPhotoEvidence decodePhotoEvidence(
    Map<String, dynamic> data,
  ) {
    return PatrolCheckpointPhotoEvidence(
      url: _requiredString(data, 'url'),
      originalName: _requiredString(data, 'original_name'),
      mimeType: _requiredString(data, 'mime_type'),
      fileSize: _requiredInt(data, 'file_size'),
      uploadedAt: _requiredDateTime(data, 'uploaded_at'),
    );
  }

  static PatrolPropertyRef decodeProperty(Map<String, dynamic> data) {
    return PatrolPropertyRef(
      id: _requiredInt(data, 'id'),
      code: _requiredString(data, 'code'),
      name: _requiredString(data, 'name'),
    );
  }

  static PatrolRouteRef decodeRoute(Map<String, dynamic> data) {
    return PatrolRouteRef(
      id: _requiredInt(data, 'id'),
      code: _requiredString(data, 'code'),
      name: _requiredString(data, 'name'),
      description: _nullableString(data['description']),
      expectedDurationMinutes: _requiredInt(data, 'expected_duration_minutes'),
    );
  }

  static PatrolPartyRef decodeParty(Map<String, dynamic> data) {
    return PatrolPartyRef(
      id: _requiredInt(data, 'id'),
      name: _requiredString(data, 'name'),
    );
  }

  static PatrolCheckpointSummary decodeSummary(Map<String, dynamic> data) {
    return PatrolCheckpointSummary(
      total: _requiredInt(data, 'total'),
      pending: _requiredInt(data, 'pending'),
      completed: _requiredInt(data, 'completed'),
      skipped: _requiredInt(data, 'skipped'),
      issue: _requiredInt(data, 'issue'),
    );
  }

  static PatrolSessionStatus decodeSessionStatus(String value) {
    return switch (value) {
      'Scheduled' => PatrolSessionStatus.scheduled,
      'In Progress' => PatrolSessionStatus.inProgress,
      'Completed' => PatrolSessionStatus.completed,
      'Cancelled' => PatrolSessionStatus.cancelled,
      _ => throw FormatException('Unsupported Patrol status: $value'),
    };
  }

  static PatrolCheckpointStatus decodeCheckpointStatus(String value) {
    return switch (value) {
      'Pending' => PatrolCheckpointStatus.pending,
      'Completed' => PatrolCheckpointStatus.completed,
      'Skipped' => PatrolCheckpointStatus.skipped,
      'Issue' => PatrolCheckpointStatus.issue,
      _ => throw FormatException('Unsupported Patrol checkpoint status: $value'),
    };
  }

  static Map<String, dynamic> _requiredObject(dynamic value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Patrol field $field must be an object.');
    }
    return value;
  }

  static List<dynamic> _requiredList(dynamic value, String field) {
    if (value is! List) {
      throw FormatException('Patrol field $field must be an array.');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = _nullableString(data[key]);
    if (value == null) {
      throw FormatException('Patrol field $key is required.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Patrol field $key must be an integer.');
  }

  static bool _requiredBool(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is bool) return value;
    throw FormatException('Patrol field $key must be a boolean.');
  }

  static DateTime _requiredDateTime(Map<String, dynamic> data, String key) {
    final value = _dateTime(data[key]);
    if (value == null) {
      throw FormatException('Patrol field $key must be ISO-8601.');
    }
    return value;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid Patrol timestamp: $value');
    }
    return parsed;
  }

  static String? _nullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
