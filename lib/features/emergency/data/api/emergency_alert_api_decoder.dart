import '../../domain/models/emergency_alert_models.dart';

abstract final class EmergencyAlertApiDecoder {
  static EmergencyAlert decodeAlert(Map<String, dynamic> data) {
    return EmergencyAlert(
      emergencyAlertId: _requiredInt(data, 'emergency_alert_id'),
      alertCode: _requiredString(data, 'alert_code'),
      status: decodeStatus(_requiredString(data, 'status')),
      message: _nullableString(data['message']),
      modalRequired: _boolOrDefault(data['modal_required'], false),
      takenByMe: _boolOrDefault(data['taken_by_me'], false),
      property: _decodeProperty(_requiredObject(data['property'], 'property')),
      resident: _decodeResident(_requiredObject(data['resident'], 'resident')),
      unit: _decodeUnit(_requiredObject(data['unit'], 'unit')),
      triggeredAt: _requiredDateTime(data, 'triggered_at'),
      acknowledgedAt: _dateTime(data['acknowledged_at']),
      acknowledgedBy: data['acknowledged_by'] == null
          ? null
          : _decodeActor(
              _requiredObject(data['acknowledged_by'], 'acknowledged_by'),
            ),
      resolvedAt: _dateTime(data['resolved_at']),
      resolvedBy: data['resolved_by'] == null
          ? null
          : _decodeActor(
              _requiredObject(data['resolved_by'], 'resolved_by'),
            ),
      resolutionNotes: _nullableString(data['resolution_notes']),
    );
  }

  static EmergencyAlertStatus decodeStatus(String value) => switch (value) {
        'Open' => EmergencyAlertStatus.open,
        'Acknowledged' => EmergencyAlertStatus.acknowledged,
        'Resolved' => EmergencyAlertStatus.resolved,
        _ => throw FormatException('Unsupported Emergency status: $value'),
      };

  static EmergencyPropertyRef _decodeProperty(Map<String, dynamic> data) {
    return EmergencyPropertyRef(
      id: _requiredInt(data, 'id'),
      code: _requiredString(data, 'code'),
      name: _requiredString(data, 'name'),
    );
  }

  static EmergencyResidentRef _decodeResident(Map<String, dynamic> data) {
    return EmergencyResidentRef(
      id: _requiredInt(data, 'id'),
      name: _requiredString(data, 'name'),
      mobileNo: _nullableString(data['mobile_no']),
    );
  }

  static EmergencyUnitRef _decodeUnit(Map<String, dynamic> data) {
    return EmergencyUnitRef(
      id: _requiredInt(data, 'id'),
      code: _requiredString(data, 'code'),
      tower: _nullableString(data['tower']),
      floor: _nullableInt(data['floor']),
    );
  }

  static EmergencyActorRef _decodeActor(Map<String, dynamic> data) {
    return EmergencyActorRef(
      id: _requiredInt(data, 'id'),
      name: _requiredString(data, 'name'),
    );
  }

  static Map<String, dynamic> _requiredObject(dynamic value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Emergency field $field must be an object.');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = _nullableString(data[key]);
    if (value == null) {
      throw FormatException('Emergency field $key is required.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> data, String key) {
    final value = _nullableInt(data[key]);
    if (value == null) {
      throw FormatException('Emergency field $key must be an integer.');
    }
    return value;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static bool _boolOrDefault(dynamic value, bool fallback) {
    return value is bool ? value : fallback;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> data, String key) {
    final value = _dateTime(data[key]);
    if (value == null) {
      throw FormatException('Emergency field $key must be ISO-8601.');
    }
    return value;
  }

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw const FormatException('Emergency timestamp must be a string.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid Emergency timestamp: $value');
    }
    return parsed;
  }

  static String? _nullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
