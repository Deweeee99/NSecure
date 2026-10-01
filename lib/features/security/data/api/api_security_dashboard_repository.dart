import '../../../../core/network/security_api_client.dart';
import '../../domain/models/security_dashboard.dart';
import '../../domain/models/security_user.dart';
import '../../domain/repositories/security_dashboard_repository.dart';

class ApiSecurityDashboardRepository implements SecurityDashboardRepository {
  ApiSecurityDashboardRepository(this._client);

  final SecurityApiClient _client;

  @override
  Future<SecurityDashboardSnapshot> load() async {
    try {
      final envelope = await _client.get('/dashboard');
      final data = _requiredObject(envelope['data'], 'dashboard data');
      final propertyData = _requiredObject(data['property'], 'dashboard property');
      final today = _requiredObject(data['today'], 'dashboard today');

      return SecurityDashboardSnapshot(
        property: SecurityProperty(
          id: _requiredInt(propertyData, 'id'),
          code: _requiredString(propertyData, 'code'),
          name: _requiredString(propertyData, 'name'),
          isDefault: true,
        ),
        totalVisitors: _requiredInt(today, 'total_visitors'),
        pendingApproval: _requiredInt(today, 'pending_approval'),
        approvedArrivals: _requiredInt(today, 'approved_arrivals'),
        checkedIn: _requiredInt(today, 'checked_in'),
        checkedOut: _requiredInt(today, 'checked_out'),
      );
    } on SecurityApiException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw SecurityDashboardException(
        SecurityDashboardFailureCode.unknown,
        message: error.message,
      );
    }
  }

  static SecurityDashboardException _mapError(SecurityApiException error) {
    final code = switch (error.code) {
      'UNAUTHENTICATED' => SecurityDashboardFailureCode.unauthorized,
      'FORBIDDEN' || 'SECURITY_PROPERTY_UNAVAILABLE' =>
        SecurityDashboardFailureCode.forbidden,
      'NETWORK_ERROR' || 'NETWORK_TIMEOUT' => SecurityDashboardFailureCode.network,
      _ => SecurityDashboardFailureCode.unknown,
    };
    return SecurityDashboardException(code, message: error.message);
  }

  static Map<String, dynamic> _requiredObject(dynamic value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('$field must be an object.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Dashboard field $key must be an integer.');
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Dashboard field $key is required.');
    }
    return value.trim();
  }
}
