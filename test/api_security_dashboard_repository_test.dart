import 'package:nsecure/core/network/security_api_client.dart';
import 'package:nsecure/features/security/data/api/api_security_dashboard_repository.dart';
import 'package:nsecure/features/security/domain/repositories/security_dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiSecurityDashboardRepository', () {
    test('loads database-backed Security dashboard metrics', () async {
      final client = _FakeDashboardClient(
        response: <String, dynamic>{
          'status': 'success',
          'message': 'Dashboard loaded.',
          'data': <String, dynamic>{
            'property': <String, dynamic>{
              'id': 1,
              'code': 'DEFAULT',
              'name': 'Aparthub Property',
            },
            'today': <String, dynamic>{
              'total_visitors': 4,
              'pending_approval': 1,
              'approved_arrivals': 2,
              'checked_in': 1,
              'checked_out': 0,
            },
          },
        },
      );
      final repository = ApiSecurityDashboardRepository(client);

      final dashboard = await repository.load();

      expect(client.lastPath, '/dashboard');
      expect(dashboard.property.id, 1);
      expect(dashboard.totalVisitors, 4);
      expect(dashboard.pendingApproval, 1);
      expect(dashboard.approvedArrivals, 2);
      expect(dashboard.checkedIn, 1);
      expect(dashboard.checkedOut, 0);
    });

    test('property unavailable maps by stable code', () async {
      final client = _FakeDashboardClient(
        error: const SecurityApiException(
          statusCode: 403,
          code: 'SECURITY_PROPERTY_UNAVAILABLE',
          message: 'No accessible Security property.',
        ),
      );
      final repository = ApiSecurityDashboardRepository(client);

      await expectLater(
        repository.load(),
        throwsA(
          isA<SecurityDashboardException>().having(
            (error) => error.code,
            'code',
            SecurityDashboardFailureCode.forbidden,
          ),
        ),
      );
    });
  });
}

class _FakeDashboardClient implements SecurityApiClient {
  _FakeDashboardClient({this.response, this.error});

  final Map<String, dynamic>? response;
  final SecurityApiException? error;
  String? lastPath;

  @override
  String? bearerToken = 'token';

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) async {
    lastPath = path;
    final failure = error;
    if (failure != null) throw failure;
    return response!;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    bool authenticated = true,
  }) {
    throw UnimplementedError();
  }
}
