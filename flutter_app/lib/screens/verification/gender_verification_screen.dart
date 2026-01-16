import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../services/gender_detection_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class GenderVerificationScreen extends StatefulWidget {
  const GenderVerificationScreen({super.key});

  @override
  State<GenderVerificationScreen> createState() => _GenderVerificationScreenState();
}

class _GenderVerificationScreenState extends State<GenderVerificationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isProcessing = false;
  String? _detectedGender;
  double? _confidence;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    GenderDetectionService.initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) return;

      // Use front camera
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      setState(() => _capturedImage = imageFile);

      // Detect gender
      final result = await GenderDetectionService.detectGender(imageFile);

      if (result['success']) {
        setState(() {
          _detectedGender = result['gender'];
          _confidence = result['confidence'];
        });

        // Show confirmation dialog
        _showConfirmationDialog(imageFile, result['gender'], result['confidence']);
      } else {
        _showError(result['error'] ?? 'Detection failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showConfirmationDialog(File imageFile, String gender, double confidence) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verification Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(imageFile, height: 200, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text(
              'Detected: ${gender.toUpperCase()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will be your verified gender and cannot be changed later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedImage = null;
                _detectedGender = null;
                _confidence = null;
              });
            },
            child: const Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () => _submitVerification(imageFile, gender),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVerification(File imageFile, String gender) async {
    Navigator.pop(context); // Close dialog
    setState(() => _isProcessing = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        _showError('Not authenticated');
        return;
      }

      final result = await GenderDetectionService.verifyWithBackend(
        imageFile: imageFile,
        detectedGender: gender,
        token: token,
      );

      if (result['success']) {
        // Update user data
        await authService.refreshUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Verification successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showError(result['message'] ?? 'Verification failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Overlay
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Gender Verification',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // Instructions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.face, color: Colors.white, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Position your face in the circle',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Make sure your face is clearly visible',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Capture button
                if (!_isProcessing)
                  GestureDetector(
                    onTap: _captureAndDetect,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  const CircularProgressIndicator(color: Colors.white),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
