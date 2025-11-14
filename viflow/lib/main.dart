import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // "flutterfire configure" komutuyla oluşan dosya

// Lokalizasyon (Dil) Dosyası
import 'package:viflow/l10n/app_localizations.dart';

// Tema ve Provider
import 'package:viflow/src/core/theme/app_theme.dart';
import 'package:viflow/src/providers/app_provider.dart';

// Başlangıç Ekranı
import 'package:viflow/src/views/splash/splash_screen.dart';

void main() async {
  // 1. Flutter Motorunu Bağla (Zorunlu)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i Başlat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase hatası alırsak loglayalım ama uygulamanın çökmesini engelleyelim
    debugPrint("Firebase Başlatma Hatası: $e");
  }

  // 3. Uygulamayı Çalıştır
  runApp(const ViflowApp());
}

class ViflowApp extends StatelessWidget {
  const ViflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider'ı başlatıyoruz.
        // NOT: Burada "..loadData()" kullanmıyoruz.
        // Veri yüklemeyi ve yönlendirmeyi SplashScreen içinde kontrollü yapıyoruz.
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      // Consumer, Provider'daki değişiklikleri (Dil/Tema) dinler ve MaterialApp'i yeniden çizer.
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Viflow',
            debugShowCheckedModeBanner: false,

            // --- TEMA AYARLARI ---
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            // Provider'dan gelen seçime göre tema (Sistem/Açık/Koyu)
            themeMode: provider.themeMode,

            // --- DİL AYARLARI ---
            // Provider'dan gelen seçili dil
            locale: provider.locale,

            // Desteklenen diller (app_en.arb, app_tr.arb)
            supportedLocales: AppLocalizations.supportedLocales,

            // Yerelleştirme Delegeleri
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // --- GİRİŞ NOKTASI ---
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}