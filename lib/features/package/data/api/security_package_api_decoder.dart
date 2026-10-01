import '../../domain/models/security_package_models.dart';

abstract final class SecurityPackageApiDecoder {
  static SecurityPackageRecord decodePackage(Map<String, dynamic> data) {
    final residentData = _requiredObject(data['resident'], 'resident');
    final propertyData = _requiredObjectFromContractCopies(
      primary: data['property'],
      nested: residentData['property'],
      field: 'property',
    );
    final unitData = _requiredObjectFromContractCopies(
      primary: data['unit'],
      nested: residentData['unit'],
      field: 'unit',
    );

    final collectedByData = data['collected_by'] is Map<String, dynamic>
        ? data['collected_by'] as Map<String, dynamic>
        : null;
    final processedByData = data['processed_by'] is Map<String, dynamic>
        ? data['processed_by'] as Map<String, dynamic>
        : null;

    final collectedBy = collectedByData == null
        ? null
        : _decodeCollectionRecipientIfCurrent(collectedByData);
    final processedBy = processedByData != null
        ? _decodeActor(processedByData)
        : _decodeLegacyProcessedBy(collectedByData);

    return SecurityPackageRecord(
      packageId: _requiredIntAny(data, const <String>['package_id', 'id']),
      packageNo: _requiredString(data, 'package_no'),
      status: decodeStatus(_requiredString(data, 'status')),
      courierName: _requiredString(data, 'courier_name'),
      trackingNumber: _nullableString(data['tracking_number']),
      senderName: _nullableString(data['sender_name']),
      packageDescription: _nullableString(data['package_description']),
      storageLocation: _nullableString(data['storage_location']),
      notes: _nullableString(data['notes']),
      collectionNotes: _nullableString(data['collection_notes']),
      property: _decodeProperty(propertyData),
      resident: _decodeResident(residentData),
      unit: _decodeUnit(unitData),
      receivedBy: data['received_by'] == null
          ? null
          : _decodeActor(_requiredObject(data['received_by'], 'received_by')),
      collectedBy: collectedBy,
      processedBy: processedBy,
      receivedAt: _requiredDateTime(data, 'received_at'),
      notifiedAt: _dateTime(data['notified_at']),
      collectedAt: _dateTime(data['collected_at']),
      expiresAt: _dateTime(data['expires_at']),
    );
  }

  static SecurityPackageResidentLookup decodeResidentLookup(
    Map<String, dynamic> data,
  ) {
    final residentData = data['resident'] is Map<String, dynamic>
        ? data['resident'] as Map<String, dynamic>
        : data;
    final propertyValue = _requiredObjectFromContractCopies(
      primary: data['property'],
      nested: residentData['property'],
      field: 'property',
    );
    final unitValue = _requiredObjectFromContractCopies(
      primary: data['unit'],
      nested: residentData['unit'],
      field: 'unit',
    );

    return SecurityPackageResidentLookup(
      resident: SecurityPackageResidentRef(
        id: _requiredIntAny(
          residentData,
          const <String>['id', 'resident_id'],
        ),
        name: _requiredString(residentData, 'name'),
        email: _nullableString(residentData['email']),
        mobileNo: _nullableString(residentData['mobile_no']),
      ),
      property: _decodeProperty(propertyValue),
      unit: _decodeUnit(unitValue),
    );
  }

  static SecurityPackageStatus decodeStatus(String value) => switch (value) {
        'Ready for Pickup' => SecurityPackageStatus.readyForPickup,
        'Collected' => SecurityPackageStatus.collected,
        'Expired' => SecurityPackageStatus.expired,
        _ => throw FormatException('Unsupported Package status: $value'),
      };

  static SecurityPackagePropertyRef _decodeProperty(
    Map<String, dynamic> data,
  ) {
    return SecurityPackagePropertyRef(
      id: _requiredInt(data, 'id'),
      code: _requiredString(data, 'code'),
      name: _requiredString(data, 'name'),
    );
  }

  static SecurityPackageResidentRef _decodeResident(
    Map<String, dynamic> data,
  ) {
    return SecurityPackageResidentRef(
      id: _requiredIntAny(data, const <String>['id', 'resident_id']),
      name: _requiredString(data, 'name'),
      email: _nullableString(data['email']),
      mobileNo: _nullableString(data['mobile_no']),
    );
  }

  static SecurityPackageUnitRef _decodeUnit(Map<String, dynamic> data) {
    return SecurityPackageUnitRef(
      id: _requiredInt(data, 'id'),
      code: _requiredString(data, 'code'),
      tower: _nullableString(data['tower']),
      floor: _nullableInt(data['floor']),
    );
  }

  static SecurityPackageActorRef _decodeActor(Map<String, dynamic> data) {
    return SecurityPackageActorRef(
      id: _requiredInt(data, 'id'),
      name: _requiredString(data, 'name'),
    );
  }

  static SecurityPackageCollectionRecipient?
      _decodeCollectionRecipientIfCurrent(Map<String, dynamic> data) {
    // New recipient-aware payloads always carry canonical `type`.
    // Historical rows may still expose the old Security actor shape
    // `{id, name}` in `collected_by`. That actor is not the physical pickup
    // recipient, so do not present it as one.
    if (_nullableString(data['type']) == null) return null;
    return _decodeCollectionRecipient(data);
  }

  static SecurityPackageActorRef? _decodeLegacyProcessedBy(
    Map<String, dynamic>? collectedByData,
  ) {
    if (collectedByData == null) return null;
    if (_nullableString(collectedByData['type']) != null) return null;

    final id = _nullableInt(collectedByData['id']);
    final name = _nullableString(collectedByData['name']);
    if (id == null || name == null) return null;

    // Compatibility only: before recipient refinement, `collected_by` was the
    // Security operator. Preserve that audit actor as Processed By while the
    // physical recipient remains unknown.
    return SecurityPackageActorRef(id: id, name: name);
  }

  static SecurityPackageCollectionRecipient _decodeCollectionRecipient(
    Map<String, dynamic> data,
  ) {
    final typeValue = _requiredString(data, 'type');
    final type = switch (typeValue) {
      'resident' => SecurityPackageCollectionRecipientType.resident,
      'others' => SecurityPackageCollectionRecipientType.others,
      _ => throw FormatException(
          'Unsupported Package collection recipient type: $typeValue',
        ),
    };

    final residentId = _nullableInt(data['resident_id']);
    if (type == SecurityPackageCollectionRecipientType.resident &&
        residentId == null) {
      throw const FormatException(
        'Package collected_by.resident_id is required for resident pickup.',
      );
    }

    return SecurityPackageCollectionRecipient(
      type: type,
      name: _requiredString(data, 'name'),
      residentId: residentId,
    );
  }

  static Map<String, dynamic> _requiredObjectFromContractCopies({
    required dynamic primary,
    required dynamic nested,
    required String field,
  }) {
    if (primary is Map<String, dynamic>) return primary;
    if (nested is Map<String, dynamic>) return nested;
    throw FormatException('Package field $field must be an object.');
  }

  static Map<String, dynamic> _requiredObject(dynamic value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Package field $field must be an object.');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = _nullableString(data[key]);
    if (value == null) {
      throw FormatException('Package field $key is required.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> data, String key) {
    final value = _nullableInt(data[key]);
    if (value == null) {
      throw FormatException('Package field $key must be an integer.');
    }
    return value;
  }

  static int _requiredIntAny(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _nullableInt(data[key]);
      if (value != null) return value;
    }
    throw FormatException(
      'Package field ${keys.join(' / ')} must be an integer.',
    );
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> data, String key) {
    final value = _dateTime(data[key]);
    if (value == null) {
      throw FormatException('Package field $key must be ISO-8601.');
    }
    return value;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Package timestamp must be a string.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid Package timestamp: $value');
    }
    return parsed;
  }

  static String? _nullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
