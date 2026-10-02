enum SecurityTaskPreviewType {
  patrol,
  visitor,
  incident,
  dispatch,
}

enum SecurityTaskPreviewStatus {
  inProgress,
  waiting,
  attention,
}

enum SecurityTaskPriority {
  normal,
  high,
  critical,
}

class SecurityTaskPreview {
  const SecurityTaskPreview({
    required this.id,
    required this.type,
    required this.status,
    this.priority = SecurityTaskPriority.normal,
    this.location,
    this.source,
    this.createdAtLabel,
  });

  final String id;
  final SecurityTaskPreviewType type;
  final SecurityTaskPreviewStatus status;
  final SecurityTaskPriority priority;
  final String? location;
  final String? source;
  final String? createdAtLabel;
}
