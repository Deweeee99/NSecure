import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';

import '../../domain/models/visitor_visit.dart';
import '../../domain/repositories/visitor_repository.dart';
import '../detail/visitor_action_confirmation_screen.dart';
import '../detail/visitor_detail_screen.dart';
import '../widgets/visitor_repository_failure_message.dart';
import 'manual_visitor_search_screen.dart';
import 'qr_visitor_verification_screen.dart';
import 'visitor_search_results_screen.dart';

enum _VerificationStage { qr, manual, results, detail, confirmation }

enum _ResultOrigin { qr, manual }

class VisitorVerificationFlow extends StatefulWidget {
  const VisitorVerificationFlow({
    required this.repository,
    required this.enableDeviceQrScanner,
    required this.onBackHome,
    required this.onVisitUpdated,
    this.onSessionExpired,
    super.key,
  });

  final VisitorRepository repository;
  final bool enableDeviceQrScanner;
  final VoidCallback onBackHome;
  final VoidCallback onVisitUpdated;
  final Future<void> Function()? onSessionExpired;

  @override
  State<VisitorVerificationFlow> createState() =>
      VisitorVerificationFlowState();
}

class VisitorVerificationFlowState extends State<VisitorVerificationFlow> {
  _VerificationStage _stage = _VerificationStage.qr;
  _ResultOrigin _resultOrigin = _ResultOrigin.manual;
  List<VisitorVisit> _results = const [];
  VisitorVisit? _selectedVisit;
  VisitorActionType? _confirmationType;
  String _query = '';
  bool _loading = false;
  String? _verifiedQrPayload;
  List<String> _recentManualSearches = const <String>[];

  @override
  Widget build(BuildContext context) {
    final content = switch (_stage) {
      _VerificationStage.qr => QrVisitorVerificationScreen(
          isLoading: _loading,
          onBack: widget.onBackHome,
          enableDeviceScanner: widget.enableDeviceQrScanner,
          onOpenManual: _openManual,
          onQrDetected: _scanQrPayload,
        ),
      _VerificationStage.manual => ManualVisitorSearchScreen(
          isLoading: _loading,
          onBack: _openQr,
          onSearch: _searchManual,
          recentSearches: _recentManualSearches,
          onClearRecentSearches: _clearRecentManualSearches,
        ),
      _VerificationStage.results => VisitorSearchResultsScreen(
          query: _query,
          results: _results,
          resultOriginLabel:
              _resultOrigin == _ResultOrigin.qr ? context.l10n.qrVerification : context.l10n.manualVerify,
          onBack: _backFromResults,
          onVisitorSelected: _openVisitorDetail,
        ),
      _VerificationStage.detail => VisitorDetailScreen(
          visit: _selectedVisit!,
          isLoading: _loading,
          onBack: _backToResults,
          onCheckIn: _checkInSelected,
          onCheckOut: _checkOutSelected,
        ),
      _VerificationStage.confirmation => VisitorActionConfirmationScreen(
          actionType: _confirmationType!,
          visit: _selectedVisit!,
          onDone: _finishAndGoHome,
          onContinueVerifying: _continueVerifying,
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(
        key: ValueKey(_stage),
        child: content,
      ),
    );
  }

  void _openQr() {
    if (_loading) return;
    setState(() => _stage = _VerificationStage.qr);
  }

  void _openManual() {
    if (_loading) return;
    setState(() => _stage = _VerificationStage.manual);
  }

  Future<void> _scanQrPayload(String qrPayload) async {
    if (_loading || qrPayload.isEmpty) return;

    setState(() => _loading = true);
    try {
      final visit = await widget.repository.verifyQrPayload(qrPayload);
      if (!mounted) return;

      setState(() {
        _loading = false;
        _query = visit.visitCode;
        _verifiedQrPayload = qrPayload;
        _results = [visit];
        _resultOrigin = _ResultOrigin.qr;
        _stage = _VerificationStage.results;
      });
    } on VisitorRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      _showActionError(visitorVerificationFailureMessage(context, error));
    }
  }

  Future<void> _searchManual(String query) async {
    final normalized = query.trim();
    if (_loading || normalized.isEmpty) return;

    setState(() => _loading = true);
    try {
      final results = await widget.repository.search(normalized);
      if (!mounted) return;

      setState(() {
        _loading = false;
        _query = normalized;
        _results = results;
        _resultOrigin = _ResultOrigin.manual;
        _verifiedQrPayload = null;
        _recentManualSearches = <String>[
          normalized,
          ..._recentManualSearches.where((value) => value != normalized),
        ].take(5).toList(growable: false);
        _stage = _VerificationStage.results;
      });
    } on VisitorRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      _showActionError(visitorVerificationFailureMessage(context, error));
    }
  }

  void _backFromResults() {
    setState(() {
      _stage = _resultOrigin == _ResultOrigin.qr
          ? _VerificationStage.qr
          : _VerificationStage.manual;
    });
  }

  void _openVisitorDetail(VisitorVisit visit) {
    setState(() {
      _selectedVisit = visit;
      _stage = _VerificationStage.detail;
    });
  }

  void _backToResults() {
    setState(() {
      _selectedVisit = null;
      _stage = _VerificationStage.results;
    });
  }

  Future<void> _checkInSelected() async {
    final visit = _selectedVisit;
    if (visit == null || _loading) return;

    setState(() => _loading = true);
    try {
      final updated = await widget.repository.checkIn(
        visit.visitId,
        method: _resultOrigin == _ResultOrigin.qr
            ? VisitorVerificationMethod.qr
            : VisitorVerificationMethod.manual,
        qrPayload: _resultOrigin == _ResultOrigin.qr ? _verifiedQrPayload : null,
      );
      if (!mounted) return;
      setState(() {
        _selectedVisit = updated;
        _results = _replaceResult(updated);
        _confirmationType = VisitorActionType.checkIn;
        _stage = _VerificationStage.confirmation;
        _loading = false;
      });
      widget.onVisitUpdated();
    } on VisitorRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      _showActionError(visitorActionFailureMessage(context, error));
    } on Object {
      if (!mounted) return;
      setState(() => _loading = false);
      _showActionError(context.l10n.visitorActionUnavailable);
    }
  }

  Future<void> _checkOutSelected() async {
    final visit = _selectedVisit;
    if (visit == null || _loading) return;

    setState(() => _loading = true);
    try {
      final updated = await widget.repository.checkOut(visit.visitId);
      if (!mounted) return;
      setState(() {
        _selectedVisit = updated;
        _results = _replaceResult(updated);
        _confirmationType = VisitorActionType.checkOut;
        _stage = _VerificationStage.confirmation;
        _loading = false;
      });
      widget.onVisitUpdated();
    } on VisitorRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      _showActionError(visitorActionFailureMessage(context, error));
    } on Object {
      if (!mounted) return;
      setState(() => _loading = false);
      _showActionError(context.l10n.visitorActionUnavailable);
    }
  }

  List<VisitorVisit> _replaceResult(VisitorVisit updated) {
    return _results
        .map((visit) => visit.visitId == updated.visitId ? updated : visit)
        .toList(growable: false);
  }

  void _finishAndGoHome() {
    _resetVerification();
    widget.onBackHome();
  }

  void _continueVerifying() {
    _resetVerification();
  }

  void _resetVerification() {
    setState(() {
      _stage = _VerificationStage.qr;
      _selectedVisit = null;
      _confirmationType = null;
      _results = const [];
      _query = '';
      _verifiedQrPayload = null;
    });
  }

  void _clearRecentManualSearches() {
    setState(() => _recentManualSearches = const <String>[]);
  }

  bool handleSystemBack() {
    if (_loading) return true;
    switch (_stage) {
      case _VerificationStage.qr:
        return false;
      case _VerificationStage.manual:
        _openQr();
      case _VerificationStage.results:
        _backFromResults();
      case _VerificationStage.detail:
        _backToResults();
      case _VerificationStage.confirmation:
        setState(() {
          _confirmationType = null;
          _stage = _VerificationStage.detail;
        });
    }
    return true;
  }

  Future<bool> _handleSessionExpired(VisitorRepositoryException error) async {
    if (error.code != VisitorRepositoryFailureCode.unauthorized) return false;
    final callback = widget.onSessionExpired;
    if (callback != null) await callback();
    return callback != null;
  }

  void _showActionError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
