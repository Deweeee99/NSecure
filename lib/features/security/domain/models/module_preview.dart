enum ModulePreviewStatus {
  active,
  comingSoon,
  designConcept,
}

class ModulePreview {
  const ModulePreview({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.isActiveModule,
  });

  final String key;
  final String title;
  final String subtitle;
  final ModulePreviewStatus status;
  final bool isActiveModule;
}
