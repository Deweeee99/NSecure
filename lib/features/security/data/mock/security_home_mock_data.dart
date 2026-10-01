import '../../domain/models/security_user.dart';

abstract final class SecurityHomeMockData {
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
