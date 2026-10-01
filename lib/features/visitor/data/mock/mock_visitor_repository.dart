import '../../domain/models/visitor_visit.dart';
import '../../domain/repositories/visitor_repository.dart';

class MockVisitorRepository implements VisitorRepository {
  MockVisitorRepository({
    List<VisitorVisit>? seed,
    this.actorName = 'Security Team',
  }) : _visits = List<VisitorVisit>.of(seed ?? _defaultSeed);

  final List<VisitorVisit> _visits;
  final String actorName;

  @override
  Future<VisitorVisit> verifyQrPayload(String qrPayload) async {
    for (final visit in _visits) {
      if (visit.qrPayload == qrPayload) {
        return visit;
      }
    }
    throw const VisitorRepositoryException(
      VisitorRepositoryFailureCode.invalidQr,
    );
  }

  @override
  Future<VisitorVisit?> findByVisitId(String visitId) async {
    final index = _indexOfVisit(visitId);
    return index < 0 ? null : _visits[index];
  }

  @override
  Future<VisitorVisit> checkIn(
    String visitId, {
    VisitorVerificationMethod method = VisitorVerificationMethod.manual,
    String? qrPayload,
  }) async {
    final index = _indexOfVisit(visitId);
    if (index < 0) {
      throw const VisitorRepositoryException(
        VisitorRepositoryFailureCode.visitNotFound,
      );
    }

    final current = _visits[index];
    if (!current.canCheckIn) {
      throw VisitorRepositoryException(_checkInFailureCode(current.status));
    }

    if (method == VisitorVerificationMethod.qr && current.qrPayload != qrPayload) {
      throw const VisitorRepositoryException(
        VisitorRepositoryFailureCode.invalidQr,
      );
    }

    final baseTime = current.validFrom ?? current.scheduledAt ?? DateTime(2024);
    final updated = current.copyWith(
      status: VisitorStatus.checkedIn,
      checkedInAt: baseTime.add(const Duration(hours: 1, minutes: 24)),
      checkedInBy: actorName,
    );
    _visits[index] = updated;
    return updated;
  }

  @override
  Future<VisitorVisit> checkOut(String visitId) async {
    final index = _indexOfVisit(visitId);
    if (index < 0) {
      throw const VisitorRepositoryException(
        VisitorRepositoryFailureCode.visitNotFound,
      );
    }

    final current = _visits[index];
    if (!current.canCheckOut) {
      throw VisitorRepositoryException(_checkOutFailureCode(current.status));
    }

    final checkInAt = current.checkedInAt ?? current.validFrom ?? current.scheduledAt ?? DateTime(2024);
    final updated = current.copyWith(
      status: VisitorStatus.checkedOut,
      checkedOutAt: checkInAt.add(const Duration(hours: 4, minutes: 11)),
      checkedOutBy: actorName,
    );
    _visits[index] = updated;
    return updated;
  }

  @override
  Future<List<VisitorVisit>> history() async {
    final visits = _visits
        .where(
          (visit) =>
              visit.status == VisitorStatus.checkedIn ||
              visit.status == VisitorStatus.checkedOut ||
              visit.status == VisitorStatus.pending ||
              visit.status == VisitorStatus.expired,
        )
        .toList(growable: false);

    visits.sort(
      (left, right) => _activityTime(right).compareTo(_activityTime(left)),
    );
    return visits;
  }

  @override
  Future<List<VisitorVisit>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    return _visits.where((visit) {
      return visit.visitCode.toLowerCase().contains(normalized) ||
          visit.visitorId.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }

  int _indexOfVisit(String visitId) {
    final normalized = visitId.trim().toLowerCase();
    return _visits.indexWhere(
      (visit) => visit.visitId.toLowerCase() == normalized,
    );
  }

  static VisitorRepositoryFailureCode _checkInFailureCode(
    VisitorStatus status,
  ) {
    return switch (status) {
      VisitorStatus.expired => VisitorRepositoryFailureCode.expiredVisit,
      VisitorStatus.rejected => VisitorRepositoryFailureCode.rejectedVisit,
      VisitorStatus.cancelled => VisitorRepositoryFailureCode.cancelledVisit,
      VisitorStatus.checkedIn => VisitorRepositoryFailureCode.alreadyCheckedIn,
      VisitorStatus.checkedOut =>
        VisitorRepositoryFailureCode.alreadyCheckedOut,
      VisitorStatus.pending => VisitorRepositoryFailureCode.invalidState,
      VisitorStatus.approved => VisitorRepositoryFailureCode.invalidState,
    };
  }

  static VisitorRepositoryFailureCode _checkOutFailureCode(
    VisitorStatus status,
  ) {
    return switch (status) {
      VisitorStatus.checkedOut =>
        VisitorRepositoryFailureCode.alreadyCheckedOut,
      VisitorStatus.expired => VisitorRepositoryFailureCode.expiredVisit,
      VisitorStatus.rejected => VisitorRepositoryFailureCode.rejectedVisit,
      VisitorStatus.cancelled => VisitorRepositoryFailureCode.cancelledVisit,
      VisitorStatus.pending => VisitorRepositoryFailureCode.invalidState,
      VisitorStatus.approved => VisitorRepositoryFailureCode.invalidState,
      VisitorStatus.checkedIn => VisitorRepositoryFailureCode.invalidState,
    };
  }

  static DateTime _activityTime(VisitorVisit visit) {
    return visit.checkedOutAt ?? visit.checkedInAt ?? visit.scheduledAt ?? DateTime(1970);
  }

  static final List<VisitorVisit> _defaultSeed = [
    VisitorVisit(
      visitId: '245',
      visitCode: 'VST-240515-0012',
      visitorId: '245',
      visitorName: 'John Michael Doe',
      visitorPhone: '+62 812 5550 245',
      residentName: 'Alexandra Smith',
      propertyName: 'Aparthub Residence',
      towerName: 'Tower A',
      unitName: '12A',
      purpose: 'Personal Visit',
      scheduledAt: DateTime(2024, 5, 15, 9),
      validFrom: DateTime(2024, 5, 15, 9),
      validUntil: DateTime(2024, 5, 15, 18),
      status: VisitorStatus.approved,
      qrPayload: 'SEC-QR-DEMO-000245',
    ),
    VisitorVisit(
      visitId: '301',
      visitCode: 'VST-240515-0011',
      visitorId: '301',
      visitorName: 'Sarah Williams',
      visitorPhone: '+62 812 5550 301',
      residentName: 'David Lee',
      propertyName: 'Aparthub Residence',
      towerName: 'Tower A',
      unitName: '10A',
      purpose: 'Personal Visit',
      scheduledAt: DateTime(2024, 5, 15, 10),
      validFrom: DateTime(2024, 5, 15, 10),
      validUntil: DateTime(2024, 5, 15, 17),
      status: VisitorStatus.checkedIn,
      qrPayload: 'SEC-QR-DEMO-000301',
      checkedInAt: DateTime(2024, 5, 15, 10, 24),
      checkedInBy: 'Security Team',
    ),
    VisitorVisit(
      visitId: '410',
      visitCode: 'VST-240515-0010',
      visitorId: '410',
      visitorName: 'Robert Brown',
      visitorPhone: '+62 812 5550 410',
      residentName: 'Emily Johnson',
      propertyName: 'Aparthub Residence',
      towerName: 'Tower B',
      unitName: '8B',
      purpose: 'Personal Visit',
      scheduledAt: DateTime(2024, 5, 15, 14),
      validFrom: DateTime(2024, 5, 15, 14),
      validUntil: DateTime(2024, 5, 15, 20),
      status: VisitorStatus.pending,
      qrPayload: 'SEC-QR-DEMO-000410',
    ),
    VisitorVisit(
      visitId: '487',
      visitCode: 'VST-240514-0087',
      visitorId: '487',
      visitorName: 'Priya Patel',
      visitorPhone: '+62 812 5550 487',
      residentName: 'Olivia Martin',
      propertyName: 'Aparthub Residence',
      towerName: 'Tower A',
      unitName: '7A',
      purpose: 'Family Visit',
      scheduledAt: DateTime(2024, 5, 14, 11),
      validFrom: DateTime(2024, 5, 14, 11),
      validUntil: DateTime(2024, 5, 14, 19),
      status: VisitorStatus.checkedOut,
      qrPayload: 'SEC-QR-DEMO-000487',
      checkedInAt: DateTime(2024, 5, 14, 11, 18),
      checkedOutAt: DateTime(2024, 5, 14, 16, 20),
      checkedInBy: 'Security Team',
      checkedOutBy: 'Security Team',
    ),
    VisitorVisit(
      visitId: '399',
      visitCode: 'VST-240514-0099',
      visitorId: '399',
      visitorName: 'Michael Chen',
      visitorPhone: '+62 812 5550 399',
      residentName: 'James Lee',
      propertyName: 'Aparthub Residence',
      towerName: 'Tower B',
      unitName: '1C',
      purpose: 'Delivery',
      scheduledAt: DateTime(2024, 5, 14, 9),
      validFrom: DateTime(2024, 5, 14, 9),
      validUntil: DateTime(2024, 5, 14, 18),
      status: VisitorStatus.expired,
      qrPayload: 'SEC-QR-DEMO-000399',
    ),
  ];
}
