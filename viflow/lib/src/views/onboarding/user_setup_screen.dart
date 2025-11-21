import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:viflow/l10n/app_localizations.dart';
import 'package:viflow/src/providers/app_provider.dart';
import 'package:viflow/src/views/dashboard/dashboard_screen.dart';
import 'package:viflow/src/core/services/auth_service.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});
  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedGender;
  int _selectedActivityIndex = 1;

  bool _isLoading = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showTopError(BuildContext context, String message) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20,
        child: Material(color: Colors.transparent, child: _TopErrorBanner(message: message)),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null && mounted) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  bool _validateCurrentStep(AppLocalizations l10n, {bool checkAll = false}) {
    String errorMsg = "";
    bool isValid = true;
    int pageToJump = _currentStep;

    if (checkAll) {
      if (_nameController.text.trim().isEmpty) { errorMsg = l10n.enterNameError; isValid = false; pageToJump = 0; }
      else if (_ageController.text.trim().isEmpty) { errorMsg = l10n.enterAgeError; isValid = false; pageToJump = 1; }
      else if (_selectedGender == null) { errorMsg = l10n.selectGenderError; isValid = false; pageToJump = 1; }
      else if (_weightController.text.trim().isEmpty) { errorMsg = l10n.enterWeightError; isValid = false; pageToJump = 2; }
      else if (_heightController.text.trim().isEmpty) { errorMsg = l10n.enterHeightError; isValid = false; pageToJump = 2; }
    }
    else {
      if (_currentStep == 0 && _nameController.text.trim().isEmpty) { errorMsg = l10n.enterNameError; isValid = false; }
      else if (_currentStep == 1) {
        if (_ageController.text.trim().isEmpty) { errorMsg = l10n.enterAgeError; isValid = false; }
        else if (_selectedGender == null) { errorMsg = l10n.selectGenderError; isValid = false; }
      } else if (_currentStep == 2) {
        if (_weightController.text.trim().isEmpty) { errorMsg = l10n.enterWeightError; isValid = false; }
        else if (_heightController.text.trim().isEmpty) { errorMsg = l10n.enterHeightError; isValid = false; }
      }
    }

    if (!isValid) {
      _showTopError(context, errorMsg);
      if (checkAll && pageToJump != _currentStep) {
        _pageController.animateToPage(pageToJump, duration: const Duration(milliseconds: 300), curve: Curves.ease);
        setState(() => _currentStep = pageToJump);
      }
    }
    return isValid;
  }

  void _finishSetup(AppLocalizations l10n) {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    double weight = double.tryParse(_weightController.text) ?? 70;
    double height = double.tryParse(_heightController.text) ?? 170;
    int age = int.tryParse(_ageController.text) ?? 25;
    String name = _nameController.text.trim().isEmpty ? l10n.defaultUser : _nameController.text.trim();

    context.read<AppProvider>().completeOnboarding(
      name: name, age: age, weight: weight, height: height,
      gender: _selectedGender ?? 'male', activityIdx: _selectedActivityIndex,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
    );
  }

  Future<void> _signInWithGoogle(AppLocalizations l10n) async {
    if (!_validateCurrentStep(l10n, checkAll: true)) return;

    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      _finishSetup(l10n);
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopError(context, "Google Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    List<Widget> steps = [
      _buildInputStep(context, title: l10n.nameQuestion, child: _buildTextField(context: context, controller: _nameController, hint: l10n.nameHint, type: TextInputType.name, isDark: isDark)),
      _buildInputStep(context, title: l10n.personalInfo, child: Column(children: [_buildTextField(context: context, controller: _ageController, hint: l10n.age, type: TextInputType.number, isNumeric: true, isDark: isDark), const Gap(20), _buildGenderSelector(l10n, theme, isDark)])),
      _buildInputStep(context, title: l10n.bodyMeasurements, child: Column(children: [_buildTextField(context: context, controller: _weightController, hint: l10n.weight, type: TextInputType.number, isNumeric: true, isDark: isDark), const Gap(20), _buildTextField(context: context, controller: _heightController, hint: l10n.height, type: TextInputType.number, isNumeric: true, isDark: isDark)])),
      _buildInputStep(context, title: l10n.activityLevel, child: _buildActivitySelector(context, l10n, theme, isDark)),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : theme.primaryColor),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  children: steps.map((widget) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: widget,
                  )).toList(),
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(),
                )
              else if (_currentStep == steps.length - 1) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _signInWithGoogle(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF4285F4),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.googleSignIn,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(20),
                TextButton(
                  onPressed: () => _finishSetup(l10n),
                  child: Text(
                    l10n.continueAnonymously,
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ]
              else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_validateCurrentStep(l10n)) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l10n.next, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 50 + 20)
                ],
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildInputStep(BuildContext context, {required String title, required Widget child}) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
            const Gap(40),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required TextInputType type,
    required bool isDark,
    bool isNumeric = false
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : type,
      // DÜZELTME: RegGexp -> RegExp
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : [],
      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
      ),
    );
  }

  Widget _buildGenderSelector(AppLocalizations l10n, ThemeData theme, bool isDark) {
    final genders = [{'id': 'male', 'label': l10n.male, 'icon': Icons.male}, {'id': 'female', 'label': l10n.female, 'icon': Icons.female}];
    return Row(
      children: genders.map((g) {
        bool isSelected = _selectedGender == g['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = g['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : (isDark ? Colors.grey.shade800 : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? theme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
                  boxShadow: [if (!isSelected && !isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(children: [Icon(g['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey, size: 32), const Gap(8), Text(g['label'] as String, style: GoogleFonts.inter(color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700), fontWeight: FontWeight.bold))]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySelector(BuildContext context, AppLocalizations l10n, ThemeData theme, bool isDark) {
    List<String> levels = [l10n.sedentary, l10n.moderate, l10n.active];
    return Column(
      children: List.generate(levels.length, (index) {
        bool isSelected = _selectedActivityIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedActivityIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor.withOpacity(0.1) : (isDark ? Colors.grey.shade800 : Colors.white),
              // DÜZELTME: Kopyala-Yapıştır hatası (İçindekiler)
              border: Border.all(color: isSelected ? theme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200), width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(levels[index], style: GoogleFonts.inter(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? theme.primaryColor : (isDark ? Colors.white70 : Colors.grey.shade700))), if (isSelected) Icon(Icons.check_circle, color: theme.primaryColor)]),
          ),
        );
      }),
    );
  }
}

// --- MODERN ÜST BİLDİRİM WIDGET'I ---
class _TopErrorBanner extends StatefulWidget {
  final String message;
  const _TopErrorBanner({required this.message});
  @override State<_TopErrorBanner> createState() => _TopErrorBannerState();
}
class _TopErrorBannerState extends State<_TopErrorBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<Offset> _offsetAnimation;
  @override void initState() { super.initState(); _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..forward(); _offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut)); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return SlideTransition(position: _offsetAnimation, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: Colors.red.shade500, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]), child: Row(children: [const Icon(Icons.error_outline_rounded, color: Colors.white), const Gap(12), Expanded(child: Text(widget.message, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)))])));
  }
}