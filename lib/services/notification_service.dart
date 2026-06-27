import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<String> _getLocalTimezoneName() async {
    const channel = MethodChannel('com.example.growlog/timezone');
    try {
      final String? timezone = await channel.invokeMethod<String>('getLocalTimezone');
      return timezone ?? 'UTC';
    } catch (e) {
      debugPrint('Error fetching native timezone, defaulting to UTC: $e');
      return 'UTC';
    }
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // Query native device timezone and set as local
    final timezoneName = await _getLocalTimezoneName();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
      debugPrint('Notification local timezone set to: $timezoneName');
    } catch (e) {
      debugPrint('Failed to set timezone location $timezoneName: $e. Falling back to UTC.');
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click if needed
      },
    );

    // Request permissions on Android 13+
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // On Android 12+ (API 31+), request exact alarms permission
      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Failed to request exact alarm permission: $e');
      }
    }
  }

  // Schedule a daily reminder at a specific time (Format: HH:mm)
  static Future<void> scheduleDailyReminder(String timeString) async {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Cancel any existing daily reminder first
      await _notificationsPlugin.cancel(0);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final Int64List vibrationPattern = Int64List.fromList([0, 3000]);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminder_channel_v4',
        'Daily Reminder',
        channelDescription: 'Daily check-in reminder to log your progress',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        0,
        'Time to grow! 🌱',
        'Open GrowLog and record your learnings for today.',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Daily reminder scheduled for $timeString');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
}
