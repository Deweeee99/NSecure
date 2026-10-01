import '../models/security_user.dart';

enum SecurityAuthFailureCode {
  invalidCredentials,
  unauthenticated,
  forbidden,
  validation,
  network,
  unknown,
}

class SecurityAuthException implements Exception {
  const SecurityAuthException(this.code, {this.message});

  final SecurityAuthFailureCode code;
  final String? message;
}

abstract interface class SecurityAuthRepository {
  Future<SecurityUser> login({
    required String username,
    required String password,
  });

  Future<SecurityUser?> restoreSession();

  Future<SecurityUser> me();

  Future<void> logout();

  bool get hasSession;
}
