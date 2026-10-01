import '../models/security_package_models.dart';

enum SecurityPackageRepositoryFailureCode {
  centerUnavailable,
  residentNotFound,
  packageNotFound,
  validation,
  collectionResidentUnavailable,
  unauthorized,
  forbidden,
  network,
  unknown,
}

class SecurityPackageRepositoryException implements Exception {
  const SecurityPackageRepositoryException(
    this.code, {
    this.message,
    this.fieldErrors = const <String, dynamic>{},
  });

  final SecurityPackageRepositoryFailureCode code;
  final String? message;
  final Map<String, dynamic> fieldErrors;

  @override
  String toString() {
    return 'SecurityPackageRepositoryException(${code.name}): ${message ?? 'no detail'}';
  }
}

abstract interface class SecurityPackageRepository {
  Future<List<SecurityPackageResidentLookup>> searchResidents({
    String? query,
    int? propertyId,
    int limit = 30,
  });

  Future<List<SecurityPackageRecord>> packages({
    SecurityPackageStatus? status,
    String? search,
    int? propertyId,
  });

  Future<SecurityPackageRecord?> findById(int packageId);

  Future<SecurityPackageRecord> receivePackage(
    SecurityPackageReceiveInput input,
  );

  Future<SecurityPackageRecord> collectPackage(
    int packageId, {
    required SecurityPackageCollectionRecipientType recipientType,
    String? collectionRecipientName,
    String? collectionNotes,
  });
}
