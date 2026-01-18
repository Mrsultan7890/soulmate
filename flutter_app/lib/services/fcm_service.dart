import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constants.dart';
import '../utils/storage_helper.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // Create notification channel
    const androidChannel = AndroidNotificationChannel(
      'heartlink_channel',
      'HeartLink Notifications',
      description: 'HeartLink app notifications',
      importance: Importance.high,
    );
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Get and send FCM token to backend
    String? token = await _messaging.getToken();
    if (token != null) {
      _fcmToken = token;
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _sendTokenToBackend(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _initialized = true;
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      print('🔄 Attempting to send FCM token to backend...');
      print('Token: ${token.substring(0, 20)}...');
      
      final authToken = await StorageHelper.getToken();
      if (authToken == null) {
        print('❌ No auth token found in storage');
        return;
      }
      
      print('✅ Auth token found: ${authToken.substring(0, 20)}...');
      
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/users/fcm-token'),
        headers: ApiConstants.getHeaders(token: authToken),
        body: jsonEncode({'fcm_token': token}),
      );
      
      print('📡 FCM token API response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ FCM token sent to backend successfully');
      } else {
        print('❌ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ FCM token send error: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');
    print('Message data: ${message.data}');
    
    // Handle welcome notification
    if (message.data['type'] == 'welcome') {
      print('🎉 Welcome notification received!');
    }
    
    // Handle zone invitation
    if (message.data['type'] == 'zone_invitation') {
      print('🎮 Zone invitation received!');
      // Could show dialog or navigate to zone
    }
    
    if (message.notification != null) {
      await _showLocalNotification(
        message.notification!.title ?? 'HeartLink',
        message.notification!.body ?? '',
        message.data,
      );
    }
  }

  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'heartlink_channel',
      'HeartLink Notifications',
      channelDescription: 'HeartLink app notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> saveFCMToken(String token, String authToken) async {
    await _sendTokenToBackend(token);
  }
}