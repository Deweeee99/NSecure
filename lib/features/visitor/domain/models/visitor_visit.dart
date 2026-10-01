enum VisitorStatus {
  pending,
  approved,
  checkedIn,
  checkedOut,
  expired,
  rejected,
  cancelled,
}

extension VisitorStatusLabel on VisitorStatus {
  String get label => switch (this) {
        VisitorStatus.pending => 'Pending',
        VisitorStatus.approved => 'Approved',
        VisitorStatus.checkedIn => 'Checked-In',
        VisitorStatus.checkedOut => 'Checked-Out',
        VisitorStatus.expired => 'Expired',
        VisitorStatus.rejected => 'Rejected',
        VisitorStatus.cancelled => 'Cancelled',
      };
}

class VisitorVisit {
  const VisitorVisit({
    required this.visitId,
    required this.visitCode,
    required this.visitorId,
    required this.visitorName,
    required this.visitorPhone,
    required this.residentName,
    required this.propertyName,
    required this.purpose,
    required this.status,
    this.towerName,
    this.unitName,
    this.scheduledAt,
    this.validFrom,
    this.validUntil,
    this.qrPayload,
    this.checkedInAt,
    this.checkedOutAt,
    this.checkedInBy,
    this.checkedOutBy,
    this.identityPhotoUrl,
    this.serverCanCheckIn,
    this.serverCanCheckOut,
  });

  final String visitId;
  final String visitCode;
  final String visitorId;
  final String visitorName;
  final String visitorPhone;
  final String residentName;
  final String propertyName;
  final String? towerName;
  final String? unitName;
  final String purpose;
  final DateTime? scheduledAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final VisitorStatus status;

  /// Present only for deterministic mock/demo data. The Security API never
  /// returns the canonical QR/access credential in Visitor payloads.
  final String? qrPayload;

  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? checkedInBy;
  final String? checkedOutBy;
  final String? identityPhotoUrl;

  /// Backend-owned action capabilities from the Security Visitor payload.
  /// Current production API responses expose these as `can_check_in` and
  /// `can_check_out`. Null is retained only for deterministic mocks / legacy
  /// fixtures so those can derive behavior from canonical status.
  final bool? serverCanCheckIn;
  final bool? serverCanCheckOut;

  bool get canCheckIn =>
      serverCanCheckIn ?? status == VisitorStatus.approved;

  bool get canCheckOut =>
      serverCanCheckOut ?? status == VisitorStatus.checkedIn;

  VisitorVisit copyWith({
    VisitorStatus? status,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? checkedInBy,
    String? checkedOutBy,
  }) {
    return VisitorVisit(
      visitId: visitId,
      visitCode: visitCode,
      visitorId: visitorId,
      visitorName: visitorName,
      visitorPhone: visitorPhone,
      residentName: residentName,
      propertyName: propertyName,
      towerName: towerName,
      unitName: unitName,
      purpose: purpose,
      scheduledAt: scheduledAt,
      validFrom: validFrom,
      validUntil: validUntil,
      status: status ?? this.status,
      qrPayload: qrPayload,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      checkedOutBy: checkedOutBy ?? this.checkedOutBy,
      identityPhotoUrl: identityPhotoUrl,
      serverCanCheckIn: serverCanCheckIn,
      serverCanCheckOut: serverCanCheckOut,
    );
  }
}
