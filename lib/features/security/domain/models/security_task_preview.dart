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

class SecurityTaskPreview {
  const SecurityTaskPreview({
    required this.id,
    required this.type,
    required this.status,
  });

  final String id;
  final SecurityTaskPreviewType type;
  final SecurityTaskPreviewStatus status;
}
