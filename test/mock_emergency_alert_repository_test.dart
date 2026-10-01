import 'package:nsecure/features/emergency/data/mock/mock_emergency_alert_repository.dart';
import 'package:nsecure/features/emergency/domain/models/emergency_alert_models.dart';
import 'package:nsecure/features/emergency/domain/repositories/emergency_alert_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockEmergencyAlertRepository', () {
    test('Open alert remains in modal queue until acknowledge', () async {
      final repository = MockEmergencyAlertRepository.withOpenAlert();

      expect(await repository.activeAlerts(), hasLength(1));

      final acknowledged = await repository.acknowledge(12);

      expect(acknowledged.status, EmergencyAlertStatus.acknowledged);
      expect(acknowledged.takenByMe, isTrue);
      expect(await repository.activeAlerts(), isEmpty);
      expect(await repository.unresolvedAlerts(), hasLength(1));
    });

    test('owner can resolve acknowledged alert into history', () async {
      final repository = MockEmergencyAlertRepository.withOpenAlert();
      await repository.acknowledge(12);

      final resolved = await repository.resolve(
        12,
        notes: 'Resident aman.',
      );

      expect(resolved.status, EmergencyAlertStatus.resolved);
      expect(resolved.resolutionNotes, 'Resident aman.');
      expect(await repository.unresolvedAlerts(), isEmpty);
      expect(await repository.history(), hasLength(1));
    });

    test('Open alert cannot resolve before acknowledge', () async {
      final repository = MockEmergencyAlertRepository.withOpenAlert();

      await expectLater(
        repository.resolve(12),
        throwsA(
          isA<EmergencyRepositoryException>().having(
            (error) => error.code,
            'code',
            EmergencyRepositoryFailureCode.notAcknowledged,
          ),
        ),
      );
    });
  });
}
