import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart'; // İzin kontrolü
import 'package:provider/provider.dart';
// Dil Dosyası
import 'package:viflow/l10n/app_localizations.dart';
import 'package:viflow/src/providers/app_provider.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {

  // --- MODERN ÜST BİLDİRİM SİSTEMİ (iOS Stili) ---
  void _showTopMessage(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _TopMessageBanner(message: message, isError: isError),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 3 Saniye sonra kaldır
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context);

    // Karanlık Mod Renk Ayarları
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = theme.cardColor; // AppTheme'den gelen renk
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      // Arkaplan rengi AppTheme'den otomatik gelir
      appBar: AppBar(
        title: Text(
          l10n.reminder,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- 1. ANA ANAHTAR (AKTİF/PASİF) ---
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: SwitchListTile(
                value: provider.isReminderActive,
                activeColor: theme.primaryColor,
                title: Text(
                  provider.isReminderActive ? l10n.reminderActive : l10n.reminderPassive,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
                subtitle: Text(
                  l10n.reminderSubtitle,
                  style: GoogleFonts.inter(fontSize: 13, color: subTextColor),
                ),
                onChanged: (value) async {
                  // Switch'e basınca provider üzerinden işlem yap
                  bool success = await provider.toggleReminder(value);

                  if (!success && value == true) {
                    // İzin verilmediyse dialog göster
                    if (context.mounted) _showPermissionDialog(context, l10n, theme, isDark);
                  } else if (value == true) {
                    // Başarıyla açıldı -> Üstten Mavi/Yeşil Bildirim
                    if (context.mounted) _showTopMessage(context, l10n.notificationsSet, isError: false);
                  } else {
                    // Kapatıldı -> Üstten Kırmızı Bildirim
                    if (context.mounted) _showTopMessage(context, l10n.notificationsDisabled, isError: true);
                  }
                },
              ),
            ),

            const Gap(30),

            // --- 2. AYARLAR (SAAT & SIKLIK) ---
            // Aktif değilse soluklaşır ve tıklanmaz
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: provider.isReminderActive ? 1.0 : 0.5,
              child: AbsorbPointer(
                absorbing: !provider.isReminderActive,
                child: Column(
                  children: [
                    // SAAT ARALIĞI
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePickerCard(
                            context,
                            label: l10n.start,
                            time: provider.startTime,
                            icon: Icons.wb_sunny_outlined,
                            onTimeChanged: (t) => provider.updateReminderSettings(start: t),
                            cardColor: cardColor,
                            textColor: textColor,
                            theme: theme,
                            isDark: isDark,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: _buildTimePickerCard(
                            context,
                            label: l10n.end,
                            time: provider.endTime,
                            icon: Icons.nights_stay_outlined,
                            onTimeChanged: (t) => provider.updateReminderSettings(end: t),
                            cardColor: cardColor,
                            textColor: textColor,
                            theme: theme,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const Gap(20),

                    // SIKLIK SEÇİMİ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark ? [] : [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 24, color: theme.primaryColor),
                              const Gap(12),
                              Text(
                                l10n.interval,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                              ),
                            ],
                          ),

                          // Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: provider.frequencyMinutes,
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.primaryColor),
                                borderRadius: BorderRadius.circular(20),
                                dropdownColor: cardColor, // Dropdown menü arkaplanı
                                style: TextStyle(color: textColor, fontFamily: GoogleFonts.inter().fontFamily),
                                items: [30, 45, 60, 90, 120].map((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(
                                      "$value ${l10n.minuteAbbr}",
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => provider.updateReminderSettings(freq: val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // --- 3. BİLGİ MESAJI ---
            if (provider.isReminderActive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.primaryColor),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        l10n.reminderInfo,
                        style: GoogleFonts.inter(color: textColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  // --- İZİN DİALOGU ---
  void _showPermissionDialog(BuildContext context, AppLocalizations l10n, ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            l10n.permissionRequired,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
        ),
        content: Text(
          l10n.permissionDesc,
          style: GoogleFonts.inter(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings(); // Ayarları aç
            },
            child: Text(l10n.openSettings, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- SAAT SEÇİCİ KARTI ---
  Widget _buildTimePickerCard(
      BuildContext context, {
        required String label,
        required TimeOfDay time,
        required Function(TimeOfDay) onTimeChanged,
        required IconData icon,
        required Color cardColor,
        required Color textColor,
        required ThemeData theme,
        required bool isDark,
      }) {
    return GestureDetector(
      onTap: () async {
        // Time Picker Teması (Karanlık/Aydınlık uyumlu)
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: isDark
                  ? ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: theme.primaryColor,
                  onPrimary: Colors.white,
                  surface: cardColor,
                  onSurface: Colors.white,
                ),
              )
                  : Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: theme.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onTimeChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade500),
                const Gap(6),
                Text(label, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const Gap(8),
            Text(
              time.format(context),
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MODERN ÜST BİLDİRİM WIDGET'I ---
class _TopMessageBanner extends StatefulWidget {
  final String message;
  final bool isError;
  const _TopMessageBanner({required this.message, this.isError = false});

  @override
  State<_TopMessageBanner> createState() => _TopMessageBannerState();
}

class _TopMessageBannerState extends State<_TopMessageBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: widget.isError ? Colors.red.shade500 : const Color(0xFF2D9CDB),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (widget.isError ? Colors.red : Colors.blue).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(widget.isError ? Icons.notifications_off_outlined : Icons.notifications_active_outlined, color: Colors.white),
            const Gap(12),
            Expanded(
              child: Text(
                widget.message,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}