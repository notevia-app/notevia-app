import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/note.dart';
import '../models/diary.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  drive.DriveApi? _driveApi;
  final DatabaseService _databaseService = DatabaseService();

  Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final client = GoogleAuthClient(auth.accessToken!);
        _driveApi = drive.DriveApi(client);
        return true;
      }
      return false;
    } catch (e) {
      print('Google Sign In Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<bool> uploadBackup(Map<String, dynamic> backupData) async {
    try {
      if (_driveApi == null) {
        final signedIn = await signIn();
        if (!signedIn) return false;
      }

      // Create file name with current date and time
      final now = DateTime.now();
      final fileName = 'notevia_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.backup';
      
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonEncode(backupData));

      // Upload to Google Drive
      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']; // Store in app data folder

      final media = drive.Media(tempFile.openRead(), tempFile.lengthSync());
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      // Clean up temporary file
      await tempFile.delete();

      return uploadedFile.id != null;
    } catch (e) {
      print('Upload Error: $e');
      return false;
    }
  }

  Future<List<drive.File>> listBackups() async {
    try {
      if (_driveApi == null) {
        final signedIn = await signIn();
        if (!signedIn) return [];
      }

      final fileList = await _driveApi!.files.list(
        q: "parents in 'appDataFolder' and name contains 'notevia_' and name contains '.backup'",
        orderBy: 'createdTime desc',
      );

      return fileList.files ?? [];
    } catch (e) {
      print('List Backups Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> downloadBackup(String fileId) async {
    try {
      if (_driveApi == null) {
        final signedIn = await signIn();
        if (!signedIn) return null;
      }

      // Download file from Google Drive
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      final jsonString = utf8.decode(dataStore);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Download Error: $e');
      return null;
    }
  }

  Future<String?> exportDataToDrive() async {
    try {
      if (_driveApi == null) {
        final signedIn = await signIn();
        if (!signedIn) return null;
      }

      // Get all data
      final notes = await _databaseService.getAllNotes();
      final diaries = await _databaseService.getAllDiaries();
      final prefs = await SharedPreferences.getInstance();
      
      // Create backup data
      final backupData = {
        'notes': notes.map((note) => {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'createdAt': note.createdAt.toIso8601String(),
          'updatedAt': note.updatedAt.toIso8601String(),
          'isHidden': note.isHidden,
          'reminderDateTime': note.reminderDateTime,
          'repeatReminder': note.repeatReminder,
        }).toList(),
        'diaries': diaries.map((diary) => {
          'id': diary.id,
          'content': diary.content,
          'date': diary.date.toIso8601String(),
          'createdAt': diary.createdAt.toIso8601String(),
          'updatedAt': diary.updatedAt.toIso8601String(),
        }).toList(),
        'settings': {
          'language': prefs.getString('language'),
          'theme_mode': prefs.getString('theme_mode'),
          'user_name': prefs.getString('user_name'),
          'daily_reminder_enabled': prefs.getBool('daily_reminder_enabled'),
          'diary_reminder_time': prefs.getString('diary_reminder_time'),
          'require_pin_for_hidden_notes': prefs.getBool('require_pin_for_hidden_notes'),
          'require_pin_for_diary': prefs.getBool('require_pin_for_diary'),
          'gemini_api_key': prefs.getString('gemini_api_key'),
        },
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      // Create file name with current date and time
      final now = DateTime.now();
      final fileName = 'notevia_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.backup';
      
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonEncode(backupData));

      // Upload to Google Drive
      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']; // Store in app data folder

      final media = drive.Media(tempFile.openRead(), tempFile.lengthSync());
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      // Clean up temporary file
      await tempFile.delete();

      return uploadedFile.id;
    } catch (e) {
      print('Export Error: $e');
      return null;
    }
  }



  Future<bool> importDataFromDrive(String fileId) async {
    try {
      if (_driveApi == null) {
        final signedIn = await signIn();
        if (!signedIn) return false;
      }

      // Download file from Google Drive
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      final jsonString = utf8.decode(dataStore);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import notes
      if (backupData['notes'] != null) {
        final notes = backupData['notes'] as List;
        for (final noteData in notes) {
          // Check if note already exists
          final existingNote = await _databaseService.getNoteById(noteData['id']);
          if (existingNote == null) {
            final newNote = Note(
               title: noteData['title'] ?? '',
               content: noteData['content'] ?? '',
               plainTextContent: noteData['plainTextContent'],
               createdAt: noteData['createdAt'] != null ? DateTime.parse(noteData['createdAt']) : DateTime.now(),
               updatedAt: noteData['updatedAt'] != null ? DateTime.parse(noteData['updatedAt']) : DateTime.now(),
               isImportant: noteData['isImportant'] == true || noteData['isImportant'] == 1,
               isHidden: noteData['isHidden'] == true || noteData['isHidden'] == 1,
               reminderDateTime: noteData['reminderDateTime'],
               repeatReminder: noteData['repeatReminder'] == true || noteData['repeatReminder'] == 1,
               tags: noteData['tags'] is String ? (noteData['tags'] as String).split(',').where((tag) => tag.isNotEmpty).toList() : (noteData['tags'] as List?)?.cast<String>() ?? [],
             );
            await _databaseService.insertNote(newNote);
          }
        }
      }

      // Import diaries
      if (backupData['diaries'] != null) {
        final diaries = backupData['diaries'] as List;
        for (final diaryData in diaries) {
          // Check if diary already exists for this date
          final existingDiary = await _databaseService.getDiaryByDate(
            DateTime.parse(diaryData['date']),
          );
          if (existingDiary == null) {
            final newDiary = Diary(
               title: diaryData['title'] ?? '',
               content: diaryData['content'] ?? '',
               date: diaryData['date'] != null ? DateTime.parse(diaryData['date']) : DateTime.now(),
               createdAt: diaryData['createdAt'] != null ? DateTime.parse(diaryData['createdAt']) : DateTime.now(),
               updatedAt: diaryData['updatedAt'] != null ? DateTime.parse(diaryData['updatedAt']) : DateTime.now(),
               backgroundColor: diaryData['backgroundColor'],
             );
            await _databaseService.insertDiary(newDiary);
          }
        }
      }

      // Import settings
      if (backupData['settings'] != null) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        
        for (final entry in settings.entries) {
          if (entry.value != null) {
            if (entry.value is String) {
              await prefs.setString(entry.key, entry.value);
            } else if (entry.value is bool) {
              await prefs.setBool(entry.key, entry.value);
            } else if (entry.value is int) {
              await prefs.setInt(entry.key, entry.value);
            } else if (entry.value is double) {
              await prefs.setDouble(entry.key, entry.value);
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('Import Error: $e');
      return false;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}