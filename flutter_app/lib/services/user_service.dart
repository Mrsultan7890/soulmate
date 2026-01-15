import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/api_constants.dart';

class UserService extends ChangeNotifier {
  List<User> _discoverUsers = [];
  bool _isLoading = false;
  String? _error;

  List<User> get discoverUsers => _discoverUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> updateProfile({
    required String token,
    String? name,
    int? age,
    String? bio,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? interests,
    String? relationshipIntent,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (age != null) body['age'] = age;
      if (bio != null) body['bio'] = bio;
      if (location != null) body['location'] = location;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (interests != null) body['interests'] = interests;
      if (relationshipIntent != null) body['relationship_intent'] = relationshipIntent;

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode(body),
      );

      _isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile';
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

  Future<bool> uploadImage(String token, String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadImage}'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'telegram_file_id': base64Image,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      _error = 'Failed to upload image: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImage(String token, int imageIndex) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteImage}/$imageIndex'),
        headers: ApiConstants.getHeaders(token: token),
      );

      return response.statusCode == 200;
    } catch (e) {
      _error = 'Failed to delete image';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchDiscoverUsers(String token, {
    int limit = 20,
    int? minAge,
    int? maxAge,
    double? maxDistanceKm,
    String? relationshipIntent,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (minAge != null) 'min_age': minAge.toString(),
        if (maxAge != null) 'max_age': maxAge.toString(),
        if (maxDistanceKm != null) 'max_distance_km': maxDistanceKm.toString(),
        if (relationshipIntent != null) 'relationship_intent': relationshipIntent,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.discover}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _discoverUsers = (data['users'] as List)
            .map((user) => User.fromJson(user))
            .toList();
      } else {
        _error = 'Failed to fetch users';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateLocation(
    String token,
    double latitude,
    double longitude,
    String? locationName, {
    double? gpsAccuracy,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateLocation}'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'location_name': locationName,
          'gps_accuracy': gpsAccuracy ?? 0,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAvailableInterests(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getInterests}'),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['interests']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateInterests(String token, List<String> interests) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateInterests}'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({'interests': interests}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void removeUserAtIndex(int index) {
    if (index >= 0 && index < _discoverUsers.length) {
      _discoverUsers.removeAt(index);
      notifyListeners();
    }
  }
}
