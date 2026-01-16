import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/api_constants.dart';
import '../utils/session_manager.dart';
import 'fcm_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _rememberMe = true;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get rememberMe => _rememberMe;

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();
    
    await _loadStoredAuth();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final sessionData = await SessionManager.getStoredSession();
      
      if (sessionData != null) {
        _token = sessionData['token'];
        _currentUser = User.fromJson(sessionData['userData']);
        _rememberMe = sessionData['rememberMe'] ?? true;
        
        // Verify token is still valid
        await getCurrentUser();
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      await SessionManager.clearSession();
    }
  }

  Future<void> _saveAuthData() async {
    if (_token != null && _currentUser != null) {
      await SessionManager.saveSession(
        token: _token!,
        userData: _currentUser!.toJson(),
        rememberMe: _rememberMe,
      );
    }
  }

  Future<void> _clearStoredAuth() async {
    await SessionManager.clearSession();
    _token = null;
    _currentUser = null;
    _rememberMe = true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    int? age,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'age': age,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        _currentUser = User.fromJson(data['user']);
        
        await _saveAuthData();
        
        // Save FCM token to backend
        try {
          final fcmToken = await FCMService.initialize();
          if (fcmToken != null && _token != null) {
            await FCMService.saveFCMToken(fcmToken, _token!);
          }
        } catch (e) {
          print('FCM token save failed: $e');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _error = error['detail'] ?? 'Registration failed';
        _isLoading = false;
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

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    _error = null;
    _rememberMe = rememberMe;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login response: $data');
        
        if (data == null || data is! Map<String, dynamic>) {
          _error = 'Invalid response from server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        _token = data['access_token'];
        
        if (data['user'] == null || data['user'] is! Map<String, dynamic>) {
          _error = 'Invalid user data received';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        _currentUser = User.fromJson(data['user']);
        
        await _saveAuthData();
        
        // Save FCM token to backend
        try {
          final fcmToken = await FCMService.initialize();
          if (fcmToken != null && _token != null) {
            await FCMService.saveFCMToken(fcmToken, _token!);
            print('✅ FCM token saved after login');
          }
        } catch (e) {
          print('⚠️ FCM token save failed: $e');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _error = error['detail'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getCurrentUser() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
        headers: ApiConstants.getHeaders(token: _token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User data received: $data');
        _currentUser = User.fromJson(data);
        await _saveAuthData();
        notifyListeners();
      } else if (response.statusCode == 401) {
        await logout();
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      print('Error getting current user: $e');
      print('Stack trace: $stack');
    }
  }

  Future<void> logout() async {
    await _clearStoredAuth();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
