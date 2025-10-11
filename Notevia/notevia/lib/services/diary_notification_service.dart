import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../screens/diary_screen.dart';
import '../main.dart';
import 'database_service.dart';
import '../models/note.dart';
import '../widgets/pin_input_dialog.dart';

class DiaryNotificationService {
  static final DiaryNotificationService _instance =
      DiaryNotificationService._internal();
  factory DiaryNotificationService() => _instance;
  DiaryNotificationService._internal();

  final DatabaseService _databaseService = DatabaseService();

  static const String _diaryReminderChannelKey = 'diary_reminders';
  // These will be set dynamically based on current locale
  static String _diaryReminderChannelName = 'Günlük Hatırlatıcıları';
  static String _diaryReminderChannelDescription = 'Günlük yazma hatırlatıcı bildirimleri';
  static const int _diaryNotificationId = 999999;

  Future<void> initialize() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Initialize awesome notifications
    await AwesomeNotifications().initialize(
      null, // Use default app icon to avoid resource issues
      [
        NotificationChannel(
          channelKey: 'diary_reminder_channel',
          channelName: _diaryReminderChannelName,
          channelDescription: _diaryReminderChannelDescription,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'note_reminders',
          channelName: 'Not Hatırlatıcıları', // Will be updated dynamically
          channelDescription: 'Not hatırlatıcı bildirimleri', // Will be updated dynamically
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
      debug: false,
    );

    // Set up notification action listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );

    print('DiaryNotificationService: Initialized with awesome_notifications');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationActionReceived(
    ReceivedAction receivedAction,
  ) async {
    if (receivedAction.payload != null &&
        receivedAction.payload!.containsKey('action')) {
      final action = receivedAction.payload!['action'];
      if (action == 'diary_reminder') {
        // Navigate to diary screen
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamed('/diary');
        }
      } else if (action == 'note_reminder') {
        // Navigate to specific note
        final noteIdStr = receivedAction.payload!['noteId'];
        if (noteIdStr != null && navigatorKey.currentContext != null) {
          final noteId = int.tryParse(noteIdStr);
          if (noteId != null) {
            _openNoteFromNotification(noteId);
          }
        }
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreated(
    ReceivedNotification receivedNotification,
  ) async {
    // Handle notification creation
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
    ReceivedNotification receivedNotification,
  ) async {
    // Handle notification display
  }

  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceived(
    ReceivedAction receivedAction,
  ) async {
    // Handle notification dismiss
  }

  static Future<void> _openNoteFromNotification(int noteId) async {
    final databaseService = DatabaseService();
    final note = await databaseService.getNoteById(noteId);

    if (note != null && navigatorKey.currentContext != null) {
      if (note.isHidden) {
        _showPinDialog(navigatorKey.currentContext!, () {
          _navigateToNoteDetail(note);
        });
      } else {
        _navigateToNoteDetail(note);
      }
    }
  }

  static void _navigateToNoteDetail(Note note) {
    if (navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!).pushNamed(
        '/note_detail',
        arguments: note,
      );
    }
  }

  static void _showPinDialog(BuildContext context, VoidCallback onSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        title: 'PIN Girin',
        onPinEntered: (pin) async {
          final prefs = await SharedPreferences.getInstance();
          final savedPin = prefs.getString('app_pin') ?? '';
          if (pin == savedPin) {
            Navigator.pop(context);
            onSuccess();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yanlış PIN'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> scheduleDailyDiaryReminder({String time = '20:00'}) async {
    try {
      // Request notification permissions
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        isAllowed = await AwesomeNotifications()
            .requestPermissionToSendNotifications();
      }

      if (!isAllowed) {
        print('Notification permission denied');
        return;
      }

      // Cancel existing notifications
      await AwesomeNotifications().cancelSchedule(_diaryNotificationId);

      // Parse time
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Get current timezone
      final now = DateTime.now();
      final localTimeZone = now.timeZoneName;

      // Calculate next notification time in user's timezone
      var nextNotification = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (nextNotification.isBefore(now)) {
        nextNotification = nextNotification.add(const Duration(days: 1));
      }

      // Schedule daily notification with timezone awareness
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _diaryNotificationId,
          channelKey: 'diary_reminder_channel',
          title: 'Günlük Hatırlatıcısı', // Will be localized at runtime
      body: 'Bugünün günlüğünü yazmayı unutmayın! 📝', // Will be localized at runtime
          payload: {
            'action': 'diary_reminder',
            'time': time,
            'timezone': localTimeZone,
          },
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('diary_reminder_time', time);
      await prefs.setBool('diary_reminder_enabled', true);
      await prefs.setString('diary_reminder_timezone', localTimeZone);

      print(
        'Daily diary reminder scheduled for $time in timezone: $localTimeZone',
      );
    } catch (e) {
      print('Error scheduling daily diary reminder: $e');
    }
  }

  Future<void> _scheduleDailyNotification(String time) async {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _diaryNotificationId,
        channelKey: 'diary_reminder_channel',
        title: 'Günlük Hatırlatıcısı', // Will be localized at runtime
      body: 'Bugünün günlüğünü yazmayı unutmayın! 📝', // Will be localized at runtime
        payload: {'action': 'diary_reminder', 'time': time},
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }

  Future<void> checkAndShowDailyReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('diary_reminder_enabled') ?? false;

      if (!isEnabled) return;

      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final lastChecked = prefs.getString('last_diary_check_date');

      // Only check once per day
      if (lastChecked == today) return;

      // Check if user has written diary today
      final hasWrittenToday = await _hasWrittenDiaryToday();

      if (!hasWrittenToday) {
        // Get reminder time and timezone
        final reminderTime = prefs.getString('diary_reminder_time') ?? '20:00';
        final timeParts = reminderTime.split(':');
        final reminderHour = int.parse(timeParts[0]);
        final reminderMinute = int.parse(timeParts[1]);

        // Check if it's past reminder time
        final currentHour = now.hour;
        final currentMinute = now.minute;
        final currentTimeInMinutes = currentHour * 60 + currentMinute;
        final reminderTimeInMinutes = reminderHour * 60 + reminderMinute;

        if (currentTimeInMinutes >= reminderTimeInMinutes) {
          final userTimeZone = now.timeZoneName;

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: _diaryNotificationId + 1000,
              channelKey: 'diary_reminder_channel',
              title: 'Günlük Hatırlatıcısı 📝', // Will be localized at runtime
      body: 'Bugünün günlüğünü henüz yazmadınız. Günlüğünüzü yazmak için dokunun!', // Will be localized at runtime
              payload: {
                'action': 'diary_reminder',
                'timezone': userTimeZone,
                'reminder_type': 'daily_check',
              },
              notificationLayout: NotificationLayout.Default,
              wakeUpScreen: true,
            ),
          );

          print(
            'Daily reminder sent at ${now.hour}:${now.minute} in timezone: $userTimeZone',
          );
        }
      }

      // Mark as checked for today
      await prefs.setString('last_diary_check_date', today);
    } catch (e) {
      print('Error checking daily reminder: $e');
    }
  }

  Future<void> _cancelDailyDiaryReminder() async {
    await AwesomeNotifications().cancel(_diaryNotificationId);
  }

  Future<void> disableDailyDiaryReminder() async {
    try {
      await AwesomeNotifications().cancelSchedule(_diaryNotificationId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('diary_reminder_enabled', false);

      print('Daily diary reminder disabled');
    } catch (e) {
      print('Error disabling daily diary reminder: $e');
    }
  }

  Future<bool> isDailyReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('diary_reminder_enabled') ?? false;
    } catch (e) {
      print('Error checking if daily reminder is enabled: $e');
      return false;
    }
  }

  Future<String> getDailyReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('diary_reminder_time') ?? '20:00';
    } catch (e) {
      print('Error getting daily reminder time: $e');
      return '20:00';
    }
  }

  Future<bool> hasTodaysDiary() async {
    final today = DateTime.now();
    final diary = await _databaseService.getDiaryByDate(today);
    return diary != null;
  }

  Future<void> checkAndScheduleReminder() async {
    final isEnabled = await isDailyReminderEnabled();
    if (isEnabled) {
      final time = await getDailyReminderTime();
      await _scheduleDailyNotification(time);
    }
  }

  Future<void> restoreScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('diary_reminder_enabled') ?? false;

      if (isEnabled) {
        final time = prefs.getString('diary_reminder_time') ?? '20:00';
        await scheduleDailyDiaryReminder(time: time);
        print('Restored scheduled notifications');
      }
    } catch (e) {
      print('Error restoring scheduled notifications: $e');
    }
  }

  Future<bool> hasNotificationPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  Future<bool> requestNotificationPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<bool> ensureNotificationPermission() async {
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        isAllowed = await AwesomeNotifications()
            .requestPermissionToSendNotifications();
      }
      return isAllowed;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  Future<bool> _hasWrittenDiaryToday() async {
    try {
      final databaseService = DatabaseService();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final diaries = await databaseService.getDiariesByDateRange(
        startOfDay,
        endOfDay,
      );
      return diaries.isNotEmpty;
    } catch (e) {
      print('Error checking if diary written today: $e');
      return false;
    }
  }
}
