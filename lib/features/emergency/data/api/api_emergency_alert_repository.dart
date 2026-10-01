import '../../../../core/network/security_api_client.dart';
import '../../domain/models/emergency_alert_models.dart';
import '../../domain/repositories/emergency_alert_repository.dart';
import 'emergency_alert_api_decoder.dart';

class ApiEmergencyAlertRepository implements EmergencyAlertRepository {
  ApiEmergencyAlertRepository(this._client);

  final SecurityApiClient _client;

  @override
  Future<List<EmergencyAlert>> activeAlerts() {
    return _list('/emergency-alerts/active');
  }

  @override
  Future<List<EmergencyAlert>> unresolvedAlerts() {
    return _list('/emergency-alerts');
  }

  @override
  Future<List<EmergencyAlert>> history() {
    return _list('/emergency-alerts/history');
  }

  @override
  Future<EmergencyAlert?> findById(int emergencyAlertId) async {
    try {
      final envelope = await _client.get('/emergency-alerts/$emergencyAlertId');
      return EmergencyAlertApiDecoder.decodeAlert(
        _requiredObject(envelope['data']),
      );
    } on SecurityApiException catch (error) {
      if (error.code == 'EMERGENCY_ALERT_NOT_FOUND') return null;
      throw _mapError(error);
    } on FormatException catch (error) {
      throw EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<EmergencyAlert> acknowledge(int emergencyAlertId) async {
    try {
      final envelope = await _client.post(
        '/emergency-alerts/$emergencyAlertId/acknowledge',
      );
      return _decodeMutationOrReload(envelope, emergencyAlertId);
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  @override
  Future<EmergencyAlert> resolve(
    int emergencyAlertId, {
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    final normalizedNotes = _nonEmpty(notes);
    if (normalizedNotes != null) {
      body['notes'] = normalizedNotes;
    }

    try {
      final envelope = await _client.post(
        '/emergency-alerts/$emergencyAlertId/resolve',
        body: body,
      );
      return _decodeMutationOrReload(envelope, emergencyAlertId);
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  Future<List<EmergencyAlert>> _list(String path) async {
    try {
      final envelope = await _client.get(
        path,
        query: path.endsWith('/active')
            ? const <String, String?>{}
            : const <String, String?>{'per_page': '30'},
      );
      final data = envelope['data'];
      if (data is! List) {
        throw const FormatException('Emergency list data must be an array.');
      }
      return data
          .map(
            (item) => EmergencyAlertApiDecoder.decodeAlert(
              _requiredObject(item),
            ),
          )
          .toList(growable: false);
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.unknown,
        message: error.message,
      );
    }
  }

  Future<EmergencyAlert> _decodeMutationOrReload(
    Map<String, dynamic> envelope,
    int emergencyAlertId,
  ) async {
    final data = envelope['data'];
    if (data is Map<String, dynamic> && data['emergency_alert_id'] != null) {
      return EmergencyAlertApiDecoder.decodeAlert(data);
    }
    final reloaded = await findById(emergencyAlertId);
    if (reloaded == null) {
      throw const EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.notFound,
      );
    }
    return reloaded;
  }

  static Map<String, dynamic> _requiredObject(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Emergency response data must be an object.');
    }
    return value;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static EmergencyRepositoryException _mapError(SecurityApiException error) {
    final code = switch (error.code) {
      'UNAUTHENTICATED' || 'SECURITY_INVALID_CREDENTIALS' =>
        EmergencyRepositoryFailureCode.unauthorized,
      'FORBIDDEN' || 'SECURITY_PROPERTY_UNAVAILABLE' =>
        EmergencyRepositoryFailureCode.forbidden,
      'EMERGENCY_ALERT_NOT_FOUND' => EmergencyRepositoryFailureCode.notFound,
      'EMERGENCY_ALREADY_TAKEN' => EmergencyRepositoryFailureCode.alreadyTaken,
      'EMERGENCY_ALREADY_RESOLVED' =>
        EmergencyRepositoryFailureCode.alreadyResolved,
      'EMERGENCY_NOT_ACKNOWLEDGED' =>
        EmergencyRepositoryFailureCode.notAcknowledged,
      'EMERGENCY_ASSIGNED_TO_OTHER' =>
        EmergencyRepositoryFailureCode.assignedToOther,
      'VALIDATION_ERROR' => EmergencyRepositoryFailureCode.validation,
      'NETWORK_ERROR' || 'NETWORK_TIMEOUT' => EmergencyRepositoryFailureCode.network,
      _ => EmergencyRepositoryFailureCode.unknown,
    };
    return EmergencyRepositoryException(
      code,
      message: error.message,
      fieldErrors: error.errors,
    );
  }
}
