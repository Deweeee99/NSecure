import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';

import '../../../../core/theme/security_tokens.dart';

class ManualVisitorSearchScreen extends StatefulWidget {
  const ManualVisitorSearchScreen({
    required this.isLoading,
    required this.onBack,
    required this.onSearch,
    this.recentSearches = const <String>[],
    this.onClearRecentSearches,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onBack;
  final Future<void> Function(String query) onSearch;
  final List<String> recentSearches;
  final VoidCallback? onClearRecentSearches;

  @override
  State<ManualVisitorSearchScreen> createState() =>
      _ManualVisitorSearchScreenState();
}

class _ManualVisitorSearchScreenState extends State<ManualVisitorSearchScreen> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _ManualHeader(onBack: widget.onBack),
          if (widget.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                SecuritySpacing.md,
                SecuritySpacing.md,
                SecuritySpacing.md,
                SecuritySpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('manualVisitorQuery'),
                    controller: _controller,
                    enabled: !widget.isLoading,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: context.l10n.searchByVisitCodeOrId,
                      errorText: _errorText,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        tooltip: context.l10n.search,
                        onPressed: widget.isLoading ? null : _submit,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: SecuritySpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SecuritySpacing.md),
                    decoration: BoxDecoration(
                      color: SecurityColors.primarySoft,
                      borderRadius: BorderRadius.circular(SecurityRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: SecurityColors.primary,
                        ),
                        const SizedBox(width: SecuritySpacing.sm),
                        Expanded(
                          child: Text(
                            '${context.l10n.visitCodeExample}\n${context.l10n.visitIdExample}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: SecurityColors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SecuritySpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('manualVisitorSearchButton'),
                      onPressed: widget.isLoading ? null : _submit,
                      icon: const Icon(Icons.search_rounded),
                      label: Text(context.l10n.searchVisitor),
                    ),
                  ),
                  if (widget.recentSearches.isNotEmpty) ...[
                    const SizedBox(height: SecuritySpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.recentSearches,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.isLoading
                              ? null
                              : widget.onClearRecentSearches,
                          child: Text(context.l10n.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: SecuritySpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        color: SecurityColors.surface,
                        borderRadius: BorderRadius.circular(SecurityRadius.lg),
                        border: Border.all(color: SecurityColors.border),
                        boxShadow: SecurityShadows.soft,
                      ),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < widget.recentSearches.length;
                              index++) ...[
                            _RecentSearchRow(
                              value: widget.recentSearches[index],
                              enabled: !widget.isLoading,
                              onTap: () =>
                                  _useRecent(widget.recentSearches[index]),
                            ),
                            if (index != widget.recentSearches.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _useRecent(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _submit();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorText = context.l10n.enterVisitCodeOrId;
      });
      return;
    }

    setState(() => _errorText = null);
    widget.onSearch(query);
  }
}

class _ManualHeader extends StatelessWidget {
  const _ManualHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: SecurityColors.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: context.l10n.backToQrVerification,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              context.l10n.manualVerify,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SecuritySpacing.md,
          vertical: SecuritySpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 18,
              color: SecurityColors.textMuted,
            ),
            const SizedBox(width: SecuritySpacing.sm),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SecurityColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: SecurityColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
