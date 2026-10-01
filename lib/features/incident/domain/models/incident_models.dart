enum IncidentStatus {
  open,
  acknowledged,
  inProgress,
  resolved,
  closed,
  cancelled,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

enum IncidentScope {
  mine,
  assigned,
  reported,
  all,
}

class IncidentPropertyRef {
  const IncidentPropertyRef({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;
}

class IncidentPartyRef {
  const IncidentPartyRef({required this.id, required this.name});

  final int id;
  final String name;
}

class IncidentPatrolContext {
  const IncidentPatrolContext({
    required this.checkpointVisitId,
    required this.patrolSessionId,
    required this.sessionNumber,
    required this.checkpointId,
    required this.checkpointName,
    this.checkpointLocation,
  });

  final int checkpointVisitId;
  final int patrolSessionId;
  final String sessionNumber;
  final int checkpointId;
  final String checkpointName;
  final String? checkpointLocation;
}

class IncidentTimelineEvent {
  const IncidentTimelineEvent({
    required this.eventId,
    required this.event,
    required this.createdAt,
    required this.metadata,
    this.fromStatus,
    this.toStatus,
    this.notes,
    this.actor,
  });

  final int eventId;
  final String event;
  final IncidentStatus? fromStatus;
  final IncidentStatus? toStatus;
  final String? notes;
  final Map<String, dynamic> metadata;
  final IncidentPartyRef? actor;
  final DateTime createdAt;
}

class IncidentRecord {
  const IncidentRecord({
    required this.incidentId,
    required this.incidentNumber,
    required this.property,
    required this.category,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    required this.reportedAt,
    required this.escalationLevel,
    required this.canAcknowledge,
    required this.canStart,
    required this.canResolve,
    required this.canAddNote,
    this.patrolContext,
    this.reportedBy,
    this.assignedTo,
    this.location,
    this.acknowledgedAt,
    this.resolvedAt,
    this.closedAt,
    this.escalatedAt,
    this.resolutionNotes,
    this.timeline = const <IncidentTimelineEvent>[],
  });

  final int incidentId;
  final String incidentNumber;
  final IncidentPropertyRef property;
  final IncidentPatrolContext? patrolContext;
  final IncidentPartyRef? reportedBy;
  final IncidentPartyRef? assignedTo;
  final String category;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String title;
  final String description;
  final String? location;
  final DateTime reportedAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? escalatedAt;
  final int escalationLevel;
  final String? resolutionNotes;
  final bool canAcknowledge;
  final bool canStart;
  final bool canResolve;
  final bool canAddNote;
  final List<IncidentTimelineEvent> timeline;
}

class IncidentDashboard {
  const IncidentDashboard({
    required this.open,
    required this.critical,
    required this.escalated,
    required this.assignedToMe,
    required this.reportedByMe,
    required this.resolvedToday,
  });

  final int open;
  final int critical;
  final int escalated;
  final int assignedToMe;
  final int reportedByMe;
  final int resolvedToday;
}

class IncidentCreateContext {
  const IncidentCreateContext({
    required this.propertyId,
    required this.patrolCheckpointVisitId,
    required this.sessionNumber,
    required this.checkpointName,
    this.location,
  });

  final int propertyId;
  final int patrolCheckpointVisitId;
  final String sessionNumber;
  final String checkpointName;
  final String? location;
}

class IncidentCreateInput {
  const IncidentCreateInput({
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.location,
    this.propertyId,
    this.patrolCheckpointVisitId,
  });

  final int? propertyId;
  final int? patrolCheckpointVisitId;
  final String title;
  final String description;
  final String category;
  final IncidentSeverity severity;
  final String? location;
}
