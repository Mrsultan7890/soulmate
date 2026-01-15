import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class SafetyService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> reportUser({
    required String token,
    required int reportedUserId,
    required String reason,
    Map<String, dynamic>? evidence,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/safety/report-user'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'reported_user_id': reportedUserId,
          'reason': reason,
          'evidence': evidence ?? {},
        }),
      );

      _isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to report user';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkUserSafety(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/safety/user-safety/$userId'),
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
