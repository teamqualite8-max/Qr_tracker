// lib/screens/verify_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/part.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../widgets/status_badge.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final DatabaseService _db = DatabaseService();
  final MobileScannerController _scannerController = MobileScannerController();

  Part? _foundPart;
  bool _isSearching = false;
  bool _scanning = true;
  String? _notFoundId;

  final DateFormat _fmt = DateFormat('dd MMM yyyy  HH:mm:ss');

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isSearching || !_scanning) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isSearching = true;
      _scanning = false;
    });

    _scannerController.stop();

    final part = await _db.getPartById(code);

    if (!mounted) return;

    setState(() {
      _foundPart = part;
      _notFoundId = part == null ? code : null;
      _isSearching = false;
    });
  }

  void _resetScan() {
    setState(() {
      _foundPart = null;
      _notFoundId = null;
      _scanning = true;
    });
    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Part'),
        actions: [
          if (!_scanning)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan another',
              onPressed: _resetScan,
            ),
        ],
      ),
      body: _scanning ? _buildScanner() : _buildResult(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Scan a QR code to check its status',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onBarcodeDetected,
              ),
              if (_isSearching)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🔍  Point camera at QR code',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (_notFoundId != null) {
      return _buildNotFound(_notFoundId!);
    }

    if (_foundPart == null) {
      return const Center(child: Text('No result'));
    }

    return _buildPartDetail(_foundPart!);
  }

  Widget _buildNotFound(String id) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Part Not Found',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                id,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This ID is not in the system.\nImport the parts CSV to add it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _resetScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartDetail(Part part) {
    final color = AppTheme.statusColorFromEnum(part.status);
    final delay = part.delayBetweenPosts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Part ID card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon(part.status), color: color, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    part.partId,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(status: part.status),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Timeline card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Processing Timeline',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineStep(
                    step: 1,
                    label: 'Control Stage 1',
                    timestamp: part.post1Timestamp,
                    imagePath: part.post1ImagePath,
                    color: AppTheme.post1Done,
                    done: part.post1Timestamp != null,
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineStep(
                    step: 2,
                    label: 'Control Stage 2',
                    timestamp: part.post2Timestamp,
                    imagePath: part.post2ImagePath,
                    color: AppTheme.post2Done,
                    done: part.post2Timestamp != null,
                  ),
                  if (delay != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Delay between stages: ${_formatDuration(delay)}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _resetScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another Part'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int step,
    required String label,
    required DateTime? timestamp,
    required String? imagePath,
    required Color color,
    required bool done,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color : Colors.grey[200],
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: done ? Colors.black87 : Colors.grey,
                ),
              ),
              if (timestamp != null)
                Text(
                  _fmt.format(timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                )
              else
                Text(
                  'Not completed',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
                ),
              if (imagePath != null && File(imagePath).existsSync()) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showImageDialog(imagePath),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      height: 80,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  IconData _statusIcon(PartStatus status) {
    return switch (status) {
      PartStatus.post2Done => Icons.verified,
      PartStatus.post1Done => Icons.pending_actions,
      PartStatus.notProcessed => Icons.hourglass_empty,
    };
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h ${d.inMinutes.remainder(60)}m';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }
}
