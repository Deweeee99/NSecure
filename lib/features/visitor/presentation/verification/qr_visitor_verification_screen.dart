import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';

import 'visitor_qr_capture_coordinator.dart';

class QrVisitorVerificationScreen extends StatefulWidget {
  const QrVisitorVerificationScreen({
    required this.isLoading,
    required this.onBack,
    required this.enableDeviceScanner,
    required this.onOpenManual,
    required this.onQrDetected,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onBack;
  final bool enableDeviceScanner;
  final VoidCallback onOpenManual;
  final Future<void> Function(String payload) onQrDetected;

  @override
  State<QrVisitorVerificationScreen> createState() =>
      _QrVisitorVerificationScreenState();
}

class _QrVisitorVerificationScreenState
    extends State<QrVisitorVerificationScreen> {
  MobileScannerController? _controller;
  final VisitorQrCaptureCoordinator _captureCoordinator =
      VisitorQrCaptureCoordinator();

  @override
  void initState() {
    super.initState();
    if (widget.enableDeviceScanner) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.normal,
      );
    }
  }

  @override
  void didUpdateWidget(covariant QrVisitorVerificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableDeviceScanner == widget.enableDeviceScanner) return;

    final oldController = _controller;
    _controller = widget.enableDeviceScanner
        ? MobileScannerController(
            formats: const [BarcodeFormat.qrCode],
            detectionSpeed: DetectionSpeed.normal,
          )
        : null;
    if (oldController != null) {
      unawaited(oldController.dispose());
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SecurityColors.primaryDeep,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ScannerHeader(
              onBack: widget.onBack,
              onToggleTorch:
                  widget.enableDeviceScanner ? _toggleTorch : _showDemoTorchInfo,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SecuritySpacing.lg,
                  SecuritySpacing.lg,
                  SecuritySpacing.lg,
                  SecuritySpacing.xl,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: SecuritySpacing.lg),
                    if (widget.enableDeviceScanner)
                      _buildDeviceScanner()
                    else
                      _DemoScannerFrame(
                        isLoading: widget.isLoading,
                        onTap: () => widget.onQrDetected('SEC-QR-DEMO-000245'),
                      ),
                    const SizedBox(height: SecuritySpacing.xl),
                    Text(
                      widget.enableDeviceScanner
                          ? context.l10n.qrPositionApi
                          : context.l10n.qrPositionDemo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: SecuritySpacing.xs),
                    Text(
                      widget.enableDeviceScanner
                          ? context.l10n.qrApiExactPayload
                          : context.l10n.qrDemoExplanation,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: SecuritySpacing.xxl),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SecuritySpacing.sm,
                          ),
                          child: Text(
                            context.l10n.or,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: SecuritySpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            widget.isLoading ? null : widget.onOpenManual,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white60),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.keyboard_alt_outlined),
                        label: Text(context.l10n.enterCodeManually),
                      ),
                    ),
                    const SizedBox(height: SecuritySpacing.sm),
                    Material(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(SecurityRadius.md),
                      child: InkWell(
                        onTap:
                            widget.isLoading ? null : widget.onOpenManual,
                        borderRadius:
                            BorderRadius.circular(SecurityRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.all(SecuritySpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(
                                    SecurityRadius.sm,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: SecuritySpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.manualVerify,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      context.l10n.searchByVisitCodeOrId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceScanner() {
    final controller = _controller!;
    return ClipRRect(
      key: const Key('deviceQrScanner'),
      borderRadius: BorderRadius.circular(SecurityRadius.xl),
      child: SizedBox(
        height: 290,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              onDetect: _handleCapture,
              errorBuilder: (context, _) => _ScannerUnavailable(
                message: context.l10n.cameraUnavailable,
              ),
              placeholderBuilder: (context) => const ColoredBox(
                color: Color(0xFF07172E),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            const IgnorePointer(child: _ScannerCorners()),
            if (widget.isLoading || _captureCoordinator.isProcessing)
              ColoredBox(
                color: const Color(0x66000000),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleCapture(BarcodeCapture capture) {
    if (widget.isLoading) return;

    String? payload;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        payload = rawValue;
        break;
      }
    }
    if (payload == null || !_captureCoordinator.tryBegin(payload)) return;

    setState(() {});
    unawaited(_processCapture(payload));
  }

  Future<void> _processCapture(String payload) async {
    try {
      // Keep the camera session alive while the backend validates the raw QR
      // payload. The capture coordinator suppresses duplicate callbacks during
      // the in-flight request. This avoids stop/start camera lifecycle races and
      // allows the same QR to be scanned again after a backend rejection.
      await widget.onQrDetected(payload);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.qrScanFailed)),
          );
      }
    } finally {
      _captureCoordinator.complete();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || widget.isLoading) return;
    try {
      await controller.toggleTorch();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.flashlightUnavailable)),
        );
    }
  }

  void _showDemoTorchInfo() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.flashlightDeviceOnly)),
      );
  }

}

class _ScannerHeader extends StatelessWidget {
  const _ScannerHeader({
    required this.onBack,
    required this.onToggleTorch,
  });

  final VoidCallback onBack;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: context.l10n.backToSecurityHome,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              context.l10n.scanQr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          IconButton(
            onPressed: onToggleTorch,
            tooltip: context.l10n.flashlight,
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DemoScannerFrame extends StatelessWidget {
  const _DemoScannerFrame({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.scanDemoQr,
      child: InkWell(
        key: const Key('demoQrScanner'),
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(SecurityRadius.xl),
        child: Ink(
          height: 290,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF07172E),
            borderRadius: BorderRadius.circular(SecurityRadius.xl),
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _ScannerCorners()),
              Center(
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            size: 56,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: SecuritySpacing.sm),
                          Text(
                            context.l10n.tapToScanSampleQr,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'VST-240515-0012',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF07172E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(SecuritySpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 42,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScannerCornerPainter());
  }
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 34.0;
    const arm = 34.0;

    final left = margin;
    final top = margin;
    final right = size.width - margin;
    final bottom = size.height - margin;

    canvas
      ..drawLine(Offset(left, top + arm), Offset(left, top), paint)
      ..drawLine(Offset(left, top), Offset(left + arm, top), paint)
      ..drawLine(Offset(right - arm, top), Offset(right, top), paint)
      ..drawLine(Offset(right, top), Offset(right, top + arm), paint)
      ..drawLine(Offset(left, bottom - arm), Offset(left, bottom), paint)
      ..drawLine(Offset(left, bottom), Offset(left + arm, bottom), paint)
      ..drawLine(Offset(right - arm, bottom), Offset(right, bottom), paint)
      ..drawLine(Offset(right, bottom), Offset(right, bottom - arm), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
