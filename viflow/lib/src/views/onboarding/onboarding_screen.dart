import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// Dil Dosyası
import 'package:viflow/l10n/app_localizations.dart';

import 'package:viflow/src/views/onboarding/user_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Karanlık mod renk ayarları
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final descColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final containerColor = isDark ? theme.cardColor : theme.primaryColor.withOpacity(0.05);

    // Sayfa İçerikleri (Dil dosyasına bağlı)
    final List<Map<String, dynamic>> pages = [
      {
        "title": l10n.onboardTitle1, // "Su Hayattır"
        "desc": l10n.onboardDesc1,   // "Vücudunuzun ihtiyaç duyduğu..."
        "icon": Icons.water_drop_outlined,
      },
      {
        "title": l10n.onboardTitle2, // "Hedefini Belirle"
        "desc": l10n.onboardDesc2,
        "icon": Icons.track_changes_outlined,
      },
      {
        "title": l10n.onboardTitle3, // "Harekete Geç"
        "desc": l10n.onboardDesc3,
        "icon": Icons.notifications_active_outlined,
      },
    ];

    bool isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. ATLA BUTONU
            Align(
              alignment: Alignment.topRight,
              child: !isLastPage
                  ? Padding(
                // Kenar boşlukları ana Padding'den geliyor
                padding: const EdgeInsets.only(right: 24.0, top: 12.0),
                child: TextButton(
                  onPressed: () {
                    // Atla denirse direkt kurulum ekranına git
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const UserSetupScreen()),
                    );
                  },
                  child: Text(l10n.skip, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                ),
              )
                  : const SizedBox(height: 48 + 12), // Buton alanı kadar boşluk
            ),

            const Gap(20),

            // 2. SAYFALAR (PAGEVIEW)
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  // --- UI DÜZELTMESİ: SAYFALAR ARASI BOŞLUK ---
                  // PageView.builder içindeki her sayfaya (Column) ayrı ayrı padding veriyoruz.
                  // Bu, kaydırma animasyonu sırasında sayfaların birbirine yapışmasını engeller.
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0), // Sayfa içeriği için sağdan/soldan boşluk
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Görsel Alanı
                        Container(
                          height: 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(pages[index]['icon'], size: 100, color: theme.primaryColor),
                        ),
                        const Gap(40),

                        // Başlık
                        Text(
                          pages[index]['title'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: titleColor),
                        ),
                        const Gap(16),

                        // Açıklama
                        Text(
                          pages[index]['desc'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 16, color: descColor, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. ALT KISIM (NOKTA VE BUTON)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Kenar boşluğu
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: theme.primaryColor,
                      dotColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      dotHeight: 8, dotWidth: 8, expansionFactor: 4,
                    ),
                  ),
                  const Gap(40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLastPage) {
                          // Son sayfadaysa Kurulum Ekranına Git
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UserSetupScreen()),
                          );
                        } else {
                          // Değilse Sonraki Sayfaya Kaydır
                          _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        shadowColor: theme.primaryColor.withOpacity(0.4),
                      ),
                      child: Text(
                        isLastPage ? l10n.start : l10n.next,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Gap(20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}