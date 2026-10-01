import '../../domain/models/security_package_models.dart';
import '../../domain/repositories/security_package_repository.dart';

class MockSecurityPackageRepository implements SecurityPackageRepository {
  MockSecurityPackageRepository({
    this.actorName = 'Security Team',
    List<SecurityPackageResidentLookup>? residents,
    List<SecurityPackageRecord>? initialPackages,
  })  : _residents = residents ?? _defaultResidents,
        _packages = <SecurityPackageRecord>[
          ...(initialPackages ?? _defaultPackages),
        ];

  final String actorName;
  final List<SecurityPackageResidentLookup> _residents;
  final List<SecurityPackageRecord> _packages;

  static const _property = SecurityPackagePropertyRef(
    id: 1,
    code: 'SITE-A',
    name: 'Aparthub Residence',
  );

  static const _residentBudi = SecurityPackageResidentRef(
    id: 101,
    name: 'Budi Santoso',
    email: 'budi@example.com',
    mobileNo: '081234567890',
  );

  static const _residentSarah = SecurityPackageResidentRef(
    id: 102,
    name: 'Sarah Williams',
    email: 'sarah@example.com',
    mobileNo: '081298765432',
  );

  static const _unitA101 = SecurityPackageUnitRef(
    id: 44,
    code: 'A-101',
    tower: 'Tower A',
    floor: 1,
  );

  static const _unitB1203 = SecurityPackageUnitRef(
    id: 45,
    code: 'B-1203',
    tower: 'Tower B',
    floor: 12,
  );

  static const _defaultResidents = <SecurityPackageResidentLookup>[
    SecurityPackageResidentLookup(
      resident: _residentBudi,
      property: _property,
      unit: _unitA101,
    ),
    SecurityPackageResidentLookup(
      resident: _residentSarah,
      property: _property,
      unit: _unitB1203,
    ),
  ];

  static final _defaultPackages = <SecurityPackageRecord>[
    SecurityPackageRecord(
      packageId: 55,
      packageNo: 'PKG-260814-AB12CD34',
      status: SecurityPackageStatus.readyForPickup,
      courierName: 'JNE',
      trackingNumber: 'JNE-123456',
      senderName: 'Marketplace Seller',
      packageDescription: 'Medium box',
      storageLocation: 'Lobby Rack A',
      notes: 'Handle with care',
      property: _property,
      resident: _residentBudi,
      unit: _unitA101,
      receivedBy: const SecurityPackageActorRef(
        id: 9,
        name: 'Security Team',
      ),
      receivedAt: DateTime(2026, 8, 14, 13, 30),
    ),
    SecurityPackageRecord(
      packageId: 54,
      packageNo: 'PKG-260814-44556677',
      status: SecurityPackageStatus.collected,
      courierName: 'SiCepat',
      trackingNumber: 'SC-445566',
      storageLocation: 'Lobby Rack B',
      collectionNotes: 'Collected by resident at lobby.',
      property: _property,
      resident: _residentSarah,
      unit: _unitB1203,
      receivedBy: const SecurityPackageActorRef(
        id: 9,
        name: 'Security Team',
      ),
      collectedBy: const SecurityPackageCollectionRecipient(
        type: SecurityPackageCollectionRecipientType.resident,
        name: 'Sarah Williams',
        residentId: 102,
      ),
      processedBy: const SecurityPackageActorRef(
        id: 9,
        name: 'Security Team',
      ),
      receivedAt: DateTime(2026, 8, 14, 11, 0),
      collectedAt: DateTime(2026, 8, 14, 12, 5),
    ),
  ];

  @override
  Future<List<SecurityPackageResidentLookup>> searchResidents({
    String? query,
    int? propertyId,
    int limit = 30,
  }) async {
    if (limit < 1 || limit > 50) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
      );
    }
    final needle = query?.trim().toLowerCase() ?? '';
    final results = _residents.where((item) {
      if (propertyId != null && item.property.id != propertyId) return false;
      if (needle.isEmpty) return true;
      final values = <String?>[
        item.resident.name,
        item.resident.email,
        item.resident.mobileNo,
        item.unit.code,
        item.unit.tower,
      ];
      return values.any(
        (value) => value?.toLowerCase().contains(needle) == true,
      );
    }).take(limit).toList(growable: false);
    return List<SecurityPackageResidentLookup>.unmodifiable(results);
  }

  @override
  Future<List<SecurityPackageRecord>> packages({
    SecurityPackageStatus? status,
    String? search,
    int? propertyId,
  }) async {
    final needle = search?.trim().toLowerCase() ?? '';
    final results = _packages.where((record) {
      if (status != null && record.status != status) return false;
      if (propertyId != null && record.property.id != propertyId) return false;
      if (needle.isEmpty) return true;
      return <String?>[
        record.packageNo,
        record.courierName,
        record.trackingNumber,
        record.resident.name,
        record.unit.code,
      ].any((value) => value?.toLowerCase().contains(needle) == true);
    }).toList(growable: false)
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return List<SecurityPackageRecord>.unmodifiable(results);
  }

  @override
  Future<SecurityPackageRecord?> findById(int packageId) async {
    for (final record in _packages) {
      if (record.packageId == packageId) return record;
    }
    return null;
  }

  @override
  Future<SecurityPackageRecord> receivePackage(
    SecurityPackageReceiveInput input,
  ) async {
    final courier = input.courierName.trim();
    if (input.residentId <= 0 || courier.isEmpty) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
      );
    }
    SecurityPackageResidentLookup? lookup;
    for (final item in _residents) {
      if (item.resident.id == input.residentId) {
        lookup = item;
        break;
      }
    }
    if (lookup == null) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.residentNotFound,
      );
    }

    final id = (_packages.isEmpty
            ? 55
            : _packages.map((item) => item.packageId).reduce(
                  (a, b) => a > b ? a : b,
                )) +
        1;
    final record = SecurityPackageRecord(
      packageId: id,
      packageNo: 'PKG-260814-MOCK$id',
      status: SecurityPackageStatus.readyForPickup,
      courierName: courier,
      trackingNumber: _clean(input.trackingNumber),
      senderName: _clean(input.senderName),
      packageDescription: _clean(input.packageDescription),
      storageLocation: _clean(input.storageLocation),
      notes: _clean(input.notes),
      property: lookup.property,
      resident: lookup.resident,
      unit: lookup.unit,
      receivedBy: SecurityPackageActorRef(id: 9, name: actorName),
      receivedAt: DateTime(2026, 8, 14, 14, 10),
    );
    _packages.add(record);
    return record;
  }

  @override
  Future<SecurityPackageRecord> collectPackage(
    int packageId, {
    required SecurityPackageCollectionRecipientType recipientType,
    String? collectionRecipientName,
    String? collectionNotes,
  }) async {
    final index = _packages.indexWhere((item) => item.packageId == packageId);
    if (index < 0) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.packageNotFound,
      );
    }
    final current = _packages[index];
    if (current.status == SecurityPackageStatus.collected &&
        current.collectedBy != null) {
      return current;
    }
    if (current.status == SecurityPackageStatus.expired) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
        message: 'Expired packages cannot be collected in mock mode.',
      );
    }

    final otherName = _clean(collectionRecipientName);
    if (recipientType == SecurityPackageCollectionRecipientType.others &&
        otherName == null) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
        message: 'Collection recipient name is required for Others.',
      );
    }

    final recipient = switch (recipientType) {
      SecurityPackageCollectionRecipientType.resident =>
        SecurityPackageCollectionRecipient(
          type: SecurityPackageCollectionRecipientType.resident,
          name: current.resident.name,
          residentId: current.resident.id,
        ),
      SecurityPackageCollectionRecipientType.others =>
        SecurityPackageCollectionRecipient(
          type: SecurityPackageCollectionRecipientType.others,
          name: otherName!,
        ),
    };

    final updated = SecurityPackageRecord(
      packageId: current.packageId,
      packageNo: current.packageNo,
      status: SecurityPackageStatus.collected,
      courierName: current.courierName,
      trackingNumber: current.trackingNumber,
      senderName: current.senderName,
      packageDescription: current.packageDescription,
      storageLocation: current.storageLocation,
      notes: current.notes,
      collectionNotes: _clean(collectionNotes),
      property: current.property,
      resident: current.resident,
      unit: current.unit,
      receivedBy: current.receivedBy,
      collectedBy: recipient,
      processedBy:
          current.processedBy ?? SecurityPackageActorRef(id: 9, name: actorName),
      receivedAt: current.receivedAt,
      notifiedAt: current.notifiedAt,
      collectedAt:
          current.collectedAt ?? DateTime(2026, 8, 14, 14, 25),
      expiresAt: current.expiresAt,
    );
    _packages[index] = updated;
    return updated;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
