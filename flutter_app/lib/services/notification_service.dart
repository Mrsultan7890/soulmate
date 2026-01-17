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

    // Create notification channels
    await _createNotificationChannels();
    _initialized = true;
  }

  static Future<void> _createNotificationChannels() async {
    const matchChannel = AndroidNotificationChannel(
      'matches',
      'Matches',
      description: 'New match notifications',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('match_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const messageChannel = AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'New message notifications',
      importance: Importance.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    const likeChannel = AndroidNotificationChannel(
      'likes',
      'Likes',
      description: 'New like notifications',
      importance: Importance.defaultImportance,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 200]),
    );

    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(matchChannel);
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messageChannel);
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(likeChannel);
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

  static Future<void> showMatchNotification(String userName) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'matches',
      'Matches',
      channelDescription: 'New match notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE91E63),
      styleInformation: BigTextStyleInformation(
        'You and $userName liked each other! Start chatting now.',
        htmlFormatBigText: true,
        contentTitle: '💕 It\'s a Match!',
        htmlFormatContentTitle: true,
      ),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      '💕 It\'s a Match!',
      'You and $userName liked each other!',
      notificationDetails,
    );
  }

  static Future<void> showMessageNotification(String userName, String message) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF2196F3),
      styleInformation: BigTextStyleInformation(
        message,
        htmlFormatBigText: true,
        contentTitle: '💬 $userName',
        htmlFormatContentTitle: true,
      ),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
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
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF5722),
      styleInformation: BigTextStyleInformation(
        'Someone new is interested in you! Check who liked you.',
        htmlFormatBigText: true,
        contentTitle: '❤️ New Like',
        htmlFormatContentTitle: true,
      ),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 200]),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      '❤️ New Like',
      'Someone liked you!',
      notificationDetails,
    );
  }
}
