import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:viflow/src/providers/app_provider.dart';
import 'package:viflow/src/views/dashboard/dashboard_screen.dart';
import 'package:viflow/src/views/onboarding/onboarding_screen.dart';
import 'package:viflow/src/core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon Kontrolcüsü
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Opaklık Animasyonu
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Büyüme Animasyonu (Hafif zoom in)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Animasyonu Başlat
    _controller.forward();

    // Uygulama Başlatma Mantığı
    _initApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // 1. Servisleri Başlat
    await NotificationService().init();

    // 2. Verileri Yükle
    await provider.loadData();

    // 3. İlk Kez ise İzin İste
    if (provider.isFirstTime) {
      bool granted = await NotificationService().requestPermissions();
      if (granted) {
        await provider.toggleReminder(true);
      }
    }

    // 4. Animasyon bitene kadar ve en az 2 saniye bekle
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)), // Logo süresi
      // Veri yükleme zaten yukarıda await edildi
    ]);

    if (!mounted) return;

    // 5. Yönlendirme
    if (provider.isFirstTime) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Karanlık modda logo rengini beyaz veya primary yapabiliriz.
    // Burada logonun rengini "Primary Color" (Mavi) yapıyoruz ki marka öne çıksın.
    // Eğer logon orijinal renklerinde kalsın istersen 'color:' parametresini silebilirsin.
    final logoColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO TEXT GÖRSELİ
                //
                Image.asset(
                  'assets/images/logo_text.png',
                  width: 250, // Genişlik ayarı
                  // color: logoColor, // Logoyu maviye boyamak istersen bu satırı aç
                  // Eğer logonun kendisi zaten renkliyse color parametresini SİL.
                ),

                const Gap(0.5),

                // Yükleniyor İndikatörü (Opsiyonel, çok şık durur)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
