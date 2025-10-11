import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../models/color_palette.dart';
import '../services/database_service.dart';
import '../services/google_drive_service.dart';
import '../services/diary_notification_service.dart';
import '../models/note.dart';
import '../models/diary.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pin_input_dialog.dart';
import '../widgets/modern_popup.dart';
import '../main.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isPinEnabled = false;
  String _currentLanguage = 'tr';
  String? _geminiApiKey;
  bool _isDailyReminderEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPinEnabled = prefs.getBool('pin_enabled') ?? false;
      _currentLanguage = prefs.getString('language') ?? 'tr';
      _geminiApiKey = prefs.getString('gemini_api_key');
      _isDailyReminderEnabled =
          prefs.getBool('daily_reminder_enabled') ?? false;
      _userName = prefs.getString('user_name') ?? '';

      final hour = prefs.getInt('daily_reminder_hour') ?? 20;
      final minute = prefs.getInt('daily_reminder_minute') ?? 0;
      _dailyReminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _setPinCode() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PinInputDialog(
        title: AppLocalizations.of(context)!.setPinCode,
        onPinEntered: (pin) {
          Navigator.of(context).pop(pin);
        },
        isSetup: true,
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pin_code', result);
      await prefs.setBool('pin_enabled', true);
      setState(() {
        _isPinEnabled = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pinCodeSet),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _changePinCode() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPin = prefs.getString('pin_code');

    if (currentPin == null) return;

    // First verify current PIN
    final currentPinInput = await showDialog<String>(
      context: context,
      builder: (context) => PinInputDialog(
        title: AppLocalizations.of(context)!.enterPinCode,
        onPinEntered: (pin) {
          Navigator.of(context).pop(pin);
        },
      ),
    );

    if (currentPinInput != currentPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.wrongPinCode),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Set new PIN
    final newPin = await showDialog<String>(
      context: context,
      builder: (context) => PinInputDialog(
        title: AppLocalizations.of(context)!.changePinCode,
        onPinEntered: (pin) {
          Navigator.of(context).pop(pin);
        },
      ),
    );

    if (newPin != null) {
      await prefs.setString('pin_code', newPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pinCodeChanged),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removePinCode() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPin = prefs.getString('pin_code');

    if (currentPin == null) return;

    // Verify current PIN
    final currentPinInput = await showDialog<String>(
      context: context,
      builder: (context) => PinInputDialog(
        title: AppLocalizations.of(context)!.enterPinCode,
        onPinEntered: (pin) {
          Navigator.of(context).pop(pin);
        },
      ),
    );

    if (currentPinInput != currentPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.wrongPinCode),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await prefs.remove('pin_code');
    await prefs.setBool('pin_enabled', false);
    setState(() {
      _isPinEnabled = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pinCodeRemoved),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _setLanguage(String languageCode) async {
    // Store the previous language code before updating
    final previousLanguage = _currentLanguage;

    // Save the new language preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);

    // Update the state with the new language
    setState(() {
      _currentLanguage = languageCode;
    });

    // Update the main app language
    NoteviaApp.changeAppLanguage(languageCode);

    // Show a message after the language change
    if (mounted) {
      // Wait longer for the language change to take effect (1 second)
      Future.delayed(Duration(milliseconds: 1), () {
        if (!mounted) return;

        // Prepare the message in the new language
        // Use hardcoded messages for each language to ensure correct display
        String message;

        // Use the new language code for the message
        switch (languageCode) {
          case 'en':
            message = 'Language changed to: English';
            break;
          case 'de':
            message = 'Sprache geändert zu: Deutsch';
            break;
          case 'fr':
            message = 'Langue changée en: Français';
            break;
          case 'es':
            message = 'Idioma cambiado a: Español';
            break;
          case 'tr':
            message = 'Dil değiştirildi: Türkçe';
            break;
          default:
            message =
                '${AppLocalizations.of(context)!.languageChangedTo}: ${_getLanguageName(languageCode)}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      });
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'tr':
        return AppLocalizations.of(context)!.turkish;
      case 'en':
        return AppLocalizations.of(context)!.english;
      case 'de':
        return AppLocalizations.of(context)!.german;
      case 'fr':
        return AppLocalizations.of(context)!.french;
      case 'es':
        return AppLocalizations.of(context)!.spanish;
      default:
        return AppLocalizations.of(context)!.english;
    }
  }

  // Returns the language name in its own language
  String _getLanguageNameInLanguage(String code, String languageCode) {
    switch (code) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      default:
        return 'English';
    }
  }

  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return _currentLanguage == 'tr'
            ? 'Sistem Varsayılanı'
            : 'System Default';
      case ThemeMode.light:
        return AppLocalizations.of(context)!.lightTheme;
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.darkTheme;
    }
  }

  Future<void> _setGeminiApiKey() async {
    final controller = TextEditingController(text: _geminiApiKey ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => ModernPopup(
        title: AppLocalizations.of(context)!.setApiKey,
        icon: Icons.key,
        content: ModernTextField(
          controller: controller,
          labelText: AppLocalizations.of(context)!.geminiApiKey,
          hintText: 'AIzaSy...',
          obscureText: true,
          prefixIcon: Icons.vpn_key,
        ),
        actions: [
          ModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
          ),
          ModernButton(
            text: AppLocalizations.of(context)!.save,
            isPrimary: true,
            icon: Icons.save,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', result);
      setState(() {
        _geminiApiKey = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.apiKeySet),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final notes = await _databaseService.getAllNotes();
      final diaries = await _databaseService.getAllDiaries();

      // Ayarları al (kullanıcı adı ve PIN hariç)
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'language': prefs.getString('language') ?? 'tr',
        'daily_reminder_enabled':
            prefs.getBool('daily_reminder_enabled') ?? false,
        'daily_reminder_hour': prefs.getInt('daily_reminder_hour') ?? 20,
        'daily_reminder_minute': prefs.getInt('daily_reminder_minute') ?? 0,
        'gemini_api_key': prefs.getString('gemini_api_key'),
        'theme_mode': prefs.getBool('dark_mode') ?? false,
        'color_palette_index': prefs.getInt('selected_palette_index') ?? 0,
      };

      final exportData = {
        'notes': notes.map((note) => note.toMap()).toList(),
        'diaries': diaries.map((diary) => diary.toMap()).toList(),
        'settings': settings,
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      };

      final jsonString = jsonEncode(exportData);

      // Dosya adını istenen formatta oluştur
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'Notevia_${formatter.format(now)}.json';

      // Android için Downloads klasörüne kaydet
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.fileSaved}: ${directory.path}/$fileName',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.saveLocationNotFound);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: AppLocalizations.of(context)!.importData,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        int importedNotesCount = 0;
        int importedDiariesCount = 0;

        // Import notes
        if (data['notes'] != null) {
          final notesList = data['notes'] as List;
          // Mevcut notları bir kez al
          final existingNotes = await _databaseService.getAllNotes();

          for (final noteData in notesList) {
            // Check if note already exists
            final exists = existingNotes.any(
              (note) =>
                  note.title == (noteData['title'] ?? '') &&
                  note.content == (noteData['content'] ?? ''),
            );

            if (!exists) {
              final newNote = Note(
                title: noteData['title'] ?? '',
                content: noteData['content'] ?? '',
                plainTextContent:
                    noteData['plain_text_content'] ?? noteData['content'] ?? '',
                createdAt: noteData['created_at'] != null
                    ? DateTime.parse(noteData['created_at'])
                    : DateTime.now(),
                updatedAt: noteData['updated_at'] != null
                    ? DateTime.parse(noteData['updated_at'])
                    : DateTime.now(),
                isImportant:
                    noteData['is_important'] == true ||
                    noteData['is_important'] == 1,
                isHidden:
                    noteData['is_hidden'] == true || noteData['is_hidden'] == 1,
                tags: noteData['tags'] is String
                    ? (noteData['tags'] as String)
                          .split(',')
                          .where((tag) => tag.isNotEmpty)
                          .toList()
                    : (noteData['tags'] as List?)?.cast<String>() ?? [],
                reminderDateTime: noteData['reminder_date_time'],
                repeatReminder:
                    noteData['repeat_reminder'] == true ||
                    noteData['repeat_reminder'] == 1,
              );
              await _databaseService.insertNote(newNote);
              importedNotesCount++;
            }
          }
        }

        // Import diaries
        if (data['diaries'] != null) {
          final diariesList = data['diaries'] as List;
          // Mevcut günlükleri bir kez al
          final existingDiaries = await _databaseService.getAllDiaries();

          for (final diaryData in diariesList) {
            // Check if diary already exists
            final exists = existingDiaries.any(
              (diary) =>
                  diary.title == (diaryData['title'] ?? '') &&
                  diary.date.toString().substring(0, 10) ==
                      (diaryData['date'] ?? '').substring(0, 10),
            );

            if (!exists) {
              final newDiary = Diary(
                title: diaryData['title'] ?? '',
                content: diaryData['content'] ?? '',
                plainTextContent:
                    diaryData['plain_text_content'] ??
                    diaryData['content'] ??
                    '',
                date: diaryData['date'] != null
                    ? DateTime.parse(diaryData['date'])
                    : DateTime.now(),
                createdAt: diaryData['created_at'] != null
                    ? DateTime.parse(diaryData['created_at'])
                    : DateTime.now(),
                updatedAt: diaryData['updated_at'] != null
                    ? DateTime.parse(diaryData['updated_at'])
                    : DateTime.now(),
                backgroundColor: diaryData['background_color'] != null
                    ? (diaryData['background_color'] is String
                          ? int.parse(
                              (diaryData['background_color'] as String)
                                  .replaceAll('#', '0xFF'),
                            )
                          : diaryData['background_color'] as int)
                    : 0xFFFFFFFF,
              );
              await _databaseService.insertDiary(newDiary);
              importedDiariesCount++;
            }
          }
        }

        // Import settings (kullanıcı adı ve PIN hariç)
        if (data['settings'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final settings = data['settings'];

          if (settings['language'] != null) {
            await prefs.setString('language', settings['language']);
          }
          if (settings['daily_reminder_enabled'] != null) {
            await prefs.setBool(
              'daily_reminder_enabled',
              settings['daily_reminder_enabled'],
            );
          }
          if (settings['daily_reminder_hour'] != null) {
            await prefs.setInt(
              'daily_reminder_hour',
              settings['daily_reminder_hour'],
            );
          }
          if (settings['daily_reminder_minute'] != null) {
            await prefs.setInt(
              'daily_reminder_minute',
              settings['daily_reminder_minute'],
            );
          }
          if (settings['gemini_api_key'] != null) {
            await prefs.setString('gemini_api_key', settings['gemini_api_key']);
          }
          if (settings['theme_mode'] != null) {
            await prefs.setBool('dark_mode', settings['theme_mode']);
          }
          if (settings['color_palette_index'] != null) {
            await prefs.setInt(
              'selected_palette_index',
              settings['color_palette_index'],
            );
          }

          // Ayarları yeniden yükle
          await _loadSettings();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.importCompleted}: $importedNotesCount ${AppLocalizations.of(context)!.notes}, $importedDiariesCount ${AppLocalizations.of(context)!.diaries}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.importError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ModernPopup(
        title: AppLocalizations.of(context)!.clearAllData,
        icon: Icons.warning,
        iconColor: Colors.orange,
        content: Text(
          AppLocalizations.of(context)!.clearAllDataConfirm,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          ModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          ModernButton(
            text: AppLocalizations.of(context)!.delete,
            isDestructive: true,
            icon: Icons.delete_forever,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Veritabanındaki tüm verileri sil
        await _databaseService.clearAllData();

        // SharedPreferences'taki tüm ayarları sil
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Bildirim servisini durdur
        final notificationService = DiaryNotificationService();
        await notificationService.disableDailyDiaryReminder();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.allDataDeleted),
              backgroundColor: Colors.green,
            ),
          );

          // Kısa bir gecikme sonrası uygulamayı yeniden başlat
          await Future.delayed(const Duration(seconds: 2));

          // Ana sayfaya git ve tüm geçmişi temizle
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeUserName() async {
    final controller = TextEditingController(text: _userName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => ModernPopup(
        title: AppLocalizations.of(context)!.changeUsername,
        icon: Icons.person,
        content: ModernTextField(
          controller: controller,
          labelText: AppLocalizations.of(context)!.userName,
          hintText: AppLocalizations.of(context)!.enterYourName,
          maxLength: 30,
          prefixIcon: Icons.account_circle,
        ),
        actions: [
          ModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
          ),
          ModernButton(
            text: AppLocalizations.of(context)!.save,
            isPrimary: true,
            icon: Icons.save,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // UserProvider kullanarak kullanıcı adını güncelle
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUserName(result);
      
      setState(() {
        _userName = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userNameChanged),
            backgroundColor: Colors.green,
          ),
        );
        
        // UserProvider otomatik olarak tüm widget'ları günceller
      }
    }
  }

  Future<void> _toggleDailyReminder(bool enabled) async {
    if (enabled) {
      // Check notification permission before enabling
      final hasPermission = await DiaryNotificationService().ensureNotificationPermission();
      if (!hasPermission) {
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bildirim izni gerekli. Lütfen ayarlardan bildirim iznini açın.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', enabled);

    if (enabled) {
      await DiaryNotificationService().scheduleDailyDiaryReminder(
        time:
            '${_dailyReminderTime.hour.toString().padLeft(2, '0')}:${_dailyReminderTime.minute.toString().padLeft(2, '0')}',
      );
    } else {
      await DiaryNotificationService().disableDailyDiaryReminder();
    }

    setState(() {
      _isDailyReminderEnabled = enabled;
    });
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dailyReminderTime,
    );

    if (picked != null && picked != _dailyReminderTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_reminder_hour', picked.hour);
      await prefs.setInt('daily_reminder_minute', picked.minute);

      setState(() {
        _dailyReminderTime = picked;
      });

      // Reschedule notification with new time
      if (_isDailyReminderEnabled) {
        await DiaryNotificationService().scheduleDailyDiaryReminder(
          time:
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
        );
      }
    }
  }

  Future<void> _showPinDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PinInputDialog(
        title: AppLocalizations.of(context)!.setPinCode,
        onPinEntered: (pin) {
          Navigator.of(context).pop(pin);
        },
        isSetup: true,
      ),
    );

    if (result != null && result.length >= 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pin_code', result);
      setState(() {
        _isPinEnabled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pinCodeSet)),
      );
    }
  }

  Future<void> _changeLanguage() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ModernPopup(
        title: AppLocalizations.of(context)!.selectLanguage,
        icon: Icons.language,
        showCloseButton: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernRadioListTile<String>(
              title: 'Türkçe',
              value: 'tr',
              groupValue: _currentLanguage,
              flagEmoji: '🇹🇷',
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            ModernRadioListTile<String>(
              title: 'English',
              value: 'en',
              groupValue: _currentLanguage,
              flagEmoji: '🇺🇸',
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            ModernRadioListTile<String>(
              title: 'Deutsch',
              value: 'de',
              groupValue: _currentLanguage,
              flagEmoji: '🇩🇪',
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            ModernRadioListTile<String>(
              title: 'Français',
              value: 'fr',
              groupValue: _currentLanguage,
              flagEmoji: '🇫🇷',
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
            ModernRadioListTile<String>(
              title: 'Español',
              value: 'es',
              groupValue: _currentLanguage,
              flagEmoji: '🇪🇸',
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        ),
        actions: [
          ModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    if (result != null && result != _currentLanguage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', result);

      setState(() {
        _currentLanguage = result;
      });

      // Update the main app language
      NoteviaApp.changeAppLanguage(result);

      if (mounted) {
        // Wait longer for the language change to take effect (1 second)
        Future.delayed(Duration(milliseconds: 1000), () {
          if (!mounted) return;

          // Use hardcoded messages for each language to ensure correct display
          String message;
          switch (result) {
            case 'en':
              message = 'Language changed to: English';
              break;
            case 'de':
              message = 'Sprache geändert zu: Deutsch';
              break;
            case 'fr':
              message = 'Langue changée en: Français';
              break;
            case 'es':
              message = 'Idioma cambiado a: Español';
              break;
            case 'tr':
              message = 'Dil değiştirildi: Türkçe';
              break;
            default:
              message =
                  '${AppLocalizations.of(context)!.languageChangedTo}: ${_getLanguageName(result)}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kişiselleştirme Grubu
            _buildSectionCard(
              title: AppLocalizations.of(context)!.personalization,
              icon: Icons.person_outline,
              color: Colors.blue,
              children: [
                _buildModernListTile(
                  icon: Icons.account_circle,
                  title: AppLocalizations.of(context)!.userName,
                  subtitle: _userName,
                  onTap: _changeUserName,
                ),
                _buildModernListTile(
                  icon: Icons.security,
                  title: AppLocalizations.of(context)!.changePinCode,
                  subtitle: AppLocalizations.of(context)!.changePinCodeSubtitle,
                  onTap: () => _showPinDialog(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Görünüm Grubu
            _buildSectionCard(
              title: AppLocalizations.of(context)!.appearance,
              icon: Icons.palette_outlined,
              color: Colors.purple,
              children: [
                _buildModernListTile(
                  icon: Icons.brightness_6_outlined,
                  title: AppLocalizations.of(context)!.theme,
                  subtitle: _getThemeModeName(themeProvider.themeMode),
                  onTap: () => _showThemeDialog(themeProvider),
                ),
                _buildModernListTile(
                  icon: Icons.color_lens_outlined,
                  title: AppLocalizations.of(context)!.colorPalette,
                  subtitle: _getColorPaletteName(
                    themeProvider.selectedPaletteIndex,
                  ),
                  onTap: () => _showColorPaletteDialog(themeProvider),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Ek Ayarlar Grubu
            _buildSectionCard(
              title: AppLocalizations.of(context)!.additionalSettings,
              icon: Icons.settings_outlined,
              color: Colors.orange,
              children: [
                _buildModernListTile(
                  icon: Icons.language_outlined,
                  title: AppLocalizations.of(context)!.language,
                  subtitle: _getLanguageName(_currentLanguage),
                  onTap: _changeLanguage,
                ),
                // Google Drive backup özelliği geçici olarak gizlendi
                // _buildModernListTile(
                //   icon: Icons.cloud_upload_outlined,
                //   title: _getExportDataText(),
                //   subtitle: _getExportDataSubtitle(),
                //   onTap: _exportDataToDrive,
                // ),
                // _buildModernListTile(
                //   icon: Icons.cloud_download_outlined,
                //   title: _getImportDataText(),
                //   subtitle: _getImportDataSubtitle(),
                //   onTap: _importDataFromDrive,
                // ),
              ],
            ),

            const SizedBox(height: 20),

            // Tehlikeli Bölge Grubu
            _buildSectionCard(
              title: AppLocalizations.of(context)!.dangerZone,
              icon: Icons.warning_outlined,
              color: Colors.red,
              children: [
                _buildModernListTile(
                  icon: Icons.delete_forever_outlined,
                  title: AppLocalizations.of(context)!.clearAllData,
                  subtitle: AppLocalizations.of(context)!.clearAllDataConfirm,
                  onTap: _clearAllData,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Theme.of(context).textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              )
            : null,
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => ModernPopup(
        title: AppLocalizations.of(context)!.themeSelection,
        icon: Icons.palette,
        showCloseButton: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernRadioListTile<ThemeMode>(
              title: _currentLanguage == 'tr'
                  ? 'Sistem Varsayılanı'
                  : 'System Default',
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              icon: Icons.settings_system_daydream,
              onChanged: (value) {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ModernRadioListTile<ThemeMode>(
              title: AppLocalizations.of(context)!.lightTheme,
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              icon: Icons.light_mode,
              onChanged: (value) {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ModernRadioListTile<ThemeMode>(
              title: AppLocalizations.of(context)!.darkTheme,
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              icon: Icons.dark_mode,
              onChanged: (value) {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          ModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showColorPaletteDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => ModernPopup(
        title: AppLocalizations.of(context)!.colorPalette,
        icon: Icons.color_lens,
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: AppColorPalettes.lightPalettes.length,
            itemBuilder: (context, index) {
              final palette = AppColorPalettes.lightPalettes[index];
              final isSelected = themeProvider.selectedPaletteIndex == index;

              return GestureDetector(
                onTap: () {
                  themeProvider.setColorPalette(index);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          ModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _getColorPaletteName(int index) {
    final paletteNames = [
      AppLocalizations.of(context)!.oceanBlue,
      AppLocalizations.of(context)!.forestGreen,
      AppLocalizations.of(context)!.sunsetOrange,
      AppLocalizations.of(context)!.royalPurple,
      AppLocalizations.of(context)!.rosePink,
    ];

    if (index >= 0 && index < paletteNames.length) {
      return paletteNames[index];
    }
    return AppLocalizations.of(context)!.defaultPalette;
  }

  String _getExportDataText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Google Drive\'a Yedekle';
      case 'en':
        return 'Backup to Google Drive';
      case 'de':
        return 'Auf Google Drive sichern';
      case 'fr':
        return 'Sauvegarder sur Google Drive';
      case 'es':
        return 'Respaldar en Google Drive';
      default:
        return 'Backup to Google Drive';
    }
  }

  String _getExportDataSubtitle() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Verilerinizi Google Drive\'a yedekleyin';
      case 'en':
        return 'Backup your data to Google Drive';
      case 'de':
        return 'Sichern Sie Ihre Daten auf Google Drive';
      case 'fr':
        return 'Sauvegardez vos données sur Google Drive';
      case 'es':
        return 'Respalda tus datos en Google Drive';
      default:
        return 'Backup your data to Google Drive';
    }
  }

  String _getImportDataText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Google Drive\'dan Geri Yükle';
      case 'en':
        return 'Restore from Google Drive';
      case 'de':
        return 'Von Google Drive wiederherstellen';
      case 'fr':
        return 'Restaurer depuis Google Drive';
      case 'es':
        return 'Restaurar desde Google Drive';
      default:
        return 'Restore from Google Drive';
    }
  }

  String _getImportDataSubtitle() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Google Drive\'dan verilerinizi geri yükleyin';
      case 'en':
        return 'Restore your data from Google Drive';
      case 'de':
        return 'Stellen Sie Ihre Daten von Google Drive wieder her';
      case 'fr':
        return 'Restaurez vos données depuis Google Drive';
      case 'es':
        return 'Restaura tus datos desde Google Drive';
      default:
        return 'Restore your data from Google Drive';
    }
  }

  Future<void> _exportDataToDrive() async {
    try {
      final googleDriveService = GoogleDriveService();
      
      // Google Drive'a bağlan
      final isConnected = await googleDriveService.signIn();
      if (!isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getGoogleSignInFailedText()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Verileri topla
      final notes = await _databaseService.getAllNotes();
      final diaries = await _databaseService.getAllDiaries();

      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'language': prefs.getString('language') ?? 'tr',
        'daily_reminder_enabled': prefs.getBool('daily_reminder_enabled') ?? false,
        'daily_reminder_hour': prefs.getInt('daily_reminder_hour') ?? 20,
        'daily_reminder_minute': prefs.getInt('daily_reminder_minute') ?? 0,
        'gemini_api_key': prefs.getString('gemini_api_key'),
        'theme_mode': prefs.getBool('dark_mode') ?? false,
        'color_palette_index': prefs.getInt('selected_palette_index') ?? 0,
      };

      final exportData = {
        'notes': notes.map((note) => note.toMap()).toList(),
        'diaries': diaries.map((diary) => diary.toMap()).toList(),
        'settings': settings,
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      };

      // Google Drive'a yükle
      final success = await googleDriveService.uploadBackup(exportData);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getBackupSuccessText()),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getBackupFailedText()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getBackupFailedText()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importDataFromDrive() async {
    try {
      final googleDriveService = GoogleDriveService();
      
      // Google Drive'a bağlan
      final isConnected = await googleDriveService.signIn();
      if (!isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getGoogleSignInFailedText()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Yedekleri listele
      final backups = await googleDriveService.listBackups();
      
      if (backups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getNoBackupsFoundText()),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Kullanıcıya yedek seçtir
      final selectedBackup = await _showBackupSelectionDialog(backups);
      if (selectedBackup == null) return;

      // Seçilen yedeği indir ve içe aktar
      final backupData = await googleDriveService.downloadBackup(selectedBackup.id!);
      
      if (backupData != null) {
        await _processImportedData(backupData);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getRestoreFailedText()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getRestoreFailedText()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<drive.File?> _showBackupSelectionDialog(List<drive.File> backups) async {
    return await showDialog<drive.File>(
      context: context,
      builder: (context) => ModernPopup(
        title: _getSelectBackupText(),
        icon: Icons.cloud_download,
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final backup = backups[index];
              final createdTime = backup.createdTime;
              final formattedDate = createdTime != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(createdTime)
                  : _getUnknownDateText();
              
              return ListTile(
                leading: const Icon(Icons.backup),
                title: Text(backup.name ?? 'Notevia Backup'),
                subtitle: Text(formattedDate),
                onTap: () => Navigator.pop(context, backup),
              );
            },
          ),
        ),
        actions: [
          ModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _processImportedData(Map<String, dynamic> data) async {
    int importedNotesCount = 0;
    int importedDiariesCount = 0;

    // Import notes
    if (data['notes'] != null) {
      final notesList = data['notes'] as List;
      final existingNotes = await _databaseService.getAllNotes();

      for (final noteData in notesList) {
        final exists = existingNotes.any(
          (note) =>
              note.title == (noteData['title'] ?? '') &&
              note.content == (noteData['content'] ?? ''),
        );

        if (!exists) {
          final newNote = Note(
            title: noteData['title'] ?? '',
            content: noteData['content'] ?? '',
            plainTextContent:
                noteData['plain_text_content'] ?? noteData['content'] ?? '',
            createdAt: noteData['created_at'] != null
                ? DateTime.parse(noteData['created_at'])
                : DateTime.now(),
            updatedAt: noteData['updated_at'] != null
                ? DateTime.parse(noteData['updated_at'])
                : DateTime.now(),
            isImportant:
                noteData['is_important'] == true ||
                noteData['is_important'] == 1,
            isHidden:
                noteData['is_hidden'] == true || noteData['is_hidden'] == 1,
            tags: noteData['tags'] is String
                ? (noteData['tags'] as String)
                      .split(',')
                      .where((tag) => tag.isNotEmpty)
                      .toList()
                : (noteData['tags'] as List?)?.cast<String>() ?? [],
            reminderDateTime: noteData['reminder_date_time'],
            repeatReminder:
                noteData['repeat_reminder'] == true ||
                noteData['repeat_reminder'] == 1,
          );
          await _databaseService.insertNote(newNote);
          importedNotesCount++;
        }
      }
    }

    // Import diaries
    if (data['diaries'] != null) {
      final diariesList = data['diaries'] as List;
      final existingDiaries = await _databaseService.getAllDiaries();

      for (final diaryData in diariesList) {
        final exists = existingDiaries.any(
          (diary) =>
              diary.title == (diaryData['title'] ?? '') &&
              diary.date.toString().substring(0, 10) ==
                  (diaryData['date'] ?? '').substring(0, 10),
        );

        if (!exists) {
          final newDiary = Diary(
            title: diaryData['title'] ?? '',
            content: diaryData['content'] ?? '',
            plainTextContent:
                diaryData['plain_text_content'] ??
                diaryData['content'] ??
                '',
            date: diaryData['date'] != null
                ? DateTime.parse(diaryData['date'])
                : DateTime.now(),
            createdAt: diaryData['created_at'] != null
                ? DateTime.parse(diaryData['created_at'])
                : DateTime.now(),
            updatedAt: diaryData['updated_at'] != null
                ? DateTime.parse(diaryData['updated_at'])
                : DateTime.now(),
            backgroundColor: diaryData['background_color'] != null
                ? (diaryData['background_color'] is String
                      ? int.parse(
                          (diaryData['background_color'] as String)
                              .replaceAll('#', '0xFF'),
                        )
                      : diaryData['background_color'] as int)
                : 0xFFFFFFFF,
          );
          await _databaseService.insertDiary(newDiary);
          importedDiariesCount++;
        }
      }
    }

    // Import settings
    if (data['settings'] != null) {
      final prefs = await SharedPreferences.getInstance();
      final settings = data['settings'];

      if (settings['language'] != null) {
        await prefs.setString('language', settings['language']);
      }
      if (settings['daily_reminder_enabled'] != null) {
        await prefs.setBool(
          'daily_reminder_enabled',
          settings['daily_reminder_enabled'],
        );
      }
      if (settings['daily_reminder_hour'] != null) {
        await prefs.setInt(
          'daily_reminder_hour',
          settings['daily_reminder_hour'],
        );
      }
      if (settings['daily_reminder_minute'] != null) {
        await prefs.setInt(
          'daily_reminder_minute',
          settings['daily_reminder_minute'],
        );
      }
      if (settings['gemini_api_key'] != null) {
        await prefs.setString('gemini_api_key', settings['gemini_api_key']);
      }
      if (settings['theme_mode'] != null) {
        await prefs.setBool('dark_mode', settings['theme_mode']);
      }
      if (settings['color_palette_index'] != null) {
        await prefs.setInt(
          'selected_palette_index',
          settings['color_palette_index'],
        );
      }

      await _loadSettings();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_getRestoreSuccessText()}: $importedNotesCount ${_getNotesText()}, $importedDiariesCount ${_getDiariesText()}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getGoogleSignInFailedText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Google hesabına giriş yapılamadı';
      case 'en':
        return 'Failed to sign in to Google account';
      case 'de':
        return 'Anmeldung bei Google-Konto fehlgeschlagen';
      case 'fr':
        return 'Échec de la connexion au compte Google';
      case 'es':
        return 'Error al iniciar sesión en la cuenta de Google';
      default:
        return 'Failed to sign in to Google account';
    }
  }

  String _getBackupSuccessText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Veriler başarıyla Google Drive\'a yedeklendi';
      case 'en':
        return 'Data successfully backed up to Google Drive';
      case 'de':
        return 'Daten erfolgreich auf Google Drive gesichert';
      case 'fr':
        return 'Données sauvegardées avec succès sur Google Drive';
      case 'es':
        return 'Datos respaldados exitosamente en Google Drive';
      default:
        return 'Data successfully backed up to Google Drive';
    }
  }

  String _getBackupFailedText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Yedekleme başarısız';
      case 'en':
        return 'Backup failed';
      case 'de':
        return 'Sicherung fehlgeschlagen';
      case 'fr':
        return 'Sauvegarde échouée';
      case 'es':
        return 'Respaldo fallido';
      default:
        return 'Backup failed';
    }
  }

  String _getNoBackupsFoundText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Google Drive\'da yedek bulunamadı';
      case 'en':
        return 'No backups found on Google Drive';
      case 'de':
        return 'Keine Sicherungen auf Google Drive gefunden';
      case 'fr':
        return 'Aucune sauvegarde trouvée sur Google Drive';
      case 'es':
        return 'No se encontraron respaldos en Google Drive';
      default:
        return 'No backups found on Google Drive';
    }
  }

  String _getRestoreFailedText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Geri yükleme başarısız';
      case 'en':
        return 'Restore failed';
      case 'de':
        return 'Wiederherstellung fehlgeschlagen';
      case 'fr':
        return 'Restauration échouée';
      case 'es':
        return 'Restauración fallida';
      default:
        return 'Restore failed';
    }
  }

  String _getSelectBackupText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Yedek Seçin';
      case 'en':
        return 'Select Backup';
      case 'de':
        return 'Sicherung auswählen';
      case 'fr':
        return 'Sélectionner la sauvegarde';
      case 'es':
        return 'Seleccionar respaldo';
      default:
        return 'Select Backup';
    }
  }

  String _getUnknownDateText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Bilinmeyen tarih';
      case 'en':
        return 'Unknown date';
      case 'de':
        return 'Unbekanntes Datum';
      case 'fr':
        return 'Date inconnue';
      case 'es':
        return 'Fecha desconocida';
      default:
        return 'Unknown date';
    }
  }

  String _getRestoreSuccessText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'Geri yükleme tamamlandı';
      case 'en':
        return 'Restore completed';
      case 'de':
        return 'Wiederherstellung abgeschlossen';
      case 'fr':
        return 'Restauration terminée';
      case 'es':
        return 'Restauración completada';
      default:
        return 'Restore completed';
    }
  }

  String _getNotesText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'not';
      case 'en':
        return 'notes';
      case 'de':
        return 'Notizen';
      case 'fr':
        return 'notes';
      case 'es':
        return 'notas';
      default:
        return 'notes';
    }
  }

  String _getDiariesText() {
    switch (_currentLanguage) {
      case 'tr':
        return 'günlük';
      case 'en':
        return 'diaries';
      case 'de':
        return 'Tagebücher';
      case 'fr':
        return 'journaux';
      case 'es':
        return 'diarios';
      default:
        return 'diaries';
    }
  }
}
