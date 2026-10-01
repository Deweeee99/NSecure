enum EmergencyAlertStatus {
  open,
  acknowledged,
  resolved,
}

class EmergencyPropertyRef {
  const EmergencyPropertyRef({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;
}

class EmergencyResidentRef {
  const EmergencyResidentRef({
    required this.id,
    required this.name,
    this.mobileNo,
  });

  final int id;
  final String name;
  final String? mobileNo;
}

class EmergencyUnitRef {
  const EmergencyUnitRef({
    required this.id,
    required this.code,
    this.tower,
    this.floor,
  });

  final int id;
  final String code;
  final String? tower;
  final int? floor;
}

class EmergencyActorRef {
  const EmergencyActorRef({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class EmergencyAlert {
  const EmergencyAlert({
    required this.emergencyAlertId,
    required this.alertCode,
    required this.status,
    required this.modalRequired,
    required this.takenByMe,
    required this.property,
    required this.resident,
    required this.unit,
    required this.triggeredAt,
    this.message,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
  });

  final int emergencyAlertId;
  final String alertCode;
  final EmergencyAlertStatus status;
  final String? message;
  final bool modalRequired;
  final bool takenByMe;
  final EmergencyPropertyRef property;
  final EmergencyResidentRef resident;
  final EmergencyUnitRef unit;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final EmergencyActorRef? acknowledgedBy;
  final DateTime? resolvedAt;
  final EmergencyActorRef? resolvedBy;
  final String? resolutionNotes;
}
