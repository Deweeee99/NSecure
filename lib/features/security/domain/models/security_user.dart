class SecurityProperty {
  const SecurityProperty({
    required this.id,
    required this.code,
    required this.name,
    this.isDefault = false,
  });

  final int id;
  final String code;
  final String name;
  final bool isDefault;
}

class SecurityUser {
  const SecurityUser({
    required this.id,
    required this.name,
    required this.username,
    required this.postName,
    required this.propertyName,
    required this.active,
    this.defaultPropertyId,
    this.properties = const <SecurityProperty>[],
  });

  final String id;
  final String name;
  final String username;
  final String postName;
  final String propertyName;
  final bool active;
  final int? defaultPropertyId;
  final List<SecurityProperty> properties;
}
