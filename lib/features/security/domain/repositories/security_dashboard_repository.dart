import '../models/security_dashboard.dart';

enum SecurityDashboardFailureCode {
  unauthorized,
  forbidden,
  network,
  unknown,
}

class SecurityDashboardException implements Exception {
  const SecurityDashboardException(this.code, {this.message});

  final SecurityDashboardFailureCode code;
  final String? message;
}

abstract interface class SecurityDashboardRepository {
  Future<SecurityDashboardSnapshot> load();
}
