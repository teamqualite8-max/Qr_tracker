// lib/screens/scan_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/part.dart';
import '../services/database_service.dart';
import '../theme.dart';
import 'camera_capture_screen.dart';

enum ScanMode { post1, post2 }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final DatabaseService _db = DatabaseService();
  final MobileScannerController _scannerController = MobileScannerController();

  ScanMode _mode = ScanMode.post1;
  bool _isProcessing = false;
  String? _lastScannedId;
  bool _scannerPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_scannerPaused) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  void _pauseScanner() {
    _scannerPaused = true;
    _scannerController.stop();
  }

  void _resumeScanner() {
    _scannerPaused = false;
    _scannerController.start();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    if (code == _lastScannedId) return;

    setState(() {
      _isProcessing = true;
      _lastScannedId = code;
    });

    _pauseScanner();
    await _handleScan(code);

    setState(() => _isProcessing = false);
    // Brief cooldown before next scan
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _lastScannedId = null);
    _resumeScanner();
  }

  Future<void> _handleScan(String partId) async {
    // Check if part exists in DB
    final exists = await _db.partExists(partId);
    if (!mounted) return;

    if (!exists) {
      _showDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        title: 'Unknown Part',
        message: 'Part ID "$partId" is not in the system.\n\nPlease import the parts list first.',
      );
      return;
    }

    final part = await _db.getPartById(partId);
    if (!mounted || part == null) return;

    if (_mode == ScanMode.post1) {
      await _handlePost1(part);
    } else {
      await _handlePost2(part);
    }
  }

  Future<void> _handlePost1(Part part) async {
    if (part.status == PartStatus.post1Done || part.status == PartStatus.post2Done) {
      final label = part.status == PartStatus.post2Done ? 'POST2_DONE' : 'POST1_DONE';
      _showDialog(
        icon: Icons.info_outline,
        iconColor: Colors.blue,
        title: 'Already Processed',
        message: 'Part "${part.partId}" has already completed Control 1.\n\nCurrent status: $label',
      );
      return;
    }

    // Take photo
    final imagePath = await _captureImage(part.partId, 'POST1');
    if (imagePath == null || !mounted) return;

    final now = DateTime.now();
    await _db.updatePost1(part.partId, now, imagePath);

    if (!mounted) return;
    _showSuccessSnack('✓ ${part.partId} completed Control 1');
  }

  Future<void> _handlePost2(Part part) async {
    if (part.status == PartStatus.notProcessed) {
      _showDialog(
        icon: Icons.block,
        iconColor: AppTheme.notProcessed,
        title: 'Control 1 Not Completed',
        message: 'This part has not passed Control 1.\n\nPart "${part.partId}" must go through Post 1 first.',
      );
      return;
    }

    if (part.status == PartStatus.post2Done) {
      _showDialog(
        icon: Icons.check_circle_outline,
        iconColor: AppTheme.post2Done,
        title: 'Already Completed',
        message: 'Part "${part.partId}" has already passed both control stages.',
      );
      return;
    }

    // Take photo for Post 2
    final imagePath = await _captureImage(part.partId, 'POST2');
    if (imagePath == null || !mounted) return;

    final now = DateTime.now();
    await _db.updatePost2(part.partId, now, imagePath);

    if (!mounted) return;
    _showSuccessSnack('✓ ${part.partId} completed Control 2 — Fully done!');
  }

  Future<String?> _captureImage(String partId, String stage) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(partId: partId, stage: stage),
      ),
    );
    return result;
  }

  void _showDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(icon, color: iconColor, size: 48),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.post2Done,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            tooltip: 'Toggle Flashlight',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_outlined),
            tooltip: 'Flip Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'POST 1',
                    subtitle: 'Control Stage 1',
                    selected: _mode == ScanMode.post1,
                    color: AppTheme.post1Done,
                    onTap: () => setState(() => _mode = ScanMode.post1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeButton(
                    label: 'POST 2',
                    subtitle: 'Control Stage 2',
                    selected: _mode == ScanMode.post2,
                    color: AppTheme.post2Done,
                    onTap: () => setState(() => _mode = ScanMode.post2),
                  ),
                ),
              ],
            ),
          ),

          // Scanner viewfinder
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                ),
                // Overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScannerOverlayPainter(),
                  ),
                ),
                // Processing indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Mode label overlay
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _mode == ScanMode.post1
                            ? AppTheme.post1Done.withOpacity(0.9)
                            : AppTheme.post2Done.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _mode == ScanMode.post1
                            ? '📷  Scanning for Control Stage 1'
                            : '📷  Scanning for Control Stage 2',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: selected ? Colors.white70 : color.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Scanner frame overlay painter
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final frameSize = size.width * 0.65;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = (size.height - frameSize) / 2;
    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize);

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;

    // Top-left
    canvas.drawLine(Offset(frameLeft, frameTop + cornerLength), Offset(frameLeft, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameTop), Offset(frameLeft + cornerLength, frameTop), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(frameLeft + frameSize - cornerLength, frameTop), Offset(frameLeft + frameSize, frameTop), cornerPaint);
    canvas.drawLine(Offset(frameLeft + frameSize, frameTop), Offset(frameLeft + frameSize, frameTop + cornerLength), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(frameLeft, frameTop + frameSize - cornerLength), Offset(frameLeft, frameTop + frameSize), cornerPaint);
    canvas.drawLine(Offset(frameLeft, frameTop + frameSize), Offset(frameLeft + cornerLength, frameTop + frameSize), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(frameLeft + frameSize - cornerLength, frameTop + frameSize), Offset(frameLeft + frameSize, frameTop + frameSize), cornerPaint);
    canvas.drawLine(Offset(frameLeft + frameSize, frameTop + frameSize), Offset(frameLeft + frameSize, frameTop + frameSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
