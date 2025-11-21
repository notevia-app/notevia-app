import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Klavye formatı için
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// Dil Dosyası
import 'package:viflow/l10n/app_localizations.dart';

import 'package:viflow/src/providers/app_provider.dart';
import 'package:viflow/src/views/graphs/graphs_screen.dart';
import 'package:viflow/src/views/reminder/reminder_screen.dart';
import 'package:viflow/src/views/settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _randomMotivationIndex;

  @override
  void initState() {
    super.initState();
    // Her açılışta rastgele bir motivasyon mesajı seç
    _randomMotivationIndex = Random().nextInt(5) + 1;
  }

  // --- MODERN ÜST BİLDİRİM SİSTEMİ (HATA GÖSTERİMİ) ---
  void _showTopError(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _TopMessageBanner(message: message, isError: true),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AppProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // Karanlık Mod Kontrolleri
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    // Lokalize Motivasyon Mesajı
    String getMotivation() {
      switch (_randomMotivationIndex) {
        case 1: return l10n.motivation1;
        case 2: return l10n.motivation2;
        case 3: return l10n.motivation3;
        case 4: return l10n.motivation4;
        case 5: return l10n.motivation5;
        default: return l10n.motivation1;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER ---
            _buildHeader(context, provider, l10n, textColor, subTextColor),

            const Gap(10),

            // --- 2. MOTİVASYON KARTI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                ),
                child: Text(
                  getMotivation(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: subTextColor,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ),
            ),

            const Gap(20),

            // --- 3. AKILLI HALKA (GLOW EFEKTLİ & ANIMASYONLU) ---
            Expanded(
              flex: 3,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: provider.currentWater),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return _buildAdvancedCircularIndicator(
                      context,
                      animatedValue,
                      provider.targetWater,
                      textColor,
                      subTextColor
                  );
                },
              ),
            ),

            const Gap(20),

            // --- 4. HIZLI İŞLEM BUTONLARI ---
            _buildQuickAddButtons(context, theme, l10n, isDark),

            const Gap(20),

            // --- 5. GEÇMİŞ LİSTESİ ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    l10n.todaysRecords,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)
                ),
              ),
            ),
            const Gap(10),

            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: provider.todayLogs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const Gap(10),
                      Text(l10n.noRecordsYet, style: GoogleFonts.inter(color: subTextColor)),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: provider.todayLogs.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final log = provider.todayLogs[index];
                    final amount = (log['amount'] as num).toDouble();
                    final time = DateFormat('HH:mm').format(log['timestamp'] as DateTime);
                    return _buildHistoryItem(context, amount, time, l10n, theme);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: GLOW EFEKTLİ AKILLI HALKA ---
  Widget _buildAdvancedCircularIndicator(BuildContext context, double currentVal, double targetVal, Color textColor, Color subTextColor) {
    final theme = Theme.of(context);
    double ratio = targetVal > 0 ? currentVal / targetVal : 0;
    int lap = ratio.floor();
    double percent = ratio - lap;

    // Renk Döngüsü
    List<Color> lapColors = [
      const Color(0xFF2D9CDB), // Mavi
      const Color(0xFF27AE60), // Yeşil
      const Color(0xFFF2994A), // Turuncu
      const Color(0xFF9B51E0), // Mor
      const Color(0xFFEB5757), // Kırmızı
    ];

    Color activeColor = lapColors[lap % lapColors.length];
    Color prevColor = lap > 0 ? lapColors[(lap - 1) % lapColors.length] : theme.primaryColor.withOpacity(0.1);

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. GLOW (IŞIK) EFEKTİ
        Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: activeColor.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
        ),

        // 2. ZEMİN HALKASI
        CircularPercentIndicator(
          radius: 120.0, lineWidth: 18.0, percent: 1.0,
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: Colors.transparent,
          progressColor: lap > 0 ? prevColor.withOpacity(0.3) : theme.primaryColor.withOpacity(0.1),
          animation: false,
        ),

        // 3. ÖNCEKİ TURLAR (Eğer varsa)
        if (lap > 0)
          CircularPercentIndicator(
            radius: 120.0, lineWidth: 18.0, percent: 1.0,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.transparent,
            progressColor: prevColor,
            animation: false,
          ),

        // 4. AKTİF İLERLEME
        CircularPercentIndicator(
          radius: 120.0, lineWidth: 18.0, percent: percent,
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: Colors.transparent,
          progressColor: activeColor,
          animation: false,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: activeColor.withOpacity(0.6), blurRadius: 20)]
                ),
                child: Icon(Icons.water_drop, size: 40, color: activeColor),
              ),
              const Gap(8),
              // Yüzde
              Text(
                "${(ratio * 100).toInt()}%",
                style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
              ),
              // Miktar
              Text(
                "${currentVal.toInt()} / ${targetVal.toInt()} ml",
                style: GoogleFonts.inter(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET: GEÇMİŞ LİSTESİ ELEMANI ---
  Widget _buildHistoryItem(BuildContext context, double amount, String time, AppLocalizations l10n, ThemeData theme) {
    bool isAdded = amount > 0;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: isAdded ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle
            ),
            child: Icon(
                isAdded ? Icons.local_drink_rounded : Icons.undo_rounded,
                color: isAdded ? Colors.blue : Colors.red,
                size: 20
            ),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdded ? l10n.waterDrunk : l10n.actionUndone,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87
                ),
              ),
              Text(
                time,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "${isAdded ? '+' : ''}${amount.toInt()} ml",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isAdded ? Colors.blue : Colors.red
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: HIZLI BUTONLAR ---
  Widget _buildQuickAddButtons(BuildContext context, ThemeData theme, AppLocalizations l10n, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _waterBtn(context, 100, theme, l10n),
          _waterBtn(context, 200, theme, l10n),
          _waterBtn(context, 500, theme, l10n),
          // Özel Buton
          GestureDetector(
            onTap: () => _showCustomDialog(context, l10n),
            child: Column(
              children: [
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: Icon(Icons.add, color: isDark ? Colors.white70 : Colors.black54),
                ),
                const Gap(8),
                Text(
                  l10n.custom,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterBtn(BuildContext context, double amount, ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        context.read<AppProvider>().addWater(amount);
        _showUndoSnackBar(context, amount, l10n);
      },
      child: Column(
        children: [
          Container(
            height: 50, width: 50,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "+${amount.toInt()}",
                style: GoogleFonts.inter(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const Gap(8),
          Text(
            "ml",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- CUSTOM DIALOG (POP-UP) ---
  void _showCustomDialog(BuildContext context, AppLocalizations l10n) {
    final TextEditingController controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierLabel: "CustomAmount",
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
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.water_drop, color: theme.primaryColor, size: 32),
                  ),
                  const Gap(20),
                  Text(l10n.enterAmount, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const Gap(20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
                    decoration: InputDecoration(
                        hintText: "0", suffixText: "ml", filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                    ),
                  ),
                  const Gap(24),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(l10n.cancel, style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)))),
                      const Gap(12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.text.isNotEmpty) {
                              double val = double.tryParse(controller.text) ?? 0;
                              if (val > 0) {
                                context.read<AppProvider>().addWater(val);
                                Navigator.pop(context);
                                _showUndoSnackBar(context, val, l10n);
                              } else {
                                _showTopError(context, l10n.errorInvalidAmount);
                              }
                            } else {
                              _showTopError(context, l10n.errorInvalidAmount);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(l10n.add, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUndoSnackBar(BuildContext context, double amount, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const Gap(10), Text(l10n.addedMsg(amount.toInt()), style: GoogleFonts.inter(fontWeight: FontWeight.w600))]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF27AE60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        action: SnackBarAction(label: l10n.undo, textColor: Colors.white, onPressed: () => context.read<AppProvider>().addWater(-amount)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider, AppLocalizations l10n, Color textColor, Color subTextColor) {
    final String localeCode = Localizations.localeOf(context).toString();
    final String dateStr = DateFormat('d MMMM, EEEE', localeCode).format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.hello(provider.userName), style: GoogleFonts.inter(fontSize: 14, color: subTextColor)),
              Text(dateStr, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade100)),
                child: Row(children: [const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20), const Gap(4), Text("${provider.streak}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16))]),
              ),
              const Gap(8),
              IconButton(
                  onPressed: () => _showMenuModal(context, l10n),
                  icon: Icon(Icons.grid_view_rounded, size: 28, color: textColor)
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMenuModal(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.bar_chart_rounded), title: Text(l10n.statistics), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const GraphsScreen())); }),
            ListTile(leading: const Icon(Icons.notifications_active_rounded), title: Text(l10n.reminder), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen())); }),
            ListTile(leading: const Icon(Icons.settings_rounded), title: Text(l10n.settings), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE TOP BANNER ---
class _TopMessageBanner extends StatefulWidget {
  final String message;
  final bool isError;
  const _TopMessageBanner({required this.message, this.isError = false});
  @override State<_TopMessageBanner> createState() => _TopMessageBannerState();
}
class _TopMessageBannerState extends State<_TopMessageBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<Offset> _offsetAnimation;
  @override void initState() { super.initState(); _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..forward(); _offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut)); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return SlideTransition(position: _offsetAnimation, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: widget.isError ? Colors.red.shade500 : const Color(0xFF2D9CDB), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: (widget.isError ? Colors.red : Colors.blue).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]), child: Row(children: [Icon(widget.isError ? Icons.error_outline_rounded : Icons.info_outline_rounded, color: Colors.white), const Gap(12), Expanded(child: Text(widget.message, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)))])));
  }
}