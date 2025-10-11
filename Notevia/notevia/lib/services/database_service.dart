import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/diary.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'notevia.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        plainTextContent TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isImportant INTEGER NOT NULL DEFAULT 0,
        isHidden INTEGER NOT NULL DEFAULT 0,
        customFilter TEXT,
        reminderDateTime TEXT,
        repeatReminder INTEGER NOT NULL DEFAULT 0,
        backgroundColor TEXT,
        audioFiles TEXT,
        tags TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE diaries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        plainTextContent TEXT,
        date INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        backgroundColor TEXT,
        audioFiles TEXT,
        reminderEnabled INTEGER NOT NULL DEFAULT 0,
        dailyReminderTime TEXT,
        UNIQUE(date)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE custom_filters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns to notes table
      await db.execute('ALTER TABLE notes ADD COLUMN plainTextContent TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT');
    }
    if (oldVersion < 3) {
      // Add plainTextContent column to diaries table
      await db.execute('ALTER TABLE diaries ADD COLUMN plainTextContent TEXT');
    }
    if (oldVersion < 4) {
      // Add reminder columns to diaries table
      await db.execute('ALTER TABLE diaries ADD COLUMN reminderEnabled INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE diaries ADD COLUMN dailyReminderTime TEXT');
    }
  }
  
  // Note operations
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }
  
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'updatedAt DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<List<Note>> getImportantNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'isImportant = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<List<Note>> getHiddenNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'isHidden = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<List<Note>> getUpcomingNotes() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'reminderDateTime IS NOT NULL AND reminderDateTime > ?',
      whereArgs: [now.toString()],
      orderBy: 'reminderDateTime ASC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<List<Note>> getNotesByFilter(String filter) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'customFilter = ?',
      whereArgs: [filter],
      orderBy: 'updatedAt DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }
  
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }
  
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> deleteMultipleNotes(List<int> ids) async {
    final db = await database;
    final batch = db.batch();
    for (int id in ids) {
      batch.delete('notes', where: 'id = ?', whereArgs: [id]);
    }
    final results = await batch.commit();
    return results.length;
  }
  
  // Diary operations
  Future<int> insertDiary(Diary diary) async {
    final db = await database;
    return await db.insert(
      'diaries',
      diary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Diary>> getAllDiaries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diaries',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Diary.fromMap(maps[i]));
  }
  
  Future<Diary?> getDiaryByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'diaries',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    
    if (maps.isNotEmpty) {
      return Diary.fromMap(maps.first);
    }
    return null;
  }
  
  Future<List<Diary>> getDiariesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diaries',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Diary.fromMap(maps[i]));
  }
  
  Future<int> updateDiary(Diary diary) async {
    final db = await database;
    return await db.update(
      'diaries',
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }
  
  Future<int> deleteDiary(int id) async {
    final db = await database;
    return await db.delete(
      'diaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Custom filter operations
  Future<int> insertCustomFilter(String name) async {
    final db = await database;
    return await db.insert('custom_filters', {
      'name': name,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<List<String>> getCustomFilters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_filters',
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }
  
  Future<int> deleteCustomFilter(String name) async {
    final db = await database;
    // Also remove the filter from all notes
    await db.update(
      'notes',
      {'customFilter': null},
      where: 'customFilter = ?',
      whereArgs: [name],
    );
    
    return await db.delete(
      'custom_filters',
      where: 'name = ?',
      whereArgs: [name],
    );
  }
  
  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('notes');
    await db.delete('diaries');
    await db.delete('custom_filters');
  }
  
  // Export data
  Future<Map<String, dynamic>> exportData() async {
    final notes = await getAllNotes();
    final diaries = await getAllDiaries();
    final filters = await getCustomFilters();
    
    return {
      'notes': notes.map((note) => note.toMap()).toList(),
      'diaries': diaries.map((diary) => diary.toMap()).toList(),
      'custom_filters': filters,
      'export_date': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  // Import data
  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    
    // Clear existing data
    await clearAllData();
    
    // Import notes
    if (data['notes'] != null) {
      for (var noteMap in data['notes']) {
        await db.insert('notes', noteMap);
      }
    }
    
    // Import diaries
    if (data['diaries'] != null) {
      for (var diaryMap in data['diaries']) {
        await db.insert('diaries', diaryMap);
      }
    }
    
    // Import custom filters
    if (data['custom_filters'] != null) {
      for (String filterName in data['custom_filters']) {
        await insertCustomFilter(filterName);
      }
    }
  }

  Future<List<Diary>> getDiaries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('diaries');
    return List.generate(maps.length, (i) {
      return Diary.fromMap(maps[i]);
    });
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }
}