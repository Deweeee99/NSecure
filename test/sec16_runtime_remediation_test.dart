import 'package:aparthub_security/features/security/domain/models/module_preview.dart';
import 'package:aparthub_security/features/security/domain/models/security_module_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production module registry exposes only active software modules', () {
    final modules = SecurityModuleRegistry.activeModules;

    expect(
      modules.map((module) => module.key),
      orderedEquals(<String>[
        'visitor_verification',
        'patrol_management',
        'incident_reporting',
        'emergency_response',
        'package_receiving',
      ]),
    );
    expect(
      modules.every(
        (module) =>
            module.isActiveModule && module.status == ModulePreviewStatus.active,
      ),
      isTrue,
    );
  });
}
