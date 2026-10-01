import 'package:aparthub_security/features/package/data/mock/mock_security_package_repository.dart';
import 'package:aparthub_security/features/package/domain/models/security_package_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockSecurityPackageRepository', () {
    test('resident lookup searches name and unit', () async {
      final repository = MockSecurityPackageRepository();

      final byName = await repository.searchResidents(query: 'Budi');
      final byUnit = await repository.searchResidents(query: 'B-1203');

      expect(byName.single.resident.id, 101);
      expect(byUnit.single.resident.id, 102);
    });

    test('receive creates canonical Ready for Pickup package', () async {
      final repository = MockSecurityPackageRepository();

      final record = await repository.receivePackage(
        const SecurityPackageReceiveInput(
          residentId: 101,
          courierName: 'J&T',
          trackingNumber: 'JT-001',
        ),
      );

      expect(record.packageNo, 'PKG-260814-MOCK56');
      expect(record.status, SecurityPackageStatus.readyForPickup);
      expect(record.resident.name, 'Budi Santoso');
      expect(record.unit.code, 'A-101');
      expect(record.receivedBy?.name, 'Security Team');
    });

    test('collect is durable and idempotent', () async {
      final repository = MockSecurityPackageRepository();

      final first = await repository.collectPackage(
        55,
        recipientType: SecurityPackageCollectionRecipientType.resident,
        collectionNotes: 'Collected at lobby.',
      );
      final second = await repository.collectPackage(
        55,
        recipientType: SecurityPackageCollectionRecipientType.others,
        collectionRecipientName: 'Ignored because already collected',
      );

      expect(first.status, SecurityPackageStatus.collected);
      expect(first.collectionNotes, 'Collected at lobby.');
      expect(first.collectedBy?.type,
          SecurityPackageCollectionRecipientType.resident);
      expect(first.collectedBy?.name, 'Budi Santoso');
      expect(first.processedBy?.name, 'Security Team');
      expect(second.status, SecurityPackageStatus.collected);
      expect(second.collectionNotes, 'Collected at lobby.');
      expect(second.collectedBy?.name, 'Budi Santoso');
      expect((await repository.packages(status: SecurityPackageStatus.readyForPickup)), isEmpty);
    });

    test('collect supports Others recipient with free-text name', () async {
      final repository = MockSecurityPackageRepository();

      final record = await repository.collectPackage(
        55,
        recipientType: SecurityPackageCollectionRecipientType.others,
        collectionRecipientName: 'Mbak Rina - ART',
      );

      expect(record.status, SecurityPackageStatus.collected);
      expect(record.collectedBy?.type,
          SecurityPackageCollectionRecipientType.others);
      expect(record.collectedBy?.name, 'Mbak Rina - ART');
      expect(record.collectedBy?.residentId, isNull);
      expect(record.processedBy?.name, 'Security Team');
    });

    test('enriches an already-Collected legacy row without changing audit time',
        () async {
      final collectedAt = DateTime(2026, 8, 14, 12, 5);
      final repository = MockSecurityPackageRepository(
        initialPackages: <SecurityPackageRecord>[
          SecurityPackageRecord(
            packageId: 77,
            packageNo: 'PKG-LEGACY-77',
            status: SecurityPackageStatus.collected,
            courierName: 'JNE',
            property: const SecurityPackagePropertyRef(
              id: 1,
              code: 'SITE-A',
              name: 'Aparthub Residence',
            ),
            resident: const SecurityPackageResidentRef(
              id: 101,
              name: 'Budi Santoso',
            ),
            unit: const SecurityPackageUnitRef(
              id: 44,
              code: 'A-101',
            ),
            receivedAt: DateTime(2026, 8, 14, 11, 0),
            collectedAt: collectedAt,
            processedBy: const SecurityPackageActorRef(
              id: 9,
              name: 'Original Security',
            ),
          ),
        ],
      );

      final record = await repository.collectPackage(
        77,
        recipientType: SecurityPackageCollectionRecipientType.others,
        collectionRecipientName: 'Mbak Rina - ART',
      );

      expect(record.status, SecurityPackageStatus.collected);
      expect(record.collectedBy?.name, 'Mbak Rina - ART');
      expect(record.processedBy?.name, 'Original Security');
      expect(record.collectedAt, collectedAt);
    });
  });
}
