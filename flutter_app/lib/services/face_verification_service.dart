import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class FaceVerificationService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, dynamic>?> detectGender(String token, String imageBase64) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/face/detect-gender'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'image_data': imageBase64,
          'verification_type': 'gender_detection',
        }),
      );

      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notifyListeners();
        return data;
      } else {
        _error = 'Failed to detect gender';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyFace(
    String token, 
    String profileImage, 
    String liveImage
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/face/verify-face'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'profile_image': profileImage,
          'live_image': liveImage,
        }),
      );

      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notifyListeners();
        return data;
      } else {
        _error = 'Face verification failed';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVerificationStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/face/verification-status'),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}