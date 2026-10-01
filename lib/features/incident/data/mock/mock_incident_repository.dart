import '../../domain/models/incident_models.dart';
import '../../domain/repositories/incident_repository.dart';

class MockIncidentRepository implements IncidentRepository {
  MockIncidentRepository({
    this.actorName = 'Security Team',
    this.onPatrolIncidentCreated,
  }) : _incidents = <int, IncidentRecord>{
          for (final incident in _seed(actorName)) incident.incidentId: incident,
        };

  final String actorName;
  final Future<void> Function(int checkpointVisitId)? onPatrolIncidentCreated;
  final Map<int, IncidentRecord> _incidents;
  int _nextId = 94;

  @override
  Future<IncidentDashboard> dashboard() async {
    final values = _incidents.values;
    return IncidentDashboard(
      open: values
          .where(
            (incident) =>
                incident.status == IncidentStatus.open ||
                incident.status == IncidentStatus.acknowledged ||
                incident.status == IncidentStatus.inProgress,
          )
          .length,
      critical: values
          .where(
            (incident) =>
                incident.severity == IncidentSeverity.critical &&
                incident.status != IncidentStatus.resolved &&
                incident.status != IncidentStatus.closed &&
                incident.status != IncidentStatus.cancelled,
          )
          .length,
      escalated: values.where((incident) => incident.escalationLevel > 0).length,
      assignedToMe: values.where((incident) => incident.assignedTo != null).length,
      reportedByMe: values.where((incident) => incident.reportedBy != null).length,
      resolvedToday: values.where((incident) => incident.status == IncidentStatus.resolved).length,
    );
  }

  @override
  Future<List<IncidentRecord>> incidents({
    IncidentScope scope = IncidentScope.mine,
    IncidentStatus? status,
    IncidentSeverity? severity,
    String? query,
  }) async {
    return _filter(
      _incidents.values.where(
        (incident) =>
            incident.status != IncidentStatus.resolved &&
            incident.status != IncidentStatus.closed &&
            incident.status != IncidentStatus.cancelled,
      ),
      status: status,
      severity: severity,
      query: query,
    );
  }

  @override
  Future<List<IncidentRecord>> history({
    IncidentScope scope = IncidentScope.mine,
    IncidentStatus? status,
    IncidentSeverity? severity,
    String? query,
  }) async {
    if (status != null &&
        status != IncidentStatus.resolved &&
        status != IncidentStatus.closed &&
        status != IncidentStatus.cancelled) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.validation,
      );
    }
    return _filter(
      _incidents.values.where(
        (incident) =>
            incident.status == IncidentStatus.resolved ||
            incident.status == IncidentStatus.closed ||
            incident.status == IncidentStatus.cancelled,
      ),
      status: status,
      severity: severity,
      query: query,
    );
  }

  @override
  Future<IncidentRecord?> findById(int incidentId) async => _incidents[incidentId];

  @override
  Future<void> createIncident(IncidentCreateInput input) async {
    final title = input.title.trim();
    final description = input.description.trim();
    final category = input.category.trim();
    if (title.isEmpty || description.isEmpty || category.isEmpty) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.validation,
      );
    }

    final patrolCheckpointVisitId = input.patrolCheckpointVisitId;
    final onPatrolIncidentCreated = this.onPatrolIncidentCreated;
    if (patrolCheckpointVisitId != null && onPatrolIncidentCreated != null) {
      await onPatrolIncidentCreated(patrolCheckpointVisitId);
    }

    final id = _nextId++;
    final now = DateTime.parse('2026-08-12T22:38:00+07:00');
    final reporter = IncidentPartyRef(id: 12, name: actorName);
    final property = const IncidentPropertyRef(
      id: 1,
      code: 'SITE-A',
      name: 'Aparthub Residence',
    );
    _incidents[id] = IncidentRecord(
      incidentId: id,
      incidentNumber: 'INC-20260812-${id.toString().padLeft(6, '0')}',
      property: property,
      reportedBy: reporter,
      category: category,
      severity: input.severity,
      status: IncidentStatus.open,
      title: title,
      description: description,
      location: _nonEmpty(input.location),
      reportedAt: now,
      escalationLevel: input.severity == IncidentSeverity.critical ? 1 : 0,
      escalatedAt: input.severity == IncidentSeverity.critical ? now : null,
      canAcknowledge: true,
      canStart: true,
      canResolve: false,
      canAddNote: true,
      timeline: <IncidentTimelineEvent>[
        IncidentTimelineEvent(
          eventId: 900 + id,
          event: 'reported',
          toStatus: IncidentStatus.open,
          metadata: const <String, dynamic>{'source': 'security_mobile'},
          actor: reporter,
          createdAt: now,
        ),
      ],
    );
  }

  @override
  Future<IncidentRecord> acknowledge(
    int incidentId, {
    String? notes,
  }) async {
    final incident = _requireIncident(incidentId);
    if (incident.status == IncidentStatus.acknowledged) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.alreadyAcknowledged,
      );
    }
    if (!incident.canAcknowledge || incident.status != IncidentStatus.open) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.invalidState,
      );
    }
    return _transition(
      incident,
      IncidentStatus.acknowledged,
      event: 'status_changed',
      notes: _nonEmpty(notes),
    );
  }

  @override
  Future<IncidentRecord> start(
    int incidentId, {
    String? notes,
  }) async {
    final incident = _requireIncident(incidentId);
    if (incident.status == IncidentStatus.inProgress) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.alreadyInProgress,
      );
    }
    if (!incident.canStart ||
        (incident.status != IncidentStatus.open &&
            incident.status != IncidentStatus.acknowledged)) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.invalidState,
      );
    }
    return _transition(
      incident,
      IncidentStatus.inProgress,
      event: 'status_changed',
      notes: _nonEmpty(notes),
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
      );
    }
    final incident = _requireIncident(incidentId);
    if (incident.status == IncidentStatus.resolved) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.alreadyResolved,
      );
    }
    if (!incident.canResolve ||
        (incident.status != IncidentStatus.acknowledged &&
            incident.status != IncidentStatus.inProgress)) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.invalidState,
      );
    }
    return _transition(
      incident,
      IncidentStatus.resolved,
      event: 'status_changed',
      notes: value,
      resolutionNotes: value,
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
      );
    }
    final incident = _requireIncident(incidentId);
    if (!incident.canAddNote) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.invalidState,
      );
    }
    final updated = _copyWith(
      incident,
      timeline: <IncidentTimelineEvent>[
        IncidentTimelineEvent(
          eventId: 2000 + incident.timeline.length,
          event: 'note_added',
          notes: value,
          metadata: const <String, dynamic>{'source': 'security_mobile'},
          actor: IncidentPartyRef(id: 12, name: actorName),
          createdAt: DateTime.parse('2026-08-12T22:40:00+07:00'),
        ),
        ...incident.timeline,
      ],
    );
    _incidents[incidentId] = updated;
    return updated;
  }

  List<IncidentRecord> _filter(
    Iterable<IncidentRecord> source, {
    IncidentStatus? status,
    IncidentSeverity? severity,
    String? query,
  }) {
    final q = _nonEmpty(query)?.toLowerCase();
    final values = source.where((incident) {
      if (status != null && incident.status != status) return false;
      if (severity != null && incident.severity != severity) return false;
      if (q != null) {
        final haystack = <String>[
          incident.incidentNumber,
          incident.title,
          incident.description,
          incident.location ?? '',
          incident.category,
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return values;
  }

  IncidentRecord _transition(
    IncidentRecord incident,
    IncidentStatus target, {
    required String event,
    String? notes,
    String? resolutionNotes,
  }) {
    final now = switch (target) {
      IncidentStatus.acknowledged => DateTime.parse('2026-08-12T22:16:00+07:00'),
      IncidentStatus.inProgress => DateTime.parse('2026-08-12T22:18:00+07:00'),
      IncidentStatus.resolved => DateTime.parse('2026-08-12T22:32:00+07:00'),
      _ => DateTime.parse('2026-08-12T22:20:00+07:00'),
    };
    final updated = _copyWith(
      incident,
      status: target,
      acknowledgedAt: target == IncidentStatus.acknowledged
          ? now
          : incident.acknowledgedAt,
      resolvedAt: target == IncidentStatus.resolved ? now : incident.resolvedAt,
      resolutionNotes: resolutionNotes ?? incident.resolutionNotes,
      canAcknowledge: false,
      canStart: target == IncidentStatus.acknowledged,
      canResolve: target == IncidentStatus.acknowledged || target == IncidentStatus.inProgress,
      canAddNote: target != IncidentStatus.resolved,
      timeline: <IncidentTimelineEvent>[
        IncidentTimelineEvent(
          eventId: 1000 + incident.timeline.length,
          event: event,
          fromStatus: incident.status,
          toStatus: target,
          notes: notes,
          metadata: const <String, dynamic>{'source': 'security_mobile'},
          actor: IncidentPartyRef(id: 12, name: actorName),
          createdAt: now,
        ),
        ...incident.timeline,
      ],
    );
    _incidents[incident.incidentId] = updated;
    return updated;
  }

  IncidentRecord _requireIncident(int incidentId) {
    final incident = _incidents[incidentId];
    if (incident == null) {
      throw const IncidentRepositoryException(
        IncidentRepositoryFailureCode.incidentNotFound,
      );
    }
    return incident;
  }

  static IncidentRecord _copyWith(
    IncidentRecord incident, {
    IncidentStatus? status,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    bool? canAcknowledge,
    bool? canStart,
    bool? canResolve,
    bool? canAddNote,
    List<IncidentTimelineEvent>? timeline,
  }) {
    return IncidentRecord(
      incidentId: incident.incidentId,
      incidentNumber: incident.incidentNumber,
      property: incident.property,
      patrolContext: incident.patrolContext,
      reportedBy: incident.reportedBy,
      assignedTo: incident.assignedTo,
      category: incident.category,
      severity: incident.severity,
      status: status ?? incident.status,
      title: incident.title,
      description: incident.description,
      location: incident.location,
      reportedAt: incident.reportedAt,
      acknowledgedAt: acknowledgedAt ?? incident.acknowledgedAt,
      resolvedAt: resolvedAt ?? incident.resolvedAt,
      closedAt: incident.closedAt,
      escalatedAt: incident.escalatedAt,
      escalationLevel: incident.escalationLevel,
      resolutionNotes: resolutionNotes ?? incident.resolutionNotes,
      canAcknowledge: canAcknowledge ?? incident.canAcknowledge,
      canStart: canStart ?? incident.canStart,
      canResolve: canResolve ?? incident.canResolve,
      canAddNote: canAddNote ?? incident.canAddNote,
      timeline: timeline ?? incident.timeline,
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static List<IncidentRecord> _seed(String actorName) {
    final officer = IncidentPartyRef(id: 12, name: actorName);
    const property = IncidentPropertyRef(
      id: 1,
      code: 'SITE-A',
      name: 'Aparthub Residence',
    );
    final openAt = DateTime.parse('2026-08-12T22:15:00+07:00');
    final activeAt = DateTime.parse('2026-08-12T21:42:00+07:00');
    final resolvedAt = DateTime.parse('2026-08-12T18:20:00+07:00');
    return <IncidentRecord>[
      IncidentRecord(
        incidentId: 91,
        incidentNumber: 'INC-20260812-000091',
        property: property,
        reportedBy: officer,
        category: 'Safety',
        severity: IncidentSeverity.high,
        status: IncidentStatus.open,
        title: 'Emergency exit obstructed',
        description: 'Boxes block the emergency exit.',
        location: 'East Emergency Exit',
        reportedAt: openAt,
        escalationLevel: 0,
        canAcknowledge: true,
        canStart: true,
        canResolve: false,
        canAddNote: true,
        timeline: <IncidentTimelineEvent>[
          IncidentTimelineEvent(
            eventId: 201,
            event: 'reported',
            toStatus: IncidentStatus.open,
            metadata: const <String, dynamic>{'source': 'security_mobile'},
            actor: officer,
            createdAt: openAt,
          ),
        ],
      ),
      IncidentRecord(
        incidentId: 92,
        incidentNumber: 'INC-20260812-000092',
        property: property,
        reportedBy: officer,
        assignedTo: officer,
        category: 'Security',
        severity: IncidentSeverity.critical,
        status: IncidentStatus.inProgress,
        title: 'Suspicious activity at parking gate',
        description: 'Unknown individual repeatedly checking parked vehicles.',
        location: 'Parking Gate B1',
        reportedAt: activeAt,
        acknowledgedAt: activeAt.add(const Duration(minutes: 2)),
        escalatedAt: activeAt.add(const Duration(minutes: 1)),
        escalationLevel: 1,
        canAcknowledge: false,
        canStart: false,
        canResolve: true,
        canAddNote: true,
        timeline: <IncidentTimelineEvent>[
          IncidentTimelineEvent(
            eventId: 211,
            event: 'status_changed',
            fromStatus: IncidentStatus.acknowledged,
            toStatus: IncidentStatus.inProgress,
            notes: 'Checking CCTV and parking area.',
            metadata: const <String, dynamic>{'source': 'security_mobile'},
            actor: officer,
            createdAt: activeAt.add(const Duration(minutes: 4)),
          ),
        ],
      ),
      IncidentRecord(
        incidentId: 93,
        incidentNumber: 'INC-20260812-000093',
        property: property,
        reportedBy: officer,
        category: 'Safety',
        severity: IncidentSeverity.medium,
        status: IncidentStatus.resolved,
        title: 'Water leak in service corridor',
        description: 'Small leak found near service access.',
        location: 'Service Corridor',
        reportedAt: resolvedAt.subtract(const Duration(minutes: 25)),
        acknowledgedAt: resolvedAt.subtract(const Duration(minutes: 20)),
        resolvedAt: resolvedAt,
        escalationLevel: 0,
        resolutionNotes: 'Valve isolated and engineering notified.',
        canAcknowledge: false,
        canStart: false,
        canResolve: false,
        canAddNote: false,
        timeline: <IncidentTimelineEvent>[
          IncidentTimelineEvent(
            eventId: 221,
            event: 'status_changed',
            fromStatus: IncidentStatus.inProgress,
            toStatus: IncidentStatus.resolved,
            notes: 'Valve isolated and engineering notified.',
            metadata: const <String, dynamic>{'source': 'security_mobile'},
            actor: officer,
            createdAt: resolvedAt,
          ),
        ],
      ),
    ];
  }
}
