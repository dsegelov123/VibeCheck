import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('NotificationService: Local notifications are not supported on Web.');
      return;
    }

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleCheckIn(String mood, Duration delay) async {
    if (kIsWeb) {
      debugPrint('NotificationService: Skipping check-in schedule (Web). Mood: $mood');
      return;
    }

    // Determine the message based on previous mood
    String title = "Thinking of you";
    String body = "Just checking in. How are you feeling now?";
    
    if (mood == 'sad') {
      title = "Hey Finn here 👋";
      body = "You were feeling a bit down earlier. Just checking in to see if you want to talk.";
    } else if (mood == 'anxious') {
      title = "Checking in";
      body = "You were feeling anxious earlier. Remember to take a deep breath. I'm here if you need me.";
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID 
      title,
      body,
      tz.TZDateTime.now(tz.local).add(delay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vibecheck_checkins',
          'VibeCheck Check-ins',
          channelDescription: 'Proactive emotional check-ins',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'check_in_nudge',
    );
    
    debugPrint('NotificationService: Scheduled an empathetic check-in for $delay from now.');
  }
}
