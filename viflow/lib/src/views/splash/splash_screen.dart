import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:viflow/src/providers/app_provider.dart';
import 'package:viflow/src/views/dashboard/dashboard_screen.dart';
import 'package:viflow/src/views/onboarding/onboarding_screen.dart';
import 'package:viflow/src/core/services/notification_service.dart';
import 'package:viflow/src/core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _initApp();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _initApp() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // 1. Auth Başlat
    await AuthService().initializeAuth();
    // 2. Notification Başlat
    await NotificationService().init();
    // 3. Verileri Yükle (Auth initialize olduktan sonra)
    await provider.loadData();

    if (provider.isFirstTime) {
      bool granted = await NotificationService().requestPermissions();
      if (granted) await provider.toggleReminder(true);
    }

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    if (provider.isFirstTime) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                // assets/images/logo_text.png var olduğunu varsayıyoruz
                // yoksa Image.asset(...) yerine Text(...) kullan
                Image.asset('assets/images/logo_text.png', width: 200),
                const Gap(20),
                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor.withOpacity(0.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}