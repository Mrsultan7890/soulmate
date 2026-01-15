import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _loginTimeKey = 'login_time';
  static const String _rememberMeKey = 'remember_me';
  static const String _autoLoginKey = 'auto_login_enabled';
  
  // Session expires after 30 days if remember me is disabled
  static const Duration _sessionDuration = Duration(days: 30);
  
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> userData,
    bool rememberMe = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userDataKey, jsonEncode(userData));
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_rememberMeKey, rememberMe);
    await prefs.setBool(_autoLoginKey, true);
  }
  
  static Future<Map<String, dynamic>?> getStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    final token = prefs.getString(_tokenKey);
    final userDataJson = prefs.getString(_userDataKey);
    final loginTime = prefs.getInt(_loginTimeKey);
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final autoLogin = prefs.getBool(_autoLoginKey) ?? false;
    
    if (token == null || userDataJson == null || loginTime == null || !autoLogin) {
      return null;
    }
    
    // Check if session is expired (only if remember me is disabled)
    if (!rememberMe) {
      final sessionAge = DateTime.now().millisecondsSinceEpoch - loginTime;
      if (sessionAge > _sessionDuration.inMilliseconds) {
        await clearSession();
        return null;
      }
    }
    
    try {
      return {
        'token': token,
        'userData': jsonDecode(userDataJson),
        'rememberMe': rememberMe,
      };
    } catch (e) {
      await clearSession();
      return null;
    }
  }
  
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_rememberMeKey);
    await prefs.setBool(_autoLoginKey, false);
  }
  
  static Future<bool> isAutoLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLoginKey) ?? false;
  }
  
  static Future<void> updateLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }
}