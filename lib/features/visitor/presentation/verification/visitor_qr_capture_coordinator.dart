class VisitorQrCaptureCoordinator {
  bool _processing = false;

  bool get isProcessing => _processing;

  bool tryBegin(String payload) {
    if (_processing || payload.isEmpty) return false;
    _processing = true;
    return true;
  }

  void complete() {
    _processing = false;
  }
}
