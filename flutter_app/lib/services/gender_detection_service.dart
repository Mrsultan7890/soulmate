import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class GenderDetectionService {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;

  // Initialize TFLite model
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/gender_model.tflite');
      _isInitialized = true;
      print('✅ Gender detection model loaded');
    } catch (e) {
      print('⚠️ Failed to load model: $e');
      _isInitialized = false;
    }
  }

  // Detect gender from image
  static Future<Map<String, dynamic>> detectGender(File imageFile) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_interpreter == null) {
        return {
          'success': false,
          'error': 'Model not loaded',
        };
      }

      // Read and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return {
          'success': false,
          'error': 'Failed to decode image',
        };
      }

      // Resize to model input size (224x224)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to input tensor
      var input = _imageToByteListFloat32(resizedImage);

      // Output tensor
      var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

      // Run inference
      _interpreter!.run(input, output);

      // Parse results
      double maleScore = output[0][0];
      double femaleScore = output[0][1];

      String gender = maleScore > femaleScore ? 'male' : 'female';
      double confidence = maleScore > femaleScore ? maleScore : femaleScore;

      return {
        'success': true,
        'gender': gender,
        'confidence': confidence,
        'male_score': maleScore,
        'female_score': femaleScore,
      };
    } catch (e) {
      print('Gender detection error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Convert image to input tensor
  static List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    var convertedBytes = List.generate(
      1,
      (i) => List.generate(
        224,
        (j) => List.generate(
          224,
          (k) => List.filled(3, 0.0),
        ),
      ),
    );

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        var pixel = image.getPixel(x, y);
        convertedBytes[0][y][x][0] = (pixel.r / 255.0 - 0.5) * 2.0;
        convertedBytes[0][y][x][1] = (pixel.g / 255.0 - 0.5) * 2.0;
        convertedBytes[0][y][x][2] = (pixel.b / 255.0 - 0.5) * 2.0;
      }
    }

    return convertedBytes;
  }

  // Send verification to backend
  static Future<Map<String, dynamic>> verifyWithBackend({
    required File imageFile,
    required String detectedGender,
    required String token,
  }) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/verification/verify-gender'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'image_base64': base64Image,
          'detected_gender': detectedGender,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Verification failed: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get verification status
  static Future<Map<String, dynamic>> getVerificationStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/verification/verification-status'),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'is_verified': false,
          'gender': null,
        };
      }
    } catch (e) {
      print('Error getting verification status: $e');
      return {
        'is_verified': false,
        'gender': null,
      };
    }
  }

  static void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
