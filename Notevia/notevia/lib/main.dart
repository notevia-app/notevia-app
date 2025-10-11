import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/note_detail_screen.dart';
import 'screens/note_add_screen.dart';
import 'screens/diary_screen.dart';

import 'screens/settings_screen.dart';
import 'services/database_service.dart';
import 'services/diary_notification_service.dart';
import 'widgets/pin_input_dialog.dart';
import 'l10n/app_localizations.dart';

// Global notification service will be handled by DiaryNotificationService

// Global navigation key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();

  // Set app to portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize database
  await DatabaseService().database;

  // Notifications will be initialized by DiaryNotificationService

  // Request storage permissions
  await _requestStoragePermissions();

  // Initialize diary notification service
  await DiaryNotificationService().initialize();
  await DiaryNotificationService().restoreScheduledNotifications();
  
  // Check and show daily reminder if needed (after a delay to ensure app is ready)
  Timer(const Duration(seconds: 5), () async {
    await DiaryNotificationService().checkAndShowDailyReminder();
  });
  
  // Set up periodic check for daily reminders (every 30 minutes)
  Timer.periodic(const Duration(minutes: 30), (timer) async {
    await DiaryNotificationService().checkAndShowDailyReminder();
  });

  // Load saved language preference
  final prefs = await SharedPreferences.getInstance();
  String savedLanguage = prefs.getString('language') ?? '';

  // If no saved language, detect device language and set it
  if (savedLanguage.isEmpty) {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final deviceLanguage = deviceLocale.languageCode;
    
    // Desteklenen diller listesi
    const supportedLanguages = ['tr', 'en', 'de', 'fr', 'es'];
    
    if (supportedLanguages.contains(deviceLanguage)) {
      savedLanguage = deviceLanguage;
    } else {
      savedLanguage = 'en'; // Varsayılan İngilizce
    }
    
    // Algılanan dili kaydet
    await prefs.setString('language', savedLanguage);
  }

  runApp(NoteviaApp(initialLanguage: savedLanguage));
}

// Notification handling is now managed by DiaryNotificationService with awesome_notifications

Future<void> _openNoteFromNotification(int noteId) async {
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

Future<void> _openDiaryFromNotification() async {
  if (navigatorKey.currentContext != null) {
    // Check if pin is required for diary access
    final prefs = await SharedPreferences.getInstance();
    final requirePin = prefs.getBool('require_pin_for_diary') ?? false;

    if (requirePin) {
      _showPinDialog(navigatorKey.currentContext!, () {
        _navigateToDiaryAdd();
      });
    } else {
      _navigateToDiaryAdd();
    }
  }
}

void _navigateToDiaryAdd() {
  if (navigatorKey.currentContext != null) {
    Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => route.isFirst,
    );
  }
}

void _navigateToNoteDetail(note) {
  if (navigatorKey.currentContext != null) {
    Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
      (route) => route.isFirst,
    );
  }
}

void _showPinDialog(BuildContext context, VoidCallback onSuccess) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PinInputDialog(
      title: AppLocalizations.of(context)!.hiddenNote,
      subtitle: AppLocalizations.of(context)!.enterPinToViewHiddenNote,
      onPinEntered: (pin) async {
        final prefs = await SharedPreferences.getInstance();
        final savedPin = prefs.getString('pin_code');
        if (pin == savedPin) {
          Navigator.of(context).pop();
          onSuccess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.wrongPinCode),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    ),
  );
}

class NoteviaApp extends StatefulWidget {
  final String? initialLanguage;
  
  const NoteviaApp({super.key, this.initialLanguage});

  @override
  State<NoteviaApp> createState() => _NoteviaAppState();

  static void changeAppLanguage(String languageCode) {
    _NoteviaAppState._instance?._changeLanguage(languageCode);
  }
}

class _NoteviaAppState extends State<NoteviaApp> {
  late String _currentLanguage;
  static _NoteviaAppState? _instance;
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage ?? 'en';
    _instance = this;
    _initSharingIntent();
  }

  void _initSharingIntent() {
    // Listen to media sharing coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    // Add a check to ensure we don't handle files when app is not ready
    if (navigatorKey.currentContext == null) {
      return;
    }
    
    for (SharedMediaFile file in files) {
      if (file.path.endsWith('.txt')) {
        _openTxtFile(file.path);
        break;
      }
    }
  }

  Future<void> _openTxtFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
      // Extract title from filename
      final fileName = file.path.split('/').last;
      final title = fileName.replaceAll('.txt', '');
      
      // Navigate to note add screen with the content only if context is available
      // and avoid automatic navigation that causes home screen return
      if (navigatorKey.currentContext != null) {
        // Add a small delay to prevent immediate navigation issues
        await Future.delayed(const Duration(milliseconds: 100));
        
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => NoteAddScreen(
              initialTitle: title,
              initialContent: content,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error reading TXT file: $e');
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _instance = null;
    super.dispose();
  }

  void _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    setState(() {
      _currentLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Notevia',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: _getThemeMode(themeProvider.themeMode),
            // Localization configuration
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr', ''), // Turkish
              Locale('en', ''), // English
              Locale('de', ''), // German
              Locale('fr', ''), // French
              Locale('es', ''), // Spanish
            ],
            locale: Locale(_currentLanguage, ''),
            home: const SplashScreen(),
            routes: {
              '/language-selection': (context) => const LanguageSelectionScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
              '/add-note': (context) => const NoteAddScreen(),
              '/diary': (context) => const DiaryScreen(),

              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

Future<void> _requestStoragePermissions() async {
  if (Platform.isAndroid) {
    // Bildirim izni (günlük hatırlatıcıları için gerekli)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // Mikrofon izni (sesli notlar için gerekli)
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
  }
}

ThemeMode _getThemeMode(ThemeMode mode) {
  return mode;
}
