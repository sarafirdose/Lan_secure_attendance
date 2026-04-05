import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static DateTime? _lastNotifyTime;
  static const Duration _spamCooldown = Duration(seconds: 30);

  Future<void> init() async {
    tz.initializeTimeZones();

    // Request Notification Permissions (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request Exact Alarm Permissions if needed
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );

    // Create a high-priority channel for Android
    const AndroidNotificationChannel highChannel = AndroidNotificationChannel(
      'ai_critical_channel',
      'Critical AI Alerts',
      description: 'Used for critical attendance and fraud warnings.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
      'ai_normal_channel',
      'AI Notifications',
      description: 'Standard AI summaries and updates.',
      importance: Importance.high,
    );

    final androidPlatform = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlatform != null) {
      await androidPlatform.createNotificationChannel(highChannel);
      await androidPlatform.createNotificationChannel(normalChannel);
    }
  }

  /// Show an immediate notification with specific priority
  
  Future<void> scheduleClassReminder({
    required int id,
    required String subject,
    required DateTime classTime,
  }) async {
    final notifyTime = classTime.subtract(const Duration(minutes: 10));
    if (notifyTime.isBefore(DateTime.now())) return; // Past

    await _notificationsPlugin.zonedSchedule(
      id,
      'Class Starting Soon',
      'Your $subject class starts in 10 minutes at ${classTime.hour}:${classTime.minute.toString().padLeft(2, '0')}',
      tz.TZDateTime.from(notifyTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ai_normal_channel',
          'AI Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String priority = 'NORMAL',
    bool bypassSpamFilter = false,
  }) async {
    // Spam Prevention Logic
    final now = DateTime.now();
    if (!bypassSpamFilter && _lastNotifyTime != null && now.difference(_lastNotifyTime!) < _spamCooldown) {
      return; 
    }
    _lastNotifyTime = now;

    AndroidNotificationDetails androidDetails;
    
    if (priority == 'CRITICAL') {
      androidDetails = const AndroidNotificationDetails(
        'ai_critical_channel',
        'Critical AI Alerts',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        styleInformation: BigTextStyleInformation(''),
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        'ai_normal_channel',
        'AI Notifications',
        importance: Importance.high,
        priority: Priority.defaultPriority,
      );
    }

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      now.millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  // Alias for legacy or specific service calls
  Future<void> showLocalNotification({
    int? id,
    required String title,
    required String body,
    String priority = 'NORMAL',
  }) async {
    return showNotification(title: title, body: body, priority: priority);
  }

  /// Schedule a notification for a specific time (e.g., class reminders)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_reminders',
          'Class Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
