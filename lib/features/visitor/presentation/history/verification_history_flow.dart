import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';

import '../../domain/models/visitor_visit.dart';
import '../../domain/repositories/visitor_repository.dart';
import '../detail/visitor_action_confirmation_screen.dart';
import '../detail/visitor_detail_screen.dart';
import '../widgets/visitor_repository_failure_message.dart';
import 'verification_history_screen.dart';

enum _HistoryStage { list, detail, confirmation }

class VerificationHistoryFlow extends StatefulWidget {
  const VerificationHistoryFlow({
    required this.repository,
    required this.refreshRevision,
    required this.onVisitUpdated,
    required this.onContinueVerifying,
    this.onSessionExpired,
    super.key,
  });

  final VisitorRepository repository;
  final int refreshRevision;
  final VoidCallback onVisitUpdated;
  final VoidCallback onContinueVerifying;
  final Future<void> Function()? onSessionExpired;

  @override
  State<VerificationHistoryFlow> createState() => VerificationHistoryFlowState();
}

class VerificationHistoryFlowState extends State<VerificationHistoryFlow> {
  _HistoryStage _stage = _HistoryStage.list;
  VerificationHistoryFilter _filter = VerificationHistoryFilter.all;
  List<VisitorVisit> _visits = const [];
  VisitorVisit? _selectedVisit;
  VisitorActionType? _confirmationType;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant VerificationHistoryFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshRevision != widget.refreshRevision) {
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _HistoryStage.list => VerificationHistoryScreen(
          visits: _visits,
          selectedFilter: _filter,
          isLoading: _loading,
          errorMessage: _errorMessage,
          onRetry: _loadHistory,
          onFilterChanged: (filter) => setState(() => _filter = filter),
          onVisitorSelected: _openDetail,
        ),
      _HistoryStage.detail => VisitorDetailScreen(
          visit: _selectedVisit!,
          isLoading: _loading,
          onBack: _backToHistory,
          onCheckIn: _checkInSelected,
          onCheckOut: _checkOutSelected,
        ),
      _HistoryStage.confirmation => VisitorActionConfirmationScreen(
          actionType: _confirmationType!,
          visit: _selectedVisit!,
          onDone: _backToHistory,
          onContinueVerifying: () {
            _backToHistory();
            widget.onContinueVerifying();
          },
        ),
    };
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final visits = await widget.repository.history();
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _loading = false;
        _errorMessage = null;
      });
    } on VisitorRepositoryException catch (error) {
      if (!mounted) return;
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = visitorHistoryFailureMessage(context, error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = context.l10n.verificationHistoryLoadFailed;
      });
    }
  }

  void _openDetail(VisitorVisit visit) {
    setState(() {
      _selectedVisit = visit;
      _stage = _HistoryStage.detail;
    });
  }

  Future<void> _checkInSelected() async {
    final visit = _selectedVisit;
    if (visit == null || _loading) return;

    setState(() => _loading = true);
    try {
      final updated = await widget.repository.checkIn(visit.visitId);
      if (!mounted) return;
      setState(() {
        _selectedVisit = updated;
        _confirmationType = VisitorActionType.checkIn;
        _stage = _HistoryStage.confirmation;
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
        _confirmationType = VisitorActionType.checkOut;
        _stage = _HistoryStage.confirmation;
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

  void _backToHistory() {
    setState(() {
      _stage = _HistoryStage.list;
      _selectedVisit = null;
      _confirmationType = null;
    });
    _loadHistory();
  }

  bool handleSystemBack() {
    if (_loading && _stage == _HistoryStage.list) return true;
    switch (_stage) {
      case _HistoryStage.list:
        return false;
      case _HistoryStage.detail:
        _backToHistory();
      case _HistoryStage.confirmation:
        setState(() {
          _confirmationType = null;
          _stage = _HistoryStage.detail;
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
