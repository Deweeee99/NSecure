import 'security_user.dart';

class SecurityDashboardSnapshot {
  const SecurityDashboardSnapshot({
    required this.property,
    required this.totalVisitors,
    required this.pendingApproval,
    required this.approvedArrivals,
    required this.checkedIn,
    required this.checkedOut,
  });

  final SecurityProperty property;
  final int totalVisitors;
  final int pendingApproval;
  final int approvedArrivals;
  final int checkedIn;
  final int checkedOut;
}
