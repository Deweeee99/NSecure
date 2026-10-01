import 'package:aparthub_security/core/network/security_api_client.dart';
import 'package:aparthub_security/features/visitor/domain/models/visitor_visit.dart';
import 'package:aparthub_security/features/visitor/domain/repositories/visitor_repository.dart';
import 'package:aparthub_security/features/visitor/presentation/history/verification_history_flow.dart';
import 'package:aparthub_security/features/visitor/presentation/verification/visitor_verification_flow.dart';
import 'package:aparthub_security/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Security API base URL rejects non-absolute values', () {
    expect(
      () => IoSecurityApiClient(baseUrl: 'api/security'),
      throwsArgumentError,
    );
  });

  testWidgets('History renders retry state after a network failure', (
    tester,
  ) async {
    final repository = _ReadinessRepository(historyFailsOnce: true);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: VerificationHistoryFlow(
            repository: repository,
            refreshRevision: 0,
            onVisitUpdated: () {},
            onContinueVerifying: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('History Unavailable'), findsOneWidget);
    expect(find.byKey(const Key('historyRetryButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('historyRetryButton')));
    await tester.pumpAndSettle();

    expect(find.text('History Unavailable'), findsNothing);
    expect(find.text('No Records • All'), findsOneWidget);
    expect(repository.historyCalls, 2);
  });

  testWidgets('unauthorized Visitor request triggers Security session exit', (
    tester,
  ) async {
    final repository = _ReadinessRepository(searchUnauthorized: true);
    var sessionExpired = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: VisitorVerificationFlow(
            repository: repository,
            enableDeviceQrScanner: false,
            onBackHome: () {},
            onVisitUpdated: () {},
            onSessionExpired: () async {
              sessionExpired = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Enter Code Manually'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manualVisitorQuery')),
      'VST-TEST',
    );
    await tester.tap(find.byKey(const Key('manualVisitorSearchButton')));
    await tester.pumpAndSettle();

    expect(sessionExpired, isTrue);
  });
}

class _ReadinessRepository implements VisitorRepository {
  _ReadinessRepository({
    this.historyFailsOnce = false,
    this.searchUnauthorized = false,
  });

  final bool historyFailsOnce;
  final bool searchUnauthorized;
  int historyCalls = 0;

  @override
  Future<List<VisitorVisit>> search(String query) async {
    if (searchUnauthorized) {
      throw const VisitorRepositoryException(
        VisitorRepositoryFailureCode.unauthorized,
      );
    }
    return const <VisitorVisit>[];
  }

  @override
  Future<List<VisitorVisit>> history() async {
    historyCalls += 1;
    if (historyFailsOnce && historyCalls == 1) {
      throw const VisitorRepositoryException(
        VisitorRepositoryFailureCode.network,
      );
    }
    return const <VisitorVisit>[];
  }

  @override
  Future<VisitorVisit> verifyQrPayload(String qrPayload) {
    throw UnimplementedError();
  }

  @override
  Future<VisitorVisit?> findByVisitId(String visitId) async => null;

  @override
  Future<VisitorVisit> checkIn(
    String visitId, {
    VisitorVerificationMethod method = VisitorVerificationMethod.manual,
    String? qrPayload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VisitorVisit> checkOut(String visitId) {
    throw UnimplementedError();
  }
}
