import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcı Profilini Kaydet
  Future<void> saveUserData({
    required String userId, required String name, required int age,
    required double weight, required double height, required String gender,
    required int activityIndex, required double dailyGoal,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name, 'age': age, 'weight': weight, 'height': height,
        'gender': gender, 'activityIndex': activityIndex, 'dailyGoal': dailyGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) { print("Kullanıcı kaydetme hatası: $e"); }
  }

  /// Kullanıcı Verilerini Sil (Reset)
  Future<void> deleteUserHistory(String userId) async {
    if (userId.isEmpty) return;
    final userRef = _firestore.collection('users').doc(userId);
    try {
      QuerySnapshot stats = await userRef.collection('daily_stats').get();
      for (QueryDocumentSnapshot doc in stats.docs) {
        QuerySnapshot logs = await doc.reference.collection('logs').get();
        for (QueryDocumentSnapshot log in logs.docs) { await log.reference.delete(); }
        await doc.reference.delete();
      }
      await userRef.delete();
    } catch (e) { print("Silme hatası: $e"); }
  }

  // --- Su Takibi ---
  Future<void> addWaterLog(String userId, double amount) async {
    if (userId.isEmpty) return;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentReference dayRef = _firestore.collection('users').doc(userId).collection('daily_stats').doc(today);
    await dayRef.set({'amount': FieldValue.increment(amount), 'date': Timestamp.now()}, SetOptions(merge: true));
    if (amount > 0) { await dayRef.collection('logs').add({'amount': amount, 'timestamp': Timestamp.now()}); }
  }

  Future<List<Map<String, dynamic>>> getTodayLogs(String userId) async {
    if (userId.isEmpty) return [];
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').doc(userId).collection('daily_stats').doc(today).collection('logs').orderBy('timestamp', descending: true).get();
      return snapshot.docs.map((doc) => {'amount': (doc['amount'] as num).toDouble(), 'timestamp': (doc['timestamp'] as Timestamp).toDate()}).toList();
    } catch (e) { return []; }
  }

  Future<double> getTodayWater(String userId) async {
    if (userId.isEmpty) return 0.0;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).collection('daily_stats').doc(today).get();
      if (doc.exists && doc.data() != null) return (doc.data() as Map<String, dynamic>)['amount']?.toDouble() ?? 0.0;
      return 0.0;
    } catch (e) { return 0.0; }
  }

  // --- Streak & İstatistikler ---
  Future<int> getStreak(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) return (doc.data() as Map<String, dynamic>)['streak'] ?? 0;
      return 0;
    } catch (e) { return 0; }
  }

  Future<void> updateStreak(String userId, int newStreak) async {
    if (userId.isEmpty) return;
    await _firestore.collection('users').doc(userId).set({'streak': newStreak, 'lastStreakDate': DateFormat('yyyy-MM-dd').format(DateTime.now())}, SetOptions(merge: true));
  }

  Future<Map<DateTime, int>> getHeatmapData(String userId) async {
    if (userId.isEmpty) return {};
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(const Duration(days: 90));
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').doc(userId).collection('daily_stats').where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate)).get();
      Map<DateTime, int> heatmapData = {};
      for (var doc in snapshot.docs) {
        DateTime date = (doc['date'] as Timestamp).toDate();
        DateTime cleanDate = DateTime(date.year, date.month, date.day);
        heatmapData[cleanDate] = (doc['amount'] as num).toInt();
      }
      return heatmapData;
    } catch (e) { return {}; }
  }

  Future<List<DateTime>> getLast7DaysLogTimes(String userId) async {
    if (userId.isEmpty) return [];
    DateTime now = DateTime.now();
    List<DateTime> timeLogs = [];
    for (int i = 0; i <= 7; i++) {
      DateTime day = now.subtract(Duration(days: i));
      String dayKey = DateFormat('yyyy-MM-dd').format(day);
      try {
        QuerySnapshot logSnap = await _firestore.collection('users').doc(userId).collection('daily_stats').doc(dayKey).collection('logs').get();
        for (var doc in logSnap.docs) timeLogs.add((doc['timestamp'] as Timestamp).toDate());
      } catch (e) { continue; }
    }
    return timeLogs;
  }

  Future<List<Map<String, dynamic>>> getWeeklyData(String userId) async {
    if (userId.isEmpty) return List.generate(7, (index) => {'label': '-', 'val': 0.0});
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 6));
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').doc(userId).collection('daily_stats').where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo)).orderBy('date').get();
      Map<String, double> rawData = {};
      for (var doc in snapshot.docs) { rawData[doc.id] = (doc.data() as Map<String, dynamic>)['amount']?.toDouble() ?? 0; }
      List<Map<String, dynamic>> formattedList = [];
      for (int i = 6; i >= 0; i--) {
        DateTime day = now.subtract(Duration(days: i));
        String dayKey = DateFormat('yyyy-MM-dd').format(day);
        String label = DateFormat('E', 'tr').format(day); // Default TR, UI'da ezilecek
        formattedList.add({'label': label, 'val': rawData[dayKey] ?? 0.0});
      }
      return formattedList;
    } catch (e) { return List.generate(7, (index) => {'label': '-', 'val': 0.0}); }
  }
}