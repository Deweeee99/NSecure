import 'package:aparthub_security/features/visitor/presentation/verification/visitor_qr_capture_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QR capture suppresses duplicates only while request is in flight', () {
    final coordinator = VisitorQrCaptureCoordinator();

    expect(coordinator.tryBegin('ACCESS-CODE-001'), isTrue);
    expect(coordinator.isProcessing, isTrue);

    expect(coordinator.tryBegin('ACCESS-CODE-001'), isFalse);
    expect(coordinator.tryBegin('ACCESS-CODE-002'), isFalse);

    coordinator.complete();

    expect(coordinator.isProcessing, isFalse);
    expect(coordinator.tryBegin('ACCESS-CODE-001'), isTrue);
  });

  test('QR capture rejects an empty raw payload', () {
    final coordinator = VisitorQrCaptureCoordinator();

    expect(coordinator.tryBegin(''), isFalse);
    expect(coordinator.isProcessing, isFalse);
  });
}
