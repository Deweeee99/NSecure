import '../../domain/models/visitor_visit.dart';

abstract final class VisitorApiDecoder {
  static VisitorVisit decode(Map<String, dynamic> data) {
    return VisitorVisit(
      visitId: _requiredScalar(data, 'visit_id'),
      visitCode: _requiredString(data, 'visit_code'),
      visitorId: _requiredScalar(data, 'visitor_id'),
      visitorName: _requiredString(data, 'visitor_name'),
      visitorPhone: _string(data['visitor_phone']) ?? '',
      residentName: _string(data['resident_name']) ?? 'Resident unavailable',
      propertyName: _string(data['property_name']) ?? 'Property unavailable',
      towerName: _string(data['tower_name']),
      unitName: _string(data['unit_name']),
      purpose: _string(data['purpose']) ?? _string(data['visit_purpose']) ?? '',
      scheduledAt: _dateTime(data['scheduled_at']),
      validFrom: _dateTime(data['valid_from']),
      validUntil: _dateTime(data['valid_until']),
      status: decodeStatus(_requiredString(data, 'status')),
      checkedInAt: _dateTime(data['checked_in_at']),
      checkedOutAt: _dateTime(data['checked_out_at']),
      checkedInBy: _actorName(data['checked_in_by']),
      checkedOutBy: _actorName(data['checked_out_by']),
      identityPhotoUrl: _string(data['identity_photo_url']),
      serverCanCheckIn: _bool(data['can_check_in']),
      serverCanCheckOut: _bool(data['can_check_out']),
    );
  }

  static VisitorStatus decodeStatus(String wireValue) {
    return switch (wireValue) {
      'Pending' => VisitorStatus.pending,
      'Approved' => VisitorStatus.approved,
      'Rejected' => VisitorStatus.rejected,
      'Checked In' => VisitorStatus.checkedIn,
      'Checked Out' => VisitorStatus.checkedOut,
      'Cancelled' => VisitorStatus.cancelled,
      'Expired' => VisitorStatus.expired,
      _ => throw FormatException('Unsupported Visitor status: $wireValue'),
    };
  }

  static String _requiredScalar(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      throw FormatException('Visitor field $key is required.');
    }
    return '$value';
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = _string(data[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Visitor field $key is required.');
    }
    return value;
  }

  static String? _string(dynamic value) {
    if (value is! String) return null;
    return value.trim().isEmpty ? null : value;
  }

  static bool? _bool(dynamic value) {
    return value is bool ? value : null;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _actorName(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _string(value['name']);
    }
    return null;
  }
}
