import 'module_preview.dart';

abstract final class SecurityModuleRegistry {
  static const activeModules = <ModulePreview>[
    ModulePreview(
      key: 'visitor_verification',
      title: 'Visitor Verification',
      subtitle: 'QR scan and manual visitor verification',
      status: ModulePreviewStatus.active,
      isActiveModule: true,
    ),
    ModulePreview(
      key: 'patrol_management',
      title: 'Patrol Management',
      subtitle: 'Assigned patrol routes and checkpoint execution',
      status: ModulePreviewStatus.active,
      isActiveModule: true,
    ),
    ModulePreview(
      key: 'incident_reporting',
      title: 'Incident Reporting',
      subtitle: 'Operational incident reporting and handling',
      status: ModulePreviewStatus.active,
      isActiveModule: true,
    ),
    ModulePreview(
      key: 'emergency_response',
      title: 'Emergency SOS',
      subtitle: 'Durable Resident SOS alerts and Security response',
      status: ModulePreviewStatus.active,
      isActiveModule: true,
    ),
    ModulePreview(
      key: 'package_receiving',
      title: 'Package Receiving',
      subtitle: 'Receive and collect packages through Package Center',
      status: ModulePreviewStatus.active,
      isActiveModule: true,
    ),
  ];
}
