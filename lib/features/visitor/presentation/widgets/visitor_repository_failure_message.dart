import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../domain/repositories/visitor_repository.dart';

String visitorActionFailureMessage(
  BuildContext context,
  VisitorRepositoryException error,
) {
  final l10n = context.l10n;

  return switch (error.code) {
    VisitorRepositoryFailureCode.visitNotFound => l10n.visitorVisitNotFound,
    VisitorRepositoryFailureCode.expiredVisit => l10n.visitExpiredCannotAction,
    VisitorRepositoryFailureCode.notValidToday =>
      l10n.visitNotValidTodayCannotAction,
    VisitorRepositoryFailureCode.pendingApproval =>
      l10n.visitStillPendingApproval,
    VisitorRepositoryFailureCode.rejectedVisit =>
      l10n.visitRejectedCannotAction,
    VisitorRepositoryFailureCode.blacklisted => l10n.visitorBlacklisted,
    VisitorRepositoryFailureCode.cancelledVisit =>
      l10n.visitCancelledCannotAction,
    VisitorRepositoryFailureCode.alreadyCheckedIn =>
      l10n.visitorAlreadyCheckedIn,
    VisitorRepositoryFailureCode.alreadyCheckedOut =>
      l10n.visitorAlreadyCheckedOut,
    VisitorRepositoryFailureCode.unauthorized =>
      l10n.securitySessionUnauthorized,
    VisitorRepositoryFailureCode.forbidden => l10n.actionForbidden,
    VisitorRepositoryFailureCode.network => l10n.networkRetry,
    VisitorRepositoryFailureCode.validation =>
      error.message ?? l10n.securityApiRejectedRequest,
    VisitorRepositoryFailureCode.invalidQr => l10n.qrCredentialInvalid,
    VisitorRepositoryFailureCode.invalidState => l10n.visitorInvalidState,
    VisitorRepositoryFailureCode.unknown => l10n.visitorActionUnavailable,
  };
}

String visitorVerificationFailureMessage(
  BuildContext context,
  VisitorRepositoryException error,
) {
  final l10n = context.l10n;
  return switch (error.code) {
    VisitorRepositoryFailureCode.invalidQr => l10n.qrInvalid,
    VisitorRepositoryFailureCode.visitNotFound => l10n.visitorVisitNotFound,
    VisitorRepositoryFailureCode.expiredVisit => l10n.qrExpiredVisit,
    VisitorRepositoryFailureCode.notValidToday =>
      l10n.visitorNotScheduledToday,
    VisitorRepositoryFailureCode.pendingApproval =>
      l10n.visitStillPendingApproval,
    VisitorRepositoryFailureCode.rejectedVisit =>
      l10n.visitorRejectedVerification,
    VisitorRepositoryFailureCode.blacklisted => l10n.visitorBlacklisted,
    VisitorRepositoryFailureCode.cancelledVisit =>
      l10n.visitorCancelledVerification,
    VisitorRepositoryFailureCode.unauthorized =>
      l10n.securitySessionUnauthorized,
    VisitorRepositoryFailureCode.forbidden => l10n.verificationForbidden,
    VisitorRepositoryFailureCode.network => l10n.networkRetry,
    VisitorRepositoryFailureCode.validation =>
      error.message ?? l10n.securityApiRejectedVerification,
    VisitorRepositoryFailureCode.alreadyCheckedIn =>
      l10n.visitorAlreadyCheckedIn,
    VisitorRepositoryFailureCode.alreadyCheckedOut =>
      l10n.visitorAlreadyCheckedOut,
    VisitorRepositoryFailureCode.invalidState => l10n.visitorCannotVerifyState,
    VisitorRepositoryFailureCode.unknown => l10n.verificationFailed,
  };
}

String visitorHistoryFailureMessage(
  BuildContext context,
  VisitorRepositoryException error,
) {
  final l10n = context.l10n;
  return switch (error.code) {
    VisitorRepositoryFailureCode.unauthorized =>
      l10n.securitySessionUnauthorized,
    VisitorRepositoryFailureCode.forbidden => l10n.historyForbidden,
    VisitorRepositoryFailureCode.network => l10n.historyNetworkRetry,
    _ => l10n.historyLoadRetry,
  };
}
