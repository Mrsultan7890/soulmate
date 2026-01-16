import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constants.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  // Initialize FCM
  static Future<String?> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM Permission granted');
        
        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('📱 FCM Token: $_fcmToken');
        
        // Initialize local notifications
        await _initializeLocalNotifications();
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
        
        // Handle token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          print('🔄 FCM Token refreshed: $newToken');
        });
        
        return _fcmToken;
      } else {
        print('❌ FCM Permission denied');
        return null;
      }
    } catch (e) {
      print('⚠️ FCM initialization failed (Firebase not configured): $e');
      return null;
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );
    
    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'heartlink_channel',
      'HeartLink Notifications',
      description: 'Notifications for matches, messages, and likes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Handle foreground messages (app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Foreground message: ${message.notification?.title}');
    
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'HeartLink',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  // Handle background messages (app is closed/background)
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📭 Background message opened: ${message.notification?.title}');
    // Navigate to appropriate screen based on message.data
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'heartlink_channel',
      'HeartLink Notifications',
      channelDescription: 'Notifications for matches, messages, and likes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Save FCM token to backend
  static Future<bool> saveFCMToken(String token, String userToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/users/fcm-token'),
        headers: ApiConstants.getHeaders(token: userToken),
        body: jsonEncode({'fcm_token': token}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error saving FCM token: $e');
      return false;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background notification: ${message.notification?.title}');
}
