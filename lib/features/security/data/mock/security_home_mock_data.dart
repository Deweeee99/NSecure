import '../../domain/models/security_task_preview.dart';
import '../../domain/models/security_user.dart';

abstract final class SecurityHomeMockData {
  static const activeTasks = <SecurityTaskPreview>[
    SecurityTaskPreview(
      id: 'TASK-PATROL-001',
      type: SecurityTaskPreviewType.patrol,
      status: SecurityTaskPreviewStatus.inProgress,
    ),
    SecurityTaskPreview(
      id: 'TASK-VISITOR-001',
      type: SecurityTaskPreviewType.visitor,
      status: SecurityTaskPreviewStatus.waiting,
    ),
    SecurityTaskPreview(
      id: 'TASK-INCIDENT-001',
      type: SecurityTaskPreviewType.incident,
      status: SecurityTaskPreviewStatus.attention,
    ),
  ];

  static const user = SecurityUser(
    id: 'SEC-001',
    name: 'Security Team',
    username: 'security.frontdesk',
    postName: 'Front Desk • Main Lobby',
    propertyName: 'NSecure Demo Site',
    active: true,
    defaultPropertyId: 1,
    properties: <SecurityProperty>[
      SecurityProperty(
        id: 1,
        code: 'SITE-A',
        name: 'NSecure Demo Site',
        isDefault: true,
      ),
    ],
  );
}
