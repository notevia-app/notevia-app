import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:viflow/l10n/app_localizations.dart';
import 'package:viflow/src/providers/app_provider.dart';
import 'package:viflow/src/views/onboarding/onboarding_screen.dart';
import 'package:viflow/src/views/settings/profile_edit_screen.dart';
import 'package:viflow/src/core/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AppProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final containerColor = theme.cardColor;
    final bool isAnonymous = AuthService().currentUser?.isAnonymous ?? true;

    String currentLangName =
        provider.locale.languageCode == 'tr' ? "Türkçe" : "English";
    String currentFlag = provider.locale.languageCode == 'tr' ? "🇹🇷" : "🇺🇸";
    String currentThemeName;
    if (provider.themeMode == ThemeMode.system) {
      currentThemeName = l10n.system;
    } else if (provider.themeMode == ThemeMode.light)
      currentThemeName = l10n.light;
    else
      currentThemeName = l10n.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settings,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(l10n.profile, isDark),
          _buildSettingsContainer(
            color: containerColor,
            isDark: isDark,
            children: [
              _buildTile(context,
                  icon: Icons.person_outline_rounded,
                  iconColor: Colors.blue,
                  title: provider.userName.isNotEmpty
                      ? provider.userName
                      : l10n.defaultUser,
                  subtitle: l10n.personalInfo,
                  textColor: textColor,
                  subTextColor: subTextColor, onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen()));
              }),
              _buildDivider(isDark),
              _buildTile(context,
                  icon: Icons.flag_outlined,
                  iconColor: Colors.orange,
                  title: l10n.dailyGoal,
                  subtitle: "${provider.targetWater.toInt()} ml",
                  trailingText: l10n.editProfile,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showModernEditTargetDialog(
                      context, provider, l10n, theme, isDark)),
            ],
          ),
          const Gap(30),
          _buildSectionHeader(l10n.appSettings, isDark),
          _buildSettingsContainer(
            color: containerColor,
            isDark: isDark,
            children: [
              _buildTile(context,
                  icon: Icons.language,
                  iconColor: Colors.purple,
                  title: l10n.language,
                  subtitle: "$currentFlag $currentLangName",
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showLanguageBottomSheet(
                      context, provider, theme, isDark)),
              _buildDivider(isDark),
              _buildTile(context,
                  icon: Icons.dark_mode_outlined,
                  iconColor: Colors.indigo,
                  title: l10n.theme,
                  subtitle: currentThemeName,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showThemeBottomSheet(
                      context, provider, l10n, theme, isDark)),
            ],
          ),
          const Gap(30),
          _buildSectionHeader(l10n.dataManagement, isDark),
          _buildSettingsContainer(
            color: containerColor,
            isDark: isDark,
            children: [
              if (isAnonymous)
                _buildTile(
                  context,
                  icon: Icons.link_rounded,
                  iconColor: Colors.green,
                  title: l10n.linkWithGoogle,
                  subtitle: l10n.secureYourData,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () async {
                    try {
                      await AuthService().signInWithGoogle();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(l10n.accountLinked),
                            backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("${l10n.linkFailed}: $e"),
                            backgroundColor: Colors.red));
                      }
                    }
                  },
                ),
              if (isAnonymous) _buildDivider(isDark),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Icon(Icons.delete_forever_rounded,
                        color: Colors.red.shade400, size: 24)),
                title: Text(l10n.resetData,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400)),
                subtitle: Text(l10n.resetDesc,
                    style:
                        GoogleFonts.inter(fontSize: 12, color: subTextColor)),
                onTap: () => _showResetConfirmDialog(
                    context, provider, l10n, theme, isDark),
              ),
            ],
          ),
          const Gap(40),
          Center(
              child: Text("${l10n.version} 1.0.0",
                  style: GoogleFonts.inter(
                      color: Colors.grey.shade500, fontSize: 12))),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(
      {required List<Widget> children,
      required Color color,
      required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: subTextColor)),
      trailing: trailingText != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(trailingText,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)))
          : Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        indent: 70);
  }

  // ==================================================
  // DIALOGLAR (TAMAMI)
  // ==================================================
  void _showModernEditTargetDialog(BuildContext context, AppProvider provider,
      AppLocalizations l10n, ThemeData theme, bool isDark) {
    final TextEditingController controller =
        TextEditingController(text: provider.targetWater.toInt().toString());
    showGeneralDialog(
      context: context,
      barrierLabel: "Target",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(animation.value) - 1.0;
        return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: animation.value,
                child: Transform.scale(
                    scale: Curves.easeOutBack.transform(animation.value),
                    child: child)));
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
            child: Material(
                color: Colors.transparent,
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10))
                        ]),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.flag_rounded,
                              color: Colors.orange, size: 32)),
                      const Gap(20),
                      Text(l10n.dailyGoal,
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87)),
                      const Gap(24),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16)),
                          child: TextField(
                              controller: controller,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700),
                              decoration: const InputDecoration(
                                  suffixText: "ml",
                                  suffixStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 16)))),
                      const Gap(30),
                      Row(children: [
                        Expanded(
                            child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16)),
                                child: Text(l10n.cancel,
                                    style: GoogleFonts.inter(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)))),
                        const Gap(12),
                        Expanded(
                            child: ElevatedButton(
                                onPressed: () {
                                  double? val =
                                      double.tryParse(controller.text);
                                  if (val != null && val > 0) {
                                    provider.updateTarget(val);
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0),
                                child: Text(l10n.saveChanges,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold)))),
                      ]),
                    ]))));
      },
    );
  }

  void _showLanguageBottomSheet(BuildContext context, AppProvider provider,
      ThemeData theme, bool isDark) {
    showModalBottomSheet(
        context: context,
        backgroundColor: theme.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                  // DÜZELTME: mainAxisSize: MainAxisSize: MainAxisSize.min -> mainAxisSize: MainAxisSize.min
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context)!.selectLanguage,
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87)),
                    const Gap(20),
                    _languageOption(context, provider, 'tr', 'Türkçe', '🇹🇷',
                        theme, isDark),
                    const Gap(10),
                    _languageOption(context, provider, 'en', 'English', '🇺🇸',
                        theme, isDark),
                    const Gap(20),
                  ]));
        });
  }

  Widget _languageOption(BuildContext context, AppProvider provider,
      String code, String name, String flag, ThemeData theme, bool isDark) {
    bool isSelected = provider.locale.languageCode == code;
    return ListTile(
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.primaryColor)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected
          ? theme.primaryColor.withOpacity(0.1)
          : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
    );
  }

  void _showThemeBottomSheet(BuildContext context, AppProvider provider,
      AppLocalizations l10n, ThemeData theme, bool isDark) {
    showModalBottomSheet(
        context: context,
        backgroundColor: theme.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                  // DÜZELTME: mainAxisSize: MainAxisSize: MainAxisSize.min -> mainAxisSize: MainAxisSize.min
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.selectTheme,
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87)),
                    const Gap(20),
                    _themeOption(context, provider, ThemeMode.system,
                        l10n.system, Icons.brightness_auto, theme, isDark),
                    const Gap(10),
                    _themeOption(context, provider, ThemeMode.light, l10n.light,
                        Icons.wb_sunny_rounded, theme, isDark),
                    const Gap(10),
                    _themeOption(context, provider, ThemeMode.dark, l10n.dark,
                        Icons.nights_stay_rounded, theme, isDark),
                    const Gap(20),
                  ]));
        });
  }

  Widget _themeOption(
      BuildContext context,
      AppProvider provider,
      ThemeMode mode,
      String name,
      IconData icon,
      ThemeData theme,
      bool isDark) {
    bool isSelected = provider.themeMode == mode;
    return ListTile(
      onTap: () {
        provider.setThemeMode(mode);
        Navigator.pop(context);
      },
      leading: Icon(icon, color: isSelected ? theme.primaryColor : Colors.grey),
      title: Text(name,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.primaryColor)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected
          ? theme.primaryColor.withOpacity(0.1)
          : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
    );
  }

  void _showResetConfirmDialog(BuildContext context, AppProvider provider,
      AppLocalizations l10n, ThemeData theme, bool isDark) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 28),
                const Gap(10),
                Text(l10n.areYouSure,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87))
              ]),
              content: Text(l10n.resetWarning,
                  style: GoogleFonts.inter(color: Colors.grey)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      await provider.resetAllData();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const OnboardingScreen()),
                              (route) => false);
                        }
                      }
                    },
                    child: Text(l10n.yesReset)),
              ],
            ));
  }
}
