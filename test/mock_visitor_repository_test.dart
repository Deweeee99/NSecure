import 'package:aparthub_security/features/visitor/data/mock/mock_visitor_repository.dart';
import 'package:aparthub_security/features/visitor/domain/models/visitor_visit.dart';
import 'package:aparthub_security/features/visitor/domain/repositories/visitor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockVisitorRepository', () {
    late MockVisitorRepository repository;

    setUp(() {
      repository = MockVisitorRepository();
    });

    test('manual search supports visit code', () async {
      final results = await repository.search('VST-240515-0012');

      expect(results, hasLength(1));
      expect(results.single.visitorName, 'John Michael Doe');
      expect(results.single.status, VisitorStatus.approved);
    });

    test('manual search supports visitor id', () async {
      final results = await repository.search('301');

      expect(results, hasLength(1));
      expect(results.single.visitorName, 'Sarah Williams');
    });

    test('qr lookup is deterministic', () async {
      final visit = await repository.verifyQrPayload('SEC-QR-DEMO-000399');

      expect(visit.status, VisitorStatus.expired);
    });


    test('qr payload matching is exact and QR Check-In carries the credential', () async {
      await expectLater(
        repository.verifyQrPayload('sec-qr-demo-000245'),
        throwsA(isA<VisitorRepositoryException>()),
      );

      final updated = await repository.checkIn(
        '245',
        method: VisitorVerificationMethod.qr,
        qrPayload: 'SEC-QR-DEMO-000245',
      );
      expect(updated.status, VisitorStatus.checkedIn);
    });

    test('invalid qr exposes stable invalidQr failure code', () async {
      await expectLater(
        repository.verifyQrPayload('QR-NOT-FOUND'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.invalidQr,
          ),
        ),
      );
    });

    test('broad visit-code search exposes multiple status examples', () async {
      final results = await repository.search('VST-');

      expect(results, hasLength(5));
      expect(results.map((visit) => visit.status), contains(VisitorStatus.pending));
      expect(
        results.map((visit) => visit.status),
        contains(VisitorStatus.checkedOut),
      );
    });

    test('Approved visit is eligible only for check-in', () async {
      final visit = await repository.findByVisitId('245');

      expect(visit, isNotNull);
      expect(visit!.canCheckIn, isTrue);
      expect(visit.canCheckOut, isFalse);
    });

    test('check-in mutates Approved visit to Checked-In deterministically', () async {
      final updated = await repository.checkIn('245');

      expect(updated.status, VisitorStatus.checkedIn);
      expect(updated.checkedInAt, DateTime(2024, 5, 15, 10, 24));
      expect(updated.checkedInBy, 'Security Team');
      expect(updated.canCheckIn, isFalse);
      expect(updated.canCheckOut, isTrue);

      final history = await repository.history();
      expect(
        history.any((visit) => visit.visitId == '245'),
        isTrue,
      );
    });

    test('check-out mutates Checked-In visit to terminal Checked-Out', () async {
      final updated = await repository.checkOut('301');

      expect(updated.status, VisitorStatus.checkedOut);
      expect(updated.checkedOutAt, DateTime(2024, 5, 15, 14, 35));
      expect(updated.checkedOutBy, 'Security Team');
      expect(updated.canCheckIn, isFalse);
      expect(updated.canCheckOut, isFalse);
    });

    test('invalid state transition is rejected', () async {
      await expectLater(
        repository.checkIn('399'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.expiredVisit,
          ),
        ),
      );

      await expectLater(
        repository.checkOut('487'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.alreadyCheckedOut,
          ),
        ),
      );
    });

    test('repository owns the authoritative actor instead of the UI', () async {
      final customActorRepository = MockVisitorRepository(
        actorName: 'Front Desk Officer A',
      );

      final updated = await customActorRepository.checkIn('245');

      expect(updated.checkedInBy, 'Front Desk Officer A');
    });

    test('missing visit exposes stable repository failure code', () async {
      await expectLater(
        repository.checkIn('VISIT-NOT-FOUND'),
        throwsA(
          isA<VisitorRepositoryException>().having(
            (error) => error.code,
            'code',
            VisitorRepositoryFailureCode.visitNotFound,
          ),
        ),
      );
    });

    test('history exposes the operational filter states only', () async {
      final history = await repository.history();
      final statuses = history.map((visit) => visit.status).toSet();

      expect(statuses, contains(VisitorStatus.checkedIn));
      expect(statuses, contains(VisitorStatus.checkedOut));
      expect(statuses, contains(VisitorStatus.pending));
      expect(statuses, contains(VisitorStatus.expired));
      expect(statuses, isNot(contains(VisitorStatus.approved)));
    });
  });
}
