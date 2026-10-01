import '../../domain/models/incident_models.dart';

abstract final class IncidentApiDecoder {
  static IncidentDashboard decodeDashboard(Map<String, dynamic> data) {
    return IncidentDashboard(
      open: _requiredInt(data, 'open'),
      critical: _requiredInt(data, 'critical'),
      escalated: _requiredInt(data, 'escalated'),
      assignedToMe: _requiredInt(data, 'assigned_to_me'),
      reportedByMe: _requiredInt(data, 'reported_by_me'),
      resolvedToday: _requiredInt(data, 'resolved_today'),
    );
  }

  static IncidentRecord decodeIncident(Map<String, dynamic> data) {
    final timelineRaw = data['timeline'];
    final timeline = timelineRaw == null
        ? const <IncidentTimelineEvent>[]
        : _requiredList(timelineRaw, 'timeline')
            .map(
              (item) => decodeTimelineEvent(
                _requiredObject(item, 'timeline[]'),
              ),
            )
            .toList(growable: false);

    return IncidentRecord(
      incidentId: _requiredInt(data, 'incident_id'),
      incidentNumber: _requiredString(data, 'incident_number'),
      property: decodeProperty(_requiredObject(data['property'], 'property')),
      patrolContext: data['patrol_context'] == null
          ? null
          : decodePatrolContext(
              _requiredObject(data['patrol_context'], 'patrol_context'),
            ),
      reportedBy: data['reported_by'] == null
          ? null
          : decodeParty(_requiredObject(data['reported_by'], 'reported_by')),
      assignedTo: data['assigned_to'] == null
          ? null
          : decodeParty(_requiredObject(data['assigned_to'], 'assigned_to')),
      category: _requiredString(data, 'category'),
      severity: decodeSeverity(_requiredString(data, 'severity')),
      status: decodeStatus(_requiredString(data, 'status')),
      title: _requiredString(data, 'title'),
      description: _requiredString(data, 'description'),
      location: _nullableString(data['location']),
      reportedAt: _requiredDateTime(data, 'reported_at'),
      acknowledgedAt: _dateTime(data['acknowledged_at']),
      resolvedAt: _dateTime(data['resolved_at']),
      closedAt: _dateTime(data['closed_at']),
      escalatedAt: _dateTime(data['escalated_at']),
      escalationLevel: _requiredInt(data, 'escalation_level'),
      resolutionNotes: _nullableString(data['resolution_notes']),
      canAcknowledge: _requiredBool(data, 'can_acknowledge'),
      canStart: _requiredBool(data, 'can_start'),
      canResolve: _requiredBool(data, 'can_resolve'),
      canAddNote: _requiredBool(data, 'can_add_note'),
      timeline: timeline,
    );
  }

  static IncidentTimelineEvent decodeTimelineEvent(Map<String, dynamic> data) {
    return IncidentTimelineEvent(
      eventId: _requiredInt(data, 'event_id'),
      event: _requiredString(data, 'event'),
      fromStatus: _optionalStatus(data['from_status']),
      toStatus: _optionalStatus(data['to_status']),
      notes: _nullableString(data['notes']),
      metadata: data['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.unmodifiable(
              data['metadata'] as Map<String, dynamic>,
            )
          : const <String, dynamic>{},
      actor: data['actor'] == null
          ? null
          : decodeParty(_requiredObject(data['actor'], 'actor')),
      createdAt: _requiredDateTime(data, 'created_at'),
    );
  }

  static IncidentPropertyRef decodeProperty(Map<String, dynamic> data) {
    return IncidentPropertyRef(
      id: _requiredInt(data, 'id'),
      code: _requiredString(data, 'code'),
      name: _requiredString(data, 'name'),
    );
  }

  static IncidentPartyRef decodeParty(Map<String, dynamic> data) {
    return IncidentPartyRef(
      id: _requiredInt(data, 'id'),
      name: _requiredString(data, 'name'),
    );
  }

  static IncidentPatrolContext decodePatrolContext(Map<String, dynamic> data) {
    return IncidentPatrolContext(
      checkpointVisitId: _requiredInt(data, 'checkpoint_visit_id'),
      patrolSessionId: _requiredInt(data, 'patrol_session_id'),
      sessionNumber: _requiredString(data, 'session_number'),
      checkpointId: _requiredInt(data, 'checkpoint_id'),
      checkpointName: _requiredString(data, 'checkpoint_name'),
      checkpointLocation: _nullableString(data['checkpoint_location']),
    );
  }

  static IncidentStatus decodeStatus(String value) {
    return switch (value) {
      'Open' => IncidentStatus.open,
      'Acknowledged' => IncidentStatus.acknowledged,
      'In Progress' => IncidentStatus.inProgress,
      'Resolved' => IncidentStatus.resolved,
      'Closed' => IncidentStatus.closed,
      'Cancelled' => IncidentStatus.cancelled,
      _ => throw FormatException('Unsupported Incident status: $value'),
    };
  }

  static IncidentSeverity decodeSeverity(String value) {
    return switch (value) {
      'Low' => IncidentSeverity.low,
      'Medium' => IncidentSeverity.medium,
      'High' => IncidentSeverity.high,
      'Critical' => IncidentSeverity.critical,
      _ => throw FormatException('Unsupported Incident severity: $value'),
    };
  }

  static IncidentStatus? _optionalStatus(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw const FormatException('Incident timeline status must be a string.');
    }
    return decodeStatus(value);
  }

  static Map<String, dynamic> _requiredObject(dynamic value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Incident field $field must be an object.');
    }
    return value;
  }

  static List<dynamic> _requiredList(dynamic value, String field) {
    if (value is! List) {
      throw FormatException('Incident field $field must be an array.');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = _nullableString(data[key]);
    if (value == null) {
      throw FormatException('Incident field $key is required.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Incident field $key must be an integer.');
  }

  static bool _requiredBool(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is bool) return value;
    throw FormatException('Incident field $key must be a boolean.');
  }

  static DateTime _requiredDateTime(Map<String, dynamic> data, String key) {
    final value = _dateTime(data[key]);
    if (value == null) {
      throw FormatException('Incident field $key must be ISO-8601.');
    }
    return value;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw const FormatException('Incident timestamp must be a string.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid Incident timestamp: $value');
    }
    return parsed;
  }

  static String? _nullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
