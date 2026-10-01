import '../../domain/models/security_user.dart';

abstract final class SecurityHomeMockData {
  static const user = SecurityUser(
    id: 'SEC-001',
    name: 'Security Team',
    username: 'security.frontdesk',
    postName: 'Front Desk • Main Lobby',
    propertyName: 'Aparthub Residence',
    active: true,
    defaultPropertyId: 1,
    properties: <SecurityProperty>[
      SecurityProperty(
        id: 1,
        code: 'SITE-A',
        name: 'Aparthub Residence',
        isDefault: true,
      ),
    ],
  );
}
