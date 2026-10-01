import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../domain/models/security_user.dart';
import '../../domain/repositories/security_auth_repository.dart';
import 'security_login_screen.dart';

class SecurityAuthGate extends StatefulWidget {
  const SecurityAuthGate({
    required this.repository,
    required this.builder,
    super.key,
  });

  final SecurityAuthRepository repository;
  final Widget Function(
    SecurityUser user,
    Future<void> Function() logout,
  ) builder;

  @override
  State<SecurityAuthGate> createState() => _SecurityAuthGateState();
}

enum _SecurityAuthUiError {
  restore,
  api,
  invalidCredentials,
  unauthenticated,
  forbidden,
  validation,
  network,
  unknown,
}

class _SecurityAuthGateState extends State<SecurityAuthGate> {
  SecurityUser? _user;
  bool _loading = true;
  _SecurityAuthUiError? _error;
  String? _backendValidationMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user != null) {
      return widget.builder(user, _logout);
    }

    return SecurityLoginScreen(
      isLoading: _loading,
      errorMessage: _localizedErrorMessage(context),
      onLogin: _login,
    );
  }

  Future<void> _restoreSession() async {
    try {
      final user = await widget.repository.restoreSession();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
        _error = null;
        _backendValidationMessage = null;
      });
    } on SecurityAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _uiErrorFor(error.code);
        _backendValidationMessage = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _SecurityAuthUiError.restore;
        _backendValidationMessage = null;
      });
    }
  }

  Future<void> _login(String username, String password) async {
    setState(() {
      _loading = true;
      _error = null;
      _backendValidationMessage = null;
    });
    try {
      final user = await widget.repository.login(
        username: username,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } on SecurityAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _uiErrorFor(error.code);
        _backendValidationMessage = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _SecurityAuthUiError.api;
        _backendValidationMessage = null;
      });
    }
  }

  Future<void> _logout() async {
    await widget.repository.logout();
    if (!mounted) return;
    setState(() {
      _user = null;
      _loading = false;
      _error = null;
      _backendValidationMessage = null;
    });
  }

  String? _localizedErrorMessage(BuildContext context) {
    final error = _error;
    if (error == null) return null;
    final l10n = context.l10n;
    return switch (error) {
      _SecurityAuthUiError.restore => l10n.authRestoreFailed,
      _SecurityAuthUiError.api => l10n.authApiUnavailable,
      _SecurityAuthUiError.invalidCredentials => l10n.authInvalidCredentials,
      _SecurityAuthUiError.unauthenticated => l10n.authUnauthenticated,
      _SecurityAuthUiError.forbidden => l10n.authForbidden,
      _SecurityAuthUiError.validation =>
        _backendValidationMessage?.trim().isNotEmpty == true
            ? _backendValidationMessage!
            : l10n.authValidation,
      _SecurityAuthUiError.network => l10n.authNetwork,
      _SecurityAuthUiError.unknown => l10n.authApiUnavailable,
    };
  }

  static _SecurityAuthUiError _uiErrorFor(SecurityAuthFailureCode code) {
    return switch (code) {
      SecurityAuthFailureCode.invalidCredentials =>
        _SecurityAuthUiError.invalidCredentials,
      SecurityAuthFailureCode.unauthenticated =>
        _SecurityAuthUiError.unauthenticated,
      SecurityAuthFailureCode.forbidden => _SecurityAuthUiError.forbidden,
      SecurityAuthFailureCode.validation => _SecurityAuthUiError.validation,
      SecurityAuthFailureCode.network => _SecurityAuthUiError.network,
      SecurityAuthFailureCode.unknown => _SecurityAuthUiError.unknown,
    };
  }
}
