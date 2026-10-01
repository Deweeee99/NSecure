import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/localization/security_language_button.dart';
import '../../../../core/theme/security_tokens.dart';

class SecurityLoginScreen extends StatefulWidget {
  const SecurityLoginScreen({
    required this.isLoading,
    required this.errorMessage,
    required this.onLogin,
    super.key,
  });

  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(String username, String password) onLogin;

  @override
  State<SecurityLoginScreen> createState() => _SecurityLoginScreenState();
}

class _SecurityLoginScreenState extends State<SecurityLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: SecurityColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: SecuritySpacing.xs,
              right: SecuritySpacing.xs,
              child: const SecurityLanguageButton(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SecuritySpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(SecuritySpacing.lg),
                    decoration: BoxDecoration(
                      color: SecurityColors.surface,
                      borderRadius: BorderRadius.circular(SecurityRadius.xl),
                      border: Border.all(color: SecurityColors.border),
                      boxShadow: SecurityShadows.soft,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: SecurityColors.primarySoft,
                              borderRadius: BorderRadius.circular(SecurityRadius.lg),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: SecurityColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: SecuritySpacing.lg),
                          Text(
                            l10n.appTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: SecuritySpacing.xs),
                          Text(
                            l10n.signInDescription,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: SecuritySpacing.lg),
                          TextFormField(
                            key: const Key('securityUsernameField'),
                            controller: _usernameController,
                            enabled: !widget.isLoading,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.username,
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? l10n.usernameRequired
                                : null,
                          ),
                          const SizedBox(height: SecuritySpacing.sm),
                          TextFormField(
                            key: const Key('securityPasswordField'),
                            controller: _passwordController,
                            enabled: !widget.isLoading,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: widget.isLoading
                                    ? null
                                    : () => setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? l10n.passwordRequired
                                : null,
                          ),
                          if (widget.errorMessage != null) ...[
                            const SizedBox(height: SecuritySpacing.sm),
                            Text(
                              widget.errorMessage!,
                              key: const Key('securityLoginError'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SecurityColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          const SizedBox(height: SecuritySpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const Key('securityLoginButton'),
                              onPressed: widget.isLoading ? null : _submit,
                              child: widget.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(l10n.signIn),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onLogin(
      _usernameController.text.trim(),
      _passwordController.text,
    );
  }
}
