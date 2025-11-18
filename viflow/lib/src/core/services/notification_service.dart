import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> requestPermissions() async {
    // 1. Genel Bildirim İzni
    PermissionStatus status = await Permission.notification.request();

    // 2. (Opsiyonel) Android 12+ için Exact Alarm izni kontrolü
    // Bu izin genelde otomatiktir ama bazı cihazlarda manuel açılması gerekebilir.
    // Şimdilik sadece notification izni yeterli, exact alarm'ı try-catch ile yöneteceğiz.

    if (status.isGranted) return true;

    final bool? result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return result ?? false;
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleDailyNotifications({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int intervalMinutes,
    required String title,
    required String body,
  }) async {
    await cancelAllNotifications();

    int startTotalMinutes = startTime.hour * 60 + startTime.minute;
    int endTotalMinutes = endTime.hour * 60 + endTime.minute;

    if (endTotalMinutes <= startTotalMinutes) {
      endTotalMinutes += 24 * 60;
    }

    int currentMinutes = startTotalMinutes + intervalMinutes;
    int notificationId = 0;

    while (currentMinutes <= endTotalMinutes) {
      int hour = (currentMinutes ~/ 60) % 24;
      int minute = currentMinutes % 60;

      await _scheduleDailyAtTime(notificationId++, hour, minute, title, body);

      currentMinutes += intervalMinutes;
    }
  }

  // --- GÜNCELLENEN FONKSİYON (GÜVENLİ ZAMANLAMA) ---
  Future<void> _scheduleDailyAtTime(
      int id, int hour, int minute, String title, String body) async {

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    // Android Bildirim Detayları
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Water Reminders',
      channelDescription: 'Reminds you to drink water',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(sound: 'default.wav');

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // 1. Önce Tam Zamanlı (Exact) kurmayı dene
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        // Exact mod: Tam zamanında çalar (İzin gerektirir)
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // 2. Eğer hata verirse (Exact Alarm izni yoksa), Yaklaşık Zamanlı (Inexact) kur
      // Bu mod izin gerektirmez ama pil durumuna göre 1-2 dk gecikebilir.
      debugPrint("Exact alarm izni yok, Inexact moda geçiliyor: $e");

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        // Inexact mod: Hata vermez, garantidir.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}