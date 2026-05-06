// lib/screens/camera_capture_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CameraCaptureScreen extends StatefulWidget {
  final String partId;
  final String stage; // 'POST1' or 'POST2'

  const CameraCaptureScreen({
    super.key,
    required this.partId,
    required this.stage,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      
      // Save to permanent app directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'part_images'));
      await imagesDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${widget.partId}_${widget.stage}_$timestamp.jpg';
      final savedPath = p.join(imagesDir.path, filename);

      await File(photo.path).copy(savedPath);

      if (mounted) {
        Navigator.of(context).pop(savedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text('Capture Photo — ${widget.stage}'),
            Text(
              widget.partId,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized
                ? CameraPreview(_controller!)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isCapturing ? Colors.grey : Colors.white,
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : null,
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
