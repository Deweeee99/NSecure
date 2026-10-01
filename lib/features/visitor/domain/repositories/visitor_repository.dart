import '../models/visitor_visit.dart';

enum VisitorRepositoryFailureCode {
  visitNotFound,
  invalidQr,
  expiredVisit,
  notValidToday,
  pendingApproval,
  rejectedVisit,
  blacklisted,
  cancelledVisit,
  alreadyCheckedIn,
  alreadyCheckedOut,
  invalidState,
  validation,
  unauthorized,
  forbidden,
  network,
  unknown,
}

class VisitorRepositoryException implements Exception {
  const VisitorRepositoryException(this.code, {this.message});

  final VisitorRepositoryFailureCode code;
  final String? message;

  @override
  String toString() {
    final detail = message;
    return detail == null
        ? 'VisitorRepositoryException(${code.name})'
        : 'VisitorRepositoryException(${code.name}): $detail';
  }
}

enum VisitorVerificationMethod {
  manual,
  qr,
}

abstract interface class VisitorRepository {
  Future<List<VisitorVisit>> search(String query);

  Future<VisitorVisit> verifyQrPayload(String qrPayload);

  Future<VisitorVisit?> findByVisitId(String visitId);

  Future<VisitorVisit> checkIn(
    String visitId, {
    VisitorVerificationMethod method = VisitorVerificationMethod.manual,
    String? qrPayload,
  });

  Future<VisitorVisit> checkOut(String visitId);

  Future<List<VisitorVisit>> history();
}
