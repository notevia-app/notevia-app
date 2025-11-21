import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:viflow/src/core/services/firebase_service.dart';
import 'package:viflow/src/core/services/notification_service.dart';
import 'package:viflow/src/core/services/auth_service.dart';

class AppProvider extends ChangeNotifier {
  double _currentWater = 0; double _targetWater = 2500;
  String _userName = ""; String _userId = ""; int _streak = 0; bool _isFirstTime = true;
  int _age = 25; double _weight = 70; double _height = 170; String _gender = 'male'; int _activityIndex = 1;
  Locale _locale = const Locale('en'); ThemeMode _themeMode = ThemeMode.system;
  bool _isReminderActive = false; int _startHour = 9; int _startMinute = 0; int _endHour = 22; int _endMinute = 0; int _frequencyMinutes = 45;
  List<Map<String, dynamic>> _todayLogs = [];
  String _motivationMessage = "Su hayattır.";

  // Getters
  double get currentWater => _currentWater; double get targetWater => _targetWater;
  String get userName => _userName; String get userId => _userId; int get streak => _streak;
  bool get isFirstTime => _isFirstTime; int get age => _age; double get weight => _weight;
  double get height => _height; String get gender => _gender; int get activityIndex => _activityIndex;
  Locale get locale => _locale; ThemeMode get themeMode => _themeMode;
  bool get isReminderActive => _isReminderActive; TimeOfDay get startTime => TimeOfDay(hour: _startHour, minute: _startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: _endHour, minute: _endMinute); int get frequencyMinutes => _frequencyMinutes;
  List<Map<String, dynamic>> get todayLogs => _todayLogs; String get motivationMessage => _motivationMessage;

  final List<String> _tips = [ "Harikasın!", "Baş ağrısının en büyük sebebi susuzluktur.", "Cildin için bir bardak daha.", "Su içmek metabolizmanı hızlandırır." ];

  double _calculateScientificGoal({required double weight, required String gender, required int activityIdx}) {
    double baseGoal = weight * 33; if (gender == 'male') baseGoal *= 1.05;
    double addon = 0; if (activityIdx == 1) addon = 350; if (activityIdx == 2) addon = 750;
    double totalGoal = baseGoal + addon; if (totalGoal < 1500) totalGoal = 1500; if (totalGoal > 4500) totalGoal = 4500;
    return (totalGoal / 10).round() * 10.0;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Auth Başlat (YENİ: Splash'te çağrılıyor ama burada veriyi alıyoruz)
    _userId = AuthService().userId ?? "";
    if (_userId.isEmpty) {
      // Yedek: İnternet yoksa yerelden al veya UUID
      _userId = prefs.getString('userId') ?? const Uuid().v4();
      // Auth servisiyle senkronize etmeye çalış
      if (AuthService().currentUser == null) await AuthService().signInAnonymously();
    }

    _userName = prefs.getString('userName') ?? "";
    _targetWater = prefs.getDouble('targetWater') ?? 2500;
    _isFirstTime = prefs.getBool('isFirstTime') ?? true;
    _age = prefs.getInt('age') ?? 25;
    _weight = prefs.getDouble('weight') ?? 70;
    _height = prefs.getDouble('height') ?? 170;
    _gender = prefs.getString('gender') ?? 'male';
    _activityIndex = prefs.getInt('activityIndex') ?? 1;

    String? langCode = prefs.getString('languageCode');
    if (langCode != null) _locale = Locale(langCode);
    else { final deviceLocale = ui.PlatformDispatcher.instance.locale.languageCode; _locale = deviceLocale == 'tr' ? const Locale('tr') : const Locale('en'); }

    int? themeIdx = prefs.getInt('themeMode');
    if (themeIdx != null) _themeMode = themeIdx == 1 ? ThemeMode.light : (themeIdx == 2 ? ThemeMode.dark : ThemeMode.system);

    _isReminderActive = prefs.getBool('isReminderActive') ?? false;
    _startHour = prefs.getInt('startHour') ?? 9; _startMinute = prefs.getInt('startMinute') ?? 0;
    _endHour = prefs.getInt('endHour') ?? 22; _endMinute = prefs.getInt('endMinute') ?? 0;
    _frequencyMinutes = prefs.getInt('frequencyMinutes') ?? 45;

    if (_isReminderActive) { if (await Permission.notification.isDenied) { _isReminderActive = false; await prefs.setBool('isReminderActive', false); } }

    _motivationMessage = _tips[Random().nextInt(_tips.length)];

    String savedDate = prefs.getString('savedDate') ?? "";
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (savedDate != today) {
      _currentWater = 0; _todayLogs = []; await prefs.setString('savedDate', today); await prefs.setDouble('currentWater', 0);
      String yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
      String lastStreakDate = prefs.getString('lastStreakUpdate') ?? "";
      if (lastStreakDate != yesterday) { _streak = 0; await prefs.setInt('streak', 0); try { await FirebaseService().updateStreak(_userId, 0); } catch (e) {} }
      else { try { _streak = await FirebaseService().getStreak(_userId); } catch (e) { _streak = prefs.getInt('streak') ?? 0; } }
    } else {
      try {
        _currentWater = await FirebaseService().getTodayWater(_userId);
        final logs = await FirebaseService().getTodayLogs(_userId);
        _todayLogs = List<Map<String, dynamic>>.from(logs);
        _streak = await FirebaseService().getStreak(_userId);
      } catch (e) { _currentWater = prefs.getDouble('currentWater') ?? 0; _streak = prefs.getInt('streak') ?? 0; }
    }
    notifyListeners();
  }

  Future<void> completeOnboarding({required String name, required int age, required double weight, required double height, required String gender, required int activityIdx}) async {
    final prefs = await SharedPreferences.getInstance();
    double calculatedTarget = _calculateScientificGoal(weight: weight, gender: gender, activityIdx: activityIdx);
    _userName = name; _targetWater = calculatedTarget; _age = age; _weight = weight; _height = height; _gender = gender; _activityIndex = activityIdx; _isFirstTime = false;
    await prefs.setString('userName', name); await prefs.setDouble('targetWater', calculatedTarget); await prefs.setInt('age', age); await prefs.setDouble('weight', weight); await prefs.setDouble('height', height); await prefs.setString('gender', gender); await prefs.setInt('activityIndex', activityIdx); await prefs.setBool('isFirstTime', false);
    if (_userId.isNotEmpty) await FirebaseService().saveUserData(userId: _userId, name: name, age: age, weight: weight, height: height, gender: gender, activityIndex: activityIdx, dailyGoal: calculatedTarget);
    notifyListeners();
  }

  Future<void> updateUserProfile({required String name, required int age, required double weight, required double height, required String gender, required int activityIdx}) async {
    final prefs = await SharedPreferences.getInstance();
    double newTarget = _calculateScientificGoal(weight: weight, gender: gender, activityIdx: activityIdx);
    _userName = name; _age = age; _weight = weight; _height = height; _gender = gender; _activityIndex = activityIdx; _targetWater = newTarget;
    await prefs.setString('userName', name); await prefs.setInt('age', age); await prefs.setDouble('weight', weight); await prefs.setDouble('height', height); await prefs.setString('gender', gender); await prefs.setInt('activityIndex', activityIdx); await prefs.setDouble('targetWater', newTarget);
    if (_userId.isNotEmpty) await FirebaseService().saveUserData(userId: _userId, name: name, age: age, weight: weight, height: height, gender: gender, activityIndex: activityIdx, dailyGoal: newTarget);
    notifyListeners();
  }

  Future<void> addWater(double amount) async {
    _currentWater += amount; if (_currentWater < 0) _currentWater = 0;
    if (amount > 0) { _todayLogs.insert(0, <String, dynamic>{'amount': amount, 'timestamp': DateTime.now()}); }
    else { if (_todayLogs.isNotEmpty) _todayLogs.removeAt(0); }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance(); await prefs.setDouble('currentWater', _currentWater);
    try { await FirebaseService().addWaterLog(_userId, amount); } catch (e) { debugPrint("Firebase Hatası: $e"); }
    _checkAndUpdateStreak(prefs);
  }

  Future<void> _checkAndUpdateStreak(SharedPreferences prefs) async {
    String lastStreakDate = prefs.getString('lastStreakUpdate') ?? ""; String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_currentWater >= _targetWater && lastStreakDate != today) { _streak++; await prefs.setString('lastStreakUpdate', today); await prefs.setInt('streak', _streak); try { await FirebaseService().updateStreak(_userId, _streak); } catch (e) {} notifyListeners(); }
  }

  Future<bool> toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) { bool granted = await NotificationService().requestPermissions(); if (!granted) return false; await _scheduleNotifications(); }
    else { await NotificationService().cancelAllNotifications(); }
    _isReminderActive = value; await prefs.setBool('isReminderActive', value); notifyListeners(); return true;
  }

  Future<void> updateReminderSettings({TimeOfDay? start, TimeOfDay? end, int? freq}) async {
    final prefs = await SharedPreferences.getInstance();
    if (start != null) { _startHour = start.hour; _startMinute = start.minute; }
    if (end != null) { _endHour = end.hour; _endMinute = end.minute; }
    if (freq != null) { _frequencyMinutes = freq; }
    await prefs.setInt('startHour', _startHour); await prefs.setInt('startMinute', _startMinute); await prefs.setInt('endHour', _endHour); await prefs.setInt('endMinute', _endMinute); await prefs.setInt('frequencyMinutes', _frequencyMinutes);
    if (_isReminderActive) { await _scheduleNotifications(); } notifyListeners();
  }

  Future<void> _scheduleNotifications() async {
    await NotificationService().scheduleDailyNotifications(startTime: TimeOfDay(hour: _startHour, minute: _startMinute), endTime: TimeOfDay(hour: _endHour, minute: _endMinute), intervalMinutes: _frequencyMinutes, title: "Viflow", body: "Su içme zamanı! 💧");
  }

  Future<void> setLocale(Locale locale) async { if (_locale == locale) return; _locale = locale; final prefs = await SharedPreferences.getInstance(); await prefs.setString('languageCode', locale.languageCode); notifyListeners(); }
  Future<void> setThemeMode(ThemeMode mode) async { if (_themeMode == mode) return; _themeMode = mode; final prefs = await SharedPreferences.getInstance(); int val = 0; if (mode == ThemeMode.light) val = 1; if (mode == ThemeMode.dark) val = 2; await prefs.setInt('themeMode', val); notifyListeners(); }
  Future<void> updateTarget(double newTarget) async { _targetWater = newTarget; final prefs = await SharedPreferences.getInstance(); await prefs.setDouble('targetWater', newTarget); notifyListeners(); }

  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    String oldUserId = _userId;
    await prefs.clear(); await NotificationService().cancelAllNotifications(); await AuthService().signOut();
    if (oldUserId.isNotEmpty) await FirebaseService().deleteUserHistory(oldUserId);
    _currentWater = 0; _targetWater = 2500; _userName = ""; _isFirstTime = true; _streak = 0; _todayLogs = []; _age = 25; _weight = 70; _height = 170; _gender = 'male'; _activityIndex = 1; _isReminderActive = false; _userId = "";
    notifyListeners();
  }
}