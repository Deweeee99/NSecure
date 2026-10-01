enum SecurityPackageStatus {
  readyForPickup,
  collected,
  expired,
}

enum SecurityPackageCollectionRecipientType {
  resident,
  others,
}

class SecurityPackageCollectionRecipient {
  const SecurityPackageCollectionRecipient({
    required this.type,
    required this.name,
    this.residentId,
  });

  final SecurityPackageCollectionRecipientType type;
  final String name;
  final int? residentId;
}

class SecurityPackagePropertyRef {
  const SecurityPackagePropertyRef({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;
}

class SecurityPackageUnitRef {
  const SecurityPackageUnitRef({
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

class SecurityPackageResidentRef {
  const SecurityPackageResidentRef({
    required this.id,
    required this.name,
    this.email,
    this.mobileNo,
  });

  final int id;
  final String name;
  final String? email;
  final String? mobileNo;
}

class SecurityPackageActorRef {
  const SecurityPackageActorRef({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class SecurityPackageResidentLookup {
  const SecurityPackageResidentLookup({
    required this.resident,
    required this.property,
    required this.unit,
  });

  final SecurityPackageResidentRef resident;
  final SecurityPackagePropertyRef property;
  final SecurityPackageUnitRef unit;
}

class SecurityPackageRecord {
  const SecurityPackageRecord({
    required this.packageId,
    required this.packageNo,
    required this.status,
    required this.courierName,
    required this.property,
    required this.resident,
    required this.unit,
    required this.receivedAt,
    this.trackingNumber,
    this.senderName,
    this.packageDescription,
    this.storageLocation,
    this.notes,
    this.collectionNotes,
    this.receivedBy,
    this.collectedBy,
    this.processedBy,
    this.notifiedAt,
    this.collectedAt,
    this.expiresAt,
  });

  final int packageId;
  final String packageNo;
  final SecurityPackageStatus status;
  final String courierName;
  final String? trackingNumber;
  final String? senderName;
  final String? packageDescription;
  final String? storageLocation;
  final String? notes;
  final String? collectionNotes;
  final SecurityPackagePropertyRef property;
  final SecurityPackageResidentRef resident;
  final SecurityPackageUnitRef unit;
  final SecurityPackageActorRef? receivedBy;
  final SecurityPackageCollectionRecipient? collectedBy;
  final SecurityPackageActorRef? processedBy;
  final DateTime receivedAt;
  final DateTime? notifiedAt;
  final DateTime? collectedAt;
  final DateTime? expiresAt;
}

class SecurityPackageReceiveInput {
  const SecurityPackageReceiveInput({
    required this.residentId,
    required this.courierName,
    this.trackingNumber,
    this.senderName,
    this.packageDescription,
    this.storageLocation,
    this.notes,
  });

  final int residentId;
  final String courierName;
  final String? trackingNumber;
  final String? senderName;
  final String? packageDescription;
  final String? storageLocation;
  final String? notes;
}
