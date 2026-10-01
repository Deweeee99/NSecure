import '../../../../core/network/security_api_client.dart';
import '../../domain/models/security_package_models.dart';
import '../../domain/repositories/security_package_repository.dart';
import 'security_package_api_decoder.dart';

class ApiSecurityPackageRepository implements SecurityPackageRepository {
  ApiSecurityPackageRepository(this._client);

  final SecurityApiClient _client;

  @override
  Future<List<SecurityPackageResidentLookup>> searchResidents({
    String? query,
    int? propertyId,
    int limit = 30,
  }) async {
    if (limit < 1 || limit > 50) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
        message: 'Resident search limit must be between 1 and 50.',
      );
    }
    final normalizedQuery = _nonEmpty(query);
    final requestQuery = <String, String?>{'limit': '$limit'};
    if (normalizedQuery != null) requestQuery['q'] = normalizedQuery;
    if (propertyId != null) requestQuery['property_id'] = '$propertyId';
    try {
      final envelope = await _client.get(
        '/packages/residents/search',
        query: requestQuery,
      );
      final data = envelope['data'];
      if (data is! List) {
        throw const FormatException('Package resident search data must be an array.');
      }
      return data
          .map(
            (item) => SecurityPackageApiDecoder.decodeResidentLookup(
              _requiredObject(item),
            ),
          )
          .toList(growable: false);
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<List<SecurityPackageRecord>> packages({
    SecurityPackageStatus? status,
    String? search,
    int? propertyId,
  }) async {
    final normalizedSearch = _nonEmpty(search);
    final records = <SecurityPackageRecord>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      try {
        final requestQuery = <String, String?>{
          'per_page': '100',
          'page': '$page',
        };
        if (status != null) requestQuery['status'] = _statusWireValue(status);
        if (normalizedSearch != null) requestQuery['search'] = normalizedSearch;
        if (propertyId != null) requestQuery['property_id'] = '$propertyId';
        final envelope = await _client.get(
          '/packages',
          query: requestQuery,
        );
        final data = envelope['data'];
        if (data is! List) {
          throw const FormatException('Package list data must be an array.');
        }
        records.addAll(
          data.map(
            (item) => SecurityPackageApiDecoder.decodePackage(
              _requiredObject(item),
            ),
          ),
        );
        final meta = envelope['meta'];
        hasMore = meta is Map<String, dynamic> && meta['has_more'] == true;
        page += 1;
        if (page > 100) {
          throw const FormatException('Package pagination exceeded safety limit.');
        }
      } on SecurityApiException catch (error) {
        throw _mapError(error);
      } on FormatException catch (error) {
        throw SecurityPackageRepositoryException(
          SecurityPackageRepositoryFailureCode.unknown,
          message: error.message,
        );
      }
    }

    return records;
  }

  @override
  Future<SecurityPackageRecord?> findById(int packageId) async {
    try {
      final envelope = await _client.get('/packages/$packageId');
      return SecurityPackageApiDecoder.decodePackage(
        _requiredObject(envelope['data']),
      );
    } on SecurityApiException catch (error) {
      if (error.code == 'PACKAGE_NOT_FOUND') return null;
      throw _mapError(error);
    } on FormatException catch (error) {
      throw SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<SecurityPackageRecord> receivePackage(
    SecurityPackageReceiveInput input,
  ) async {
    final courierName = input.courierName.trim();
    if (input.residentId <= 0 || courierName.isEmpty) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
        message: 'Resident and courier are required.',
      );
    }

    final body = <String, dynamic>{
      'resident_id': input.residentId,
      'courier_name': courierName,
    };
    _putIfPresent(body, 'tracking_number', input.trackingNumber);
    _putIfPresent(body, 'sender_name', input.senderName);
    _putIfPresent(body, 'package_description', input.packageDescription);
    _putIfPresent(body, 'storage_location', input.storageLocation);
    _putIfPresent(body, 'notes', input.notes);

    try {
      final envelope = await _client.post('/packages', body: body);
      return SecurityPackageApiDecoder.decodePackage(
        _requiredObject(envelope['data']),
      );
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<SecurityPackageRecord> collectPackage(
    int packageId, {
    required SecurityPackageCollectionRecipientType recipientType,
    String? collectionRecipientName,
    String? collectionNotes,
  }) async {
    if (packageId <= 0) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
        message: 'Package ID is invalid.',
      );
    }

    final recipientName = _nonEmpty(collectionRecipientName);
    if (recipientType == SecurityPackageCollectionRecipientType.others &&
        recipientName == null) {
      throw const SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.validation,
        message: 'Collection recipient name is required for Others.',
        fieldErrors: <String, dynamic>{
          'collection_recipient_name': <String>[
            'Collection recipient name is required for Others.',
          ],
        },
      );
    }

    final body = <String, dynamic>{
      'collection_recipient_type': _recipientTypeWireValue(recipientType),
    };
    if (recipientType == SecurityPackageCollectionRecipientType.others) {
      body['collection_recipient_name'] = recipientName;
    }
    _putIfPresent(body, 'collection_notes', collectionNotes);

    try {
      final envelope = await _client.post(
        '/packages/$packageId/collect',
        body: body,
      );
      final data = envelope['data'];

      // The refined collect response may be an operation/result payload instead
      // of the full Package detail. Decode directly only when the full package
      // shape is present; otherwise refetch the canonical durable record.
      if (data is Map<String, dynamic> && _looksLikeFullPackagePayload(data)) {
        return SecurityPackageApiDecoder.decodePackage(data);
      }

      final reloaded = await findById(packageId);
      if (reloaded == null) {
        throw const SecurityPackageRepositoryException(
          SecurityPackageRepositoryFailureCode.packageNotFound,
        );
      }
      return reloaded;
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw SecurityPackageRepositoryException(
        SecurityPackageRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  static String _statusWireValue(SecurityPackageStatus status) => switch (status) {
        SecurityPackageStatus.readyForPickup => 'Ready for Pickup',
        SecurityPackageStatus.collected => 'Collected',
        SecurityPackageStatus.expired => 'Expired',
      };

  static String _recipientTypeWireValue(
    SecurityPackageCollectionRecipientType type,
  ) =>
      switch (type) {
        SecurityPackageCollectionRecipientType.resident => 'resident',
        SecurityPackageCollectionRecipientType.others => 'others',
      };

  static bool _looksLikeFullPackagePayload(Map<String, dynamic> data) {
    return data['package_no'] != null &&
        data['courier_name'] != null &&
        data['resident'] is Map<String, dynamic> &&
        data['received_at'] != null;
  }

  static void _putIfPresent(
    Map<String, dynamic> target,
    String key,
    String? value,
  ) {
    final normalized = _nonEmpty(value);
    if (normalized != null) target[key] = normalized;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, dynamic> _requiredObject(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Package response data must be an object.');
    }
    return value;
  }

  static SecurityPackageRepositoryException _mapError(
    SecurityApiException error,
  ) {
    final code = switch (error.code) {
      'UNAUTHENTICATED' || 'SECURITY_INVALID_CREDENTIALS' =>
        SecurityPackageRepositoryFailureCode.unauthorized,
      'FORBIDDEN' || 'SECURITY_PROPERTY_UNAVAILABLE' =>
        SecurityPackageRepositoryFailureCode.forbidden,
      'PACKAGE_CENTER_UNAVAILABLE' =>
        SecurityPackageRepositoryFailureCode.centerUnavailable,
      'PACKAGE_RESIDENT_NOT_FOUND' =>
        SecurityPackageRepositoryFailureCode.residentNotFound,
      'PACKAGE_NOT_FOUND' => SecurityPackageRepositoryFailureCode.packageNotFound,
      'PACKAGE_COLLECTION_RESIDENT_UNAVAILABLE' =>
        SecurityPackageRepositoryFailureCode.collectionResidentUnavailable,
      'VALIDATION_ERROR' => SecurityPackageRepositoryFailureCode.validation,
      'NETWORK_ERROR' || 'NETWORK_TIMEOUT' =>
        SecurityPackageRepositoryFailureCode.network,
      _ => SecurityPackageRepositoryFailureCode.unknown,
    };
    return SecurityPackageRepositoryException(
      code,
      message: error.message,
      fieldErrors: error.errors,
    );
  }
}
