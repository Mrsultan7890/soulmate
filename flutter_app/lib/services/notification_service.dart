import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    _initialized = true;
  }

  static Future<void> showNotification(String title, String body) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> showMatchNotification(String userName) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'matches',
      'Matches',
      channelDescription: 'New match notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      '💕 New Match!',
      'You matched with $userName',
      notificationDetails,
    );
  }

  static Future<void> showMessageNotification(String userName, String message) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      '💬 $userName',
      message,
      notificationDetails,
    );
  }

  static Future<void> showLikeNotification(String userName) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'likes',
      'Likes',
      channelDescription: 'New like notifications',
      importance: Importance.default_,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      '❤️ New Like',
      '$userName liked you!',
      notificationDetails,
    );
  }
}
