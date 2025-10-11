import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart' as providers;
import '../models/color_palette.dart';
import '../widgets/pin_input_dialog.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _userName = '';
  String _userPin = '';
  int _selectedPaletteIndex = 0;
  String _selectedLanguage = 'en';
  bool _isLanguageLoading = false;

  final List<Map<String, String>> _languages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _detectDeviceLanguage();
  }

  void _detectDeviceLanguage() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final deviceLanguage = deviceLocale.languageCode;
    
    // Desteklenen diller listesi
    const supportedLanguages = ['tr', 'en', 'de', 'fr', 'es'];
    
    if (supportedLanguages.contains(deviceLanguage)) {
      setState(() {
        _selectedLanguage = deviceLanguage;
      });
    } else {
      setState(() {
        _selectedLanguage = 'en'; // Varsayılan İngilizce
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
      _isLanguageLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      
      // Dil değişikliğini uygula
      NoteviaApp.changeAppLanguage(languageCode);
      
      if (mounted) {
        setState(() {
          _isLanguageLoading = false;
        });
        
        // Bir sonraki sayfaya geç
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      setState(() {
        _isLanguageLoading = false;
      });
    }
  }

  List<OnboardingPage> get _pages => [
    OnboardingPage(
      title: AppLocalizations.of(context)!.welcomeToNotevia,
      description: AppLocalizations.of(context)!.aiSupportedExperience,
      icon: Icons.edit_note_rounded,
    ),
    OnboardingPage(
      title: AppLocalizations.of(context)!.aiSupport,
      description: AppLocalizations.of(context)!.enhanceWithGemini,
      icon: Icons.psychology_rounded,
    ),
    OnboardingPage(
      title: AppLocalizations.of(context)!.voiceNotes,
      description: AppLocalizations.of(context)!.recordAndCombine,
      icon: Icons.mic_rounded,
    ),
    OnboardingPage(
      title: AppLocalizations.of(context)!.secureJournal,
      description: AppLocalizations.of(context)!.pinProtectedJournal,
      icon: Icons.lock_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<providers.ThemeProvider>(context);
    themeProvider.updateSystemOverlay(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length + 3, // +3 for language, color palette and user setup pages
                itemBuilder: (context, index) {
                   if (index == 0) {
                     return _buildLanguageSelectionPage();
                   } else if (index <= _pages.length) {
                     return _buildOnboardingPage(_pages[index - 1]);
                   } else if (index == _pages.length + 1) {
                     return _buildColorPalettePage();
                   } else {
                     return _buildUserSetupPage();
                   }
                 },
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalettePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.selectYourColorPalette,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: AppColorPalettes.lightPalettes.length,
              itemBuilder: (context, index) {
                final palette = AppColorPalettes.lightPalettes[index];
                final isSelected = _selectedPaletteIndex == index;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedPaletteIndex = index;
                    });
                    // Apply theme immediately
                    final themeProvider = Provider.of<providers.ThemeProvider>(
                      context,
                      listen: false,
                    );
                    await themeProvider.setColorPalette(index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? palette.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Card(
                      color: palette.background,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: palette.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: palette.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: palette.accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            palette.name,
                            style: TextStyle(
                              color: palette.onBackground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: palette.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSetupPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.createYourAccount,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.yourName,
              hintText: AppLocalizations.of(context)!.enterYourName,
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) {
              setState(() {
                _userName = value;
              });
            },
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.pinFourDigit,
              hintText: AppLocalizations.of(context)!.createSecurityPin,
              prefixIcon: Icon(Icons.lock),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            onChanged: (value) {
              setState(() {
                _userPin = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.pinUsageDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.language,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 32),
          Text(
            _getLocalizedText('selectLanguage'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _getLocalizedText('choosePreferredLanguage'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguage == language['code'];
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Material(
                    elevation: isSelected ? 4 : 1,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isLanguageLoading ? null : () {
                        setState(() {
                          _selectedLanguage = language['code']!;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Text(
                              language['flag']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                language['name']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLanguageLoading ? null : () => _changeLanguage(_selectedLanguage),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLanguageLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getLocalizedText('continue'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(String key) {
    switch (_selectedLanguage) {
      case 'tr':
        switch (key) {
          case 'selectLanguage': return 'Dil Seçin';
          case 'choosePreferredLanguage': return 'Tercih ettiğiniz dili seçin';
          case 'continue': return 'Devam Et';
          default: return key;
        }
      case 'de':
        switch (key) {
          case 'selectLanguage': return 'Sprache wählen';
          case 'choosePreferredLanguage': return 'Wählen Sie Ihre bevorzugte Sprache';
          case 'continue': return 'Weiter';
          default: return key;
        }
      case 'fr':
        switch (key) {
          case 'selectLanguage': return 'Sélectionner la langue';
          case 'choosePreferredLanguage': return 'Choisissez votre langue préférée';
          case 'continue': return 'Continuer';
          default: return key;
        }
      case 'es':
        switch (key) {
          case 'selectLanguage': return 'Seleccionar idioma';
          case 'choosePreferredLanguage': return 'Elige tu idioma preferido';
          case 'continue': return 'Continuar';
          default: return key;
        }
      default: // English
        switch (key) {
          case 'selectLanguage': return 'Select Language';
          case 'choosePreferredLanguage': return 'Choose your preferred language';
          case 'continue': return 'Continue';
          default: return key;
        }
    }
  }

  Widget _buildBottomNavigation() {
    final isLastPage = _currentPage == _pages.length + 2;
    final isLanguagePage = _currentPage == 0;
    
    // Dil sayfasında bottom navigation gösterme
    if (isLanguagePage) {
      return const SizedBox.shrink();
    }
    
    final isColorPalettePage = _currentPage == _pages.length + 1;
    final canProceed =
        _currentPage < _pages.length + 1 ||
        isColorPalettePage ||
        (_currentPage == _pages.length + 2 &&
            _userName.isNotEmpty &&
            _userPin.length == 4);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(AppLocalizations.of(context)!.back),
            )
          else
            const SizedBox(),

          // Page indicators
          Row(
            children: List.generate(
              _pages.length + 3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          ElevatedButton(
            onPressed: canProceed
                ? () {
                    if (isLastPage) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                : null,
            child: Text(isLastPage ? AppLocalizations.of(context)!.start : AppLocalizations.of(context)!.next),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );

    // Save user settings
    await prefs.setString('user_name', _userName);
    await prefs.setString('pin_code', _userPin);
    await prefs.setBool('first_launch', false);

    // Set selected color palette
    await themeProvider.setColorPalette(_selectedPaletteIndex);

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
