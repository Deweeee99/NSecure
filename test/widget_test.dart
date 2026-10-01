import 'package:nsecure/app.dart';
import 'package:nsecure/core/bootstrap/app_dependencies.dart';
import 'package:nsecure/features/emergency/data/mock/mock_emergency_alert_repository.dart';
import 'package:nsecure/features/incident/data/mock/mock_incident_repository.dart';
import 'package:nsecure/features/patrol/data/mock/mock_patrol_repository.dart';
import 'package:nsecure/features/package/data/mock/mock_security_package_repository.dart';
import 'package:nsecure/features/visitor/data/mock/mock_visitor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _dragListUntilMounted(
  WidgetTester tester,
  Finder target, {
  int maxDrags = 8,
}) async {
  final listView = find.byType(ListView);
  for (var attempt = 0; attempt < maxDrags; attempt++) {
    if (target.evaluate().isNotEmpty) {
      return;
    }
    expect(listView, findsOneWidget);
    await tester.drag(listView, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
}

void main() {
  testWidgets('Security Platform Home renders core modules', (tester) async {
    await tester.pumpWidget(const NSecureApp());

    expect(find.text('NSecure'), findsOneWidget);
    expect(find.text('Security Team'), findsOneWidget);
    expect(find.text("Today's Overview"), findsNothing);
    expect(find.text('Active Tasks'), findsOneWidget);
    expect(find.text('Continue Patrol'), findsOneWidget);
    expect(find.text('Verify Visitor'), findsOneWidget);
    expect(find.text('Review Incident'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);

    expect(find.text('Visitor Verification'), findsOneWidget);
    expect(find.text('Patrol Management'), findsOneWidget);
    expect(find.text('Incident Reporting'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('Package Receiving'), findsOneWidget);
    expect(find.text('Access Control'), findsNothing);
    expect(find.text('Vehicle Management'), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('WAITING'), findsOneWidget);
    expect(find.text('PRIORITY'), findsOneWidget);
    expect(find.text('COMING SOON'), findsNothing);
  });

  testWidgets('Active task preview routes into existing operational flow', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.tap(find.byKey(const Key('activeTask_TASK-PATROL-001')));
    await tester.pumpAndSettle();

    expect(find.text('Patrol Dashboard'), findsOneWidget);
    expect(find.text('Assigned Patrols'), findsOneWidget);
  });

  testWidgets('Verify tab opens active QR verification path', (tester) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Enter Code Manually'), findsOneWidget);
    expect(find.text('Manual Verify'), findsOneWidget);
    expect(find.byKey(const Key('demoQrScanner')), findsOneWidget);
  });

  testWidgets('manual verification searches by Visit Code', (tester) async {
    await tester.pumpWidget(const NSecureApp());

    await _openManualSearch(tester);

    await tester.enterText(
      find.byKey(const Key('manualVisitorQuery')),
      'VST-240515-0012',
    );
    await tester.tap(find.byKey(const Key('manualVisitorSearchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Search Results'), findsOneWidget);
    expect(find.text('John Michael Doe'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
  });

  testWidgets('Manual Verify starts without seeded recent searches', (tester) async {
    await tester.pumpWidget(const NSecureApp());

    await _openManualSearch(tester);

    expect(find.text('Recent Searches'), findsNothing);
    expect(find.text('Visit Code example: VST-240515-0012'), findsNothing);
    expect(find.text('Visit ID example: 245'), findsNothing);
    expect(find.text('VST-240515-0011'), findsNothing);
    expect(find.text('410'), findsNothing);
    expect(find.text('VST-240514-0099'), findsNothing);
    expect(find.text('487'), findsNothing);
  });

  testWidgets('successful manual search becomes real session history', (tester) async {
    await tester.pumpWidget(const NSecureApp());

    await _openManualSearch(tester);
    await tester.enterText(
      find.byKey(const Key('manualVisitorQuery')),
      'VST-240515-0012',
    );
    await tester.tap(find.byKey(const Key('manualVisitorSearchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Search Results'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('VST-240515-0012'), findsOneWidget);
  });

  testWidgets('Android system Back returns through app screens', (tester) async {
    await tester.pumpWidget(const NSecureApp());

    final packageReceiving = find.text('Package Receiving');
    await tester.ensureVisible(packageReceiving);
    await tester.pumpAndSettle();
    await tester.tap(packageReceiving);
    await tester.pumpAndSettle();
    expect(find.text('Receive Package'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enter Code Manually'));
    await tester.tap(find.text('Enter Code Manually'));
    await tester.pumpAndSettle();
    expect(find.text('Manual Verify'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Scan QR'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('manual verification shows explicit not-found state', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await _openManualSearch(tester);

    await tester.enterText(
      find.byKey(const Key('manualVisitorQuery')),
      'VIS-NOT-FOUND',
    );
    await tester.tap(find.byKey(const Key('manualVisitorSearchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Visitor Not Found'), findsOneWidget);
    expect(find.textContaining('VIS-NOT-FOUND'), findsOneWidget);
  });

  testWidgets('demo QR resolves deterministic visitor without backend', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demoQrScanner')));
    await tester.pumpAndSettle();

    expect(find.text('Search Results'), findsOneWidget);
    expect(find.text('QR Verification'), findsOneWidget);
    expect(find.text('John Michael Doe'), findsOneWidget);
  });

  testWidgets('Approved visitor opens detail and completes Check-In', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await _searchApprovedVisitor(tester);
    await tester.tap(find.text('John Michael Doe'));
    await tester.pumpAndSettle();

    expect(find.text('Visitor Detail'), findsOneWidget);
    expect(find.text('245'), findsOneWidget);
    expect(find.byKey(const Key('checkInVisitorButton')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('checkInVisitorButton')));
    await tester.tap(find.byKey(const Key('checkInVisitorButton')));
    await tester.pumpAndSettle();

    expect(find.text('Check-In Successful!'), findsOneWidget);
    expect(find.text('10:24 AM'), findsOneWidget);
    expect(find.text('Security Team'), findsWidgets);
    expect(find.byKey(const Key('continueVerifyingButton')), findsOneWidget);
  });

  testWidgets('Checked-In visitor detail exposes Check-Out action', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await _openManualSearch(tester);
    await tester.enterText(
      find.byKey(const Key('manualVisitorQuery')),
      '301',
    );
    await tester.tap(find.byKey(const Key('manualVisitorSearchButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sarah Williams'));
    await tester.pumpAndSettle();

    expect(find.text('Visitor Detail'), findsOneWidget);
    expect(find.byKey(const Key('checkOutVisitorButton')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('checkOutVisitorButton')));
    await tester.tap(find.byKey(const Key('checkOutVisitorButton')));
    await tester.pumpAndSettle();

    final confirmationFinder = find.text('Check-Out Successful!');
    expect(confirmationFinder, findsOneWidget);

    final confirmationContext = tester.element(confirmationFinder);
    final expectedCheckOutTime = MaterialLocalizations.of(
      confirmationContext,
    ).formatTimeOfDay(
      const TimeOfDay(hour: 14, minute: 35),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
        confirmationContext,
      ),
    );
    expect(find.text(expectedCheckOutTime), findsOneWidget);
  });

  testWidgets('Expired visitor remains read-only in Visitor Detail', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await _openManualSearch(tester);
    await tester.enterText(
      find.byKey(const Key('manualVisitorQuery')),
      'VST-240514-0099',
    );
    await tester.tap(find.byKey(const Key('manualVisitorSearchButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Michael Chen'));
    await tester.pumpAndSettle();

    expect(find.text('Visitor Detail'), findsOneWidget);
    expect(find.text('EXPIRED'), findsOneWidget);
    expect(find.textContaining('Check-In is not available'), findsOneWidget);
    expect(find.byKey(const Key('checkInVisitorButton')), findsNothing);
    expect(find.byKey(const Key('checkOutVisitorButton')), findsNothing);
  });

  testWidgets('History tab renders operational filters and activity', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Verification History'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Checked In'), findsWidgets);
    expect(find.text('Checked Out'), findsWidgets);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Expired'), findsWidgets);
    expect(find.text('Sarah Williams'), findsOneWidget);
    expect(find.text('Priya Patel'), findsOneWidget);
  });

  testWidgets('new Check-In becomes visible in Verification History', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await _searchApprovedVisitor(tester);
    await tester.tap(find.text('John Michael Doe'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('checkInVisitorButton')));
    await tester.tap(find.byKey(const Key('checkInVisitorButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirmationDoneButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Verification History'), findsOneWidget);
    expect(find.text('John Michael Doe'), findsOneWidget);
    expect(find.text('CHECKED IN'), findsWidgets);
  });

  testWidgets('Patrol Management opens operational assigned patrol flow', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Patrol Management'));
    await tester.tap(find.text('Patrol Management'));
    await tester.pumpAndSettle();

    expect(find.text('Patrol Dashboard'), findsOneWidget);
    expect(find.text('Assigned Patrols'), findsOneWidget);
    expect(find.text('Active Patrol'), findsOneWidget);
    expect(find.text('Tower A — Night Patrol'), findsWidgets);
    expect(find.textContaining('Design concept only'), findsNothing);

    await tester.tap(find.byKey(const Key('patrolNextSessionCard')));
    await tester.pumpAndSettle();

    expect(find.text('Patrol Route'), findsOneWidget);
    expect(find.byKey(const Key('completePatrolButton')), findsOneWidget);

    // The detail body is intentionally scrollable beneath a persistent action
    // footer. In the default widget-test viewport the checkpoint section can be
    // lazily outside the mounted ListView children, so scroll until it becomes
    // visible before asserting its contents.
    await tester.scrollUntilVisible(
      find.text('Route Checkpoints'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Route Checkpoints'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Main Lobby'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Main Lobby'), findsOneWidget);
  });

  testWidgets('Patrol History renders terminal assigned patrols', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Patrol Management'));
    await tester.tap(find.text('Patrol Management'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('patrolHistoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Patrol History'), findsOneWidget);
    expect(find.text('Completed Patrol Activity'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.text('Tower A — Night Patrol'), findsOneWidget);
  });

  testWidgets('Patrol checkpoint can report an Incident and return with Issue state', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Patrol Management'));
    await tester.tap(find.text('Patrol Management'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tower A — Night Patrol').first);
    await tester.pumpAndSettle();

    final reportIssueButton = find.byKey(
      const Key('reportCheckpointIssueButton-102'),
    );
    await tester.scrollUntilVisible(
      reportIssueButton,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(reportIssueButton);
    await tester.pumpAndSettle();

    expect(find.text('Create Incident'), findsOneWidget);
    expect(find.textContaining('Lift Lobby — Floor 1'), findsOneWidget);
    expect(find.textContaining('PAT-20260812-000041'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('incidentTitleField')),
      'Lift lobby obstruction',
    );
    await tester.enterText(
      find.byKey(const Key('incidentCategoryField')),
      'Safety',
    );
    final descriptionField = find.byKey(
      const Key('incidentDescriptionField'),
    );
    final createIncidentList = find.byType(ListView);
    expect(createIncidentList, findsOneWidget);
    for (var attempt = 0;
        attempt < 4 && descriptionField.evaluate().isEmpty;
        attempt++) {
      await tester.drag(
        createIncidentList,
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();
    }
    expect(descriptionField, findsOneWidget);
    await tester.enterText(
      descriptionField,
      'Obstruction found during patrol.',
    );
    await tester.tap(find.byKey(const Key('submitIncidentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Incident Dashboard'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Patrol Dashboard'), findsOneWidget);
    await tester.tap(find.text('Tower A — Night Patrol').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lift Lobby — Floor 1'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Issue'), findsOneWidget);
    expect(
      find.byKey(const Key('reportCheckpointIssueButton-102')),
      findsNothing,
    );
  });

  testWidgets('Incident Reporting opens operational dashboard and detail', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Incident Reporting'));
    await tester.tap(find.text('Incident Reporting'));
    await tester.pumpAndSettle();

    expect(find.text('Incident Dashboard'), findsOneWidget);

    // Dashboard content is intentionally scrollable. In the widget-test
    // viewport, lower sections can be outside ListView's lazily mounted
    // children, so scroll to each operational target before asserting it.
    await tester.scrollUntilVisible(
      find.byKey(const Key('reportIncidentButton')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reportIncidentButton')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Active Incidents'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Active Incidents'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Emergency exit obstructed'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Emergency exit obstructed'), findsOneWidget);
    expect(find.textContaining('Future Capability'), findsNothing);

    await tester.tap(find.text('Emergency exit obstructed'));
    await tester.pumpAndSettle();

    expect(find.text('Incident Detail'), findsOneWidget);
    expect(find.text('INC-20260812-000091'), findsOneWidget);
    expect(find.byKey(const Key('acknowledgeIncidentButton')), findsOneWidget);
    expect(find.byKey(const Key('startIncidentButton')), findsOneWidget);
  });

  testWidgets('Incident Reporting creates a standalone incident', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Incident Reporting'));
    await tester.tap(find.text('Incident Reporting'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('reportIncidentButton')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reportIncidentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Create Incident'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('incidentTitleField')),
      'Loading bay obstruction',
    );
    await tester.enterText(
      find.byKey(const Key('incidentCategoryField')),
      'Safety',
    );
    await tester.enterText(
      find.byKey(const Key('incidentDescriptionField')),
      'Boxes obstruct the loading bay exit.',
    );
    await tester.tap(find.byKey(const Key('submitIncidentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Incident Dashboard'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Loading bay obstruction'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Loading bay obstruction'), findsOneWidget);
  });

  testWidgets('Incident History renders terminal incidents', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Incident Reporting'));
    await tester.tap(find.text('Incident Reporting'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('incidentHistoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Incident History'), findsOneWidget);
    expect(find.text('Resolved Incident Activity'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Water leak in service corridor'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Water leak in service corridor'), findsOneWidget);
  });
  
  testWidgets('Emergency SOS opens operational center', (tester) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Emergency SOS'));
    await tester.tap(find.text('Emergency SOS'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency SOS'), findsWidgets);
    expect(find.text('Unresolved Alerts'), findsOneWidget);
    expect(find.text('No unresolved SOS alerts'), findsOneWidget);
    expect(find.textContaining('future concept'), findsNothing);
  });

  testWidgets('persistent SOS modal remains until Security takes alert', (
    tester,
  ) async {
    final patrolRepository = MockPatrolRepository();
    final dependencies = AppDependencies(
      visitorRepository: MockVisitorRepository(),
      patrolRepository: patrolRepository,
      incidentRepository: MockIncidentRepository(
        onPatrolIncidentCreated:
            patrolRepository.markCheckpointIssueFromIncident,
      ),
      emergencyAlertRepository:
          MockEmergencyAlertRepository.withOpenAlert(),
      securityPackageRepository: MockSecurityPackageRepository(),
    );

    await tester.pumpWidget(NSecureApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emergencyPersistentModal')), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('SOS-20260814-000012'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emergencyAcknowledgeButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emergencyPersistentModal')), findsNothing);
    await tester.ensureVisible(find.text('Emergency SOS'));
    await tester.tap(find.text('Emergency SOS'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Acknowledged'), findsOneWidget);
  });

  testWidgets('Package Receiving registers and collects through Package Center flow', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());

    await tester.ensureVisible(find.text('Package Receiving'));
    await tester.tap(find.text('Package Receiving'));
    await tester.pumpAndSettle();

    expect(find.text('Packages'), findsOneWidget);
    expect(find.text('PKG-260814-AB12CD34'), findsOneWidget);
    expect(find.text('Ready for Pickup'), findsWidgets);

    await tester.tap(find.byKey(const Key('openReceivePackageButton')));
    await tester.pumpAndSettle();
    expect(find.text('Receive Package'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('packageResidentSearchField')),
      'Budi',
    );
    await tester.tap(find.byKey(const Key('packageResidentSearchButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('packageResidentResult-101')), findsOneWidget);

    await tester.tap(find.byKey(const Key('packageResidentResult-101')));
    await tester.pumpAndSettle();

    await _dragListUntilMounted(
      tester,
      find.byKey(const Key('packageCourierField')),
    );
    await tester.enterText(
      find.byKey(const Key('packageCourierField')),
      'J&T',
    );
    await tester.tap(find.byKey(const Key('packageReceiveButton')));
    await tester.pumpAndSettle();

    expect(find.text('PKG-260814-MOCK56'), findsOneWidget);
    expect(find.text('Ready for Pickup'), findsOneWidget);
    expect(find.byKey(const Key('packageCollectButton')), findsOneWidget);

    await _dragListUntilMounted(
      tester,
      find.byKey(const Key('packageCollectionRecipientTypeControl')),
    );
    expect(
      find.byKey(const Key('packageCollectionRecipientNameField')),
      findsNothing,
    );

    await tester.tap(find.text('Others'));
    await tester.pumpAndSettle();

    await _dragListUntilMounted(
      tester,
      find.byKey(const Key('packageCollectionRecipientNameField')),
    );
    await tester.enterText(
      find.byKey(const Key('packageCollectionRecipientNameField')),
      'Mbak Rina - ART',
    );
    await _dragListUntilMounted(
      tester,
      find.byKey(const Key('packageCollectionNotesField')),
    );
    await tester.enterText(
      find.byKey(const Key('packageCollectionNotesField')),
      'Picked up at lobby.',
    );
    await tester.tap(find.byKey(const Key('packageCollectButton')));
    await tester.pumpAndSettle();

    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Picked Up By Type'), findsOneWidget);
    expect(find.text('Others'), findsOneWidget);
    expect(find.text('Picked Up By'), findsOneWidget);
    expect(find.text('Mbak Rina - ART'), findsOneWidget);
    expect(find.text('Processed By'), findsOneWidget);
    expect(find.byKey(const Key('packageCollectButton')), findsNothing);
  });

  testWidgets('More tab exposes only active production modules', (
    tester,
  ) async {
    await tester.pumpWidget(const NSecureApp());
  
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
  
    expect(find.text('Security Platform'), findsOneWidget);
    expect(find.text('Platform Modules'), findsOneWidget);

    // The catalog is a lazy ListView. The fourth active module (Emergency
    // SOS) can sit just below the initial test viewport, so asserting four
    // ACTIVE chips before scrolling is viewport-dependent. Scroll to the
    // module itself and verify that the active module is rendered.
    await tester.scrollUntilVisible(
      find.text('Emergency SOS'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Emergency SOS'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Package Receiving'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Package Receiving'), findsOneWidget);
    expect(find.text('ACTIVE'), findsNothing);

    expect(find.text('Access Control'), findsNothing);
    expect(find.text('Vehicle Management'), findsNothing);
    expect(find.text('COMING SOON'), findsNothing);
  });
}

Future<void> _openManualSearch(WidgetTester tester) async {
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Enter Code Manually'));
  await tester.tap(find.text('Enter Code Manually'));
  await tester.pumpAndSettle();

  expect(find.text('Manual Verify'), findsOneWidget);
  expect(find.byKey(const Key('manualVisitorQuery')), findsOneWidget);
}

Future<void> _searchApprovedVisitor(WidgetTester tester) async {
  await _openManualSearch(tester);
  await tester.enterText(
    find.byKey(const Key('manualVisitorQuery')),
    'VST-240515-0012',
  );
  await tester.tap(find.byKey(const Key('manualVisitorSearchButton')));
  await tester.pumpAndSettle();
}
