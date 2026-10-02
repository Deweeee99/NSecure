import 'security_task_preview.dart';

class SecurityTaskHistoryEntry {
  const SecurityTaskHistoryEntry({
    required this.task,
    required this.completedAt,
    required this.evidenceFileName,
  });

  final SecurityTaskPreview task;
  final DateTime completedAt;
  final String evidenceFileName;
}
