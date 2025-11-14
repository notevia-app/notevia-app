import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Tarih formatlama
import 'package:provider/provider.dart';
// Dil Dosyası
import 'package:viflow/l10n/app_localizations.dart';

import 'package:viflow/src/providers/app_provider.dart';
import 'package:viflow/src/core/services/firebase_service.dart';

class GraphsScreen extends StatefulWidget {
  const GraphsScreen({super.key});

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _allStatsFuture;
  int _touchedIndex = -1; // Bar Chart için
  int _touchedPieIndex = -1; // Pie Chart için

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<AppProvider>(context, listen: false).userId;

    // Tüm verileri paralel çekiyoruz
    _allStatsFuture = Future.wait([
      FirebaseService().getWeeklyData(userId),       // 0: Bar Chart
      FirebaseService().getHeatmapData(userId),      // 1: Heatmap
      FirebaseService().getLast7DaysLogTimes(userId) // 2: Pie Chart
    ]);
  }

  // --- MODERN ÜST BİLDİRİM (iOS Stili) ---
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
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Dil Ayarlarını Algıla
    final String localeCode = Localizations.localeOf(context).languageCode;
    final bool isTr = localeCode == 'tr';

    // Karanlık Mod Renkleri
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final containerColor = theme.cardColor;

    return Scaffold(
      // Arkaplan rengi temadan
      appBar: AppBar(
        title: Text(
            l10n.statistics,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _allStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("${l10n.noRecordsYet} (${snapshot.error})"));
          }

          final weeklyData = snapshot.data![0] as List<Map<String, dynamic>>;
          final heatmapData = snapshot.data![1] as Map<DateTime, int>;
          final logTimes = snapshot.data![2] as List<DateTime>;

          final pieData = _preparePieData(logTimes, l10n);
          final totalDrunk = heatmapData.values.fold(0, (sum, val) => sum + val);

          // --- Dinamik Grafik Yüksekliği Hesaplama ---
          double maxVal = 0;
          for (var item in weeklyData) {
            double val = (item['val'] as num).toDouble();
            if (val > maxVal) maxVal = val;
          }
          double chartMaxY = maxVal > 0 ? maxVal * 1.2 : 3000;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. AYLIK HEATMAP (Özel Grid Widget) ---
                _sectionTitle(l10n.habitCalendar, textColor),

                _buildCustomMonthGrid(
                    context,
                    heatmapData,
                    theme,
                    provider.targetWater,
                    isTr,
                    localeCode,
                    containerColor,
                    isDark
                ),

                const Gap(30),

                // --- 2. GENEL DURUM (Insights) ---
                _sectionTitle(l10n.overview, textColor),
                Row(
                  children: [
                    Expanded(child: _infoCard(l10n.totalIntake, "${(totalDrunk/1000).toStringAsFixed(1)} L", Icons.water_drop, Colors.blue, containerColor, textColor, isDark)),
                    const Gap(12),
                    Expanded(child: _infoCard(l10n.activeDays, "${heatmapData.length} ${l10n.days}", Icons.calendar_today, Colors.orange, containerColor, textColor, isDark)),
                  ],
                ),

                const Gap(30),

                // --- 3. ZAMAN DAĞILIMI (Pie Chart) ---
                _sectionTitle(l10n.timeDistribution, textColor),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _boxDecoration(containerColor, isDark),
                  height: 300,
                  child: logTimes.isEmpty
                      ? Center(child: Text(l10n.noRecordsYet, style: GoogleFonts.inter(color: Colors.grey)))
                      : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildPieSections(pieData, l10n),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pieData.keys.map((key) {
                          Color color = _getTimeColor(key, l10n);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const Gap(8),
                                Text("$key (%${pieData[key]!.toInt()})", style: TextStyle(fontSize: 12, color: textColor)),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ),

                const Gap(30),

                // --- 4. HAFTALIK DETAY (Bar Chart) ---
                _sectionTitle(l10n.weeklyDetail, textColor),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _boxDecoration(containerColor, isDark),
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMaxY,
                        barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => theme.cardColor,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  "${rod.toY.toInt()} ml",
                                  TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                            touchCallback: (e, r) {
                              setState(() {
                                if (r != null && r.spot != null && e.isInterestedForInteractions) {
                                  _touchedIndex = r.spot!.touchedBarGroupIndex;
                                } else {
                                  _touchedIndex = -1;
                                }
                              });
                            }
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index >= 0 && index < weeklyData.length) {
                                  // Tarihi dinamik hesapla ve dile göre formatla
                                  DateTime date = DateTime.now().subtract(Duration(days: 6 - index));
                                  String dayLabel = DateFormat('E', localeCode).format(date);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                        dayLabel,
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)
                                    ),
                                  );
                                }
                                return const Text("");
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const SizedBox.shrink();
                                  if (value >= 1000) {
                                    return Text("${(value/1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.grey, fontSize: 10));
                                  }
                                  return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                                },
                              )
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              strokeWidth: 1
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(weeklyData.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: (weeklyData[index]['val'] as num).toDouble(),
                                color: _touchedIndex == index
                                    ? theme.primaryColor
                                    : (isDark ? Colors.blueGrey.shade800 : Colors.blue.shade50),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: chartMaxY,
                                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                                ),
                              )
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const Gap(30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- ÖZEL AYLIK IZGARA (CUSTOM GRID) ---
  Widget _buildCustomMonthGrid(
      BuildContext context,
      Map<DateTime, int> heatmapData,
      ThemeData theme,
      double targetWater,
      bool isTr,
      String localeCode,
      Color containerColor,
      bool isDark
      ) {
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Ay Başlığı (Lokalize)
    String monthName = DateFormat.yMMMM(localeCode).format(now);

    // Yazı renkleri (Karanlık mod uyumu)
    Color titleColor = isDark ? Colors.white : Colors.blueGrey.shade700;
    Color legendText = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(containerColor, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              monthName,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)
          ),
          const Gap(16),

          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              int day = index + 1;
              DateTime dateKey = DateTime(now.year, now.month, day);
              int amount = heatmapData[dateKey] ?? 0;

              double opacity = (amount / targetWater).clamp(0.0, 1.0);

              // Hücre Rengi
              Color cellColor;
              if (amount == 0) {
                cellColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
              } else {
                cellColor = theme.primaryColor.withOpacity(max(0.2, opacity));
              }

              // Yazı Rengi (Koyu hücrede beyaz, açıkta gri)
              Color textColor = opacity > 0.6 ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700);

              return GestureDetector(
                onTap: () {
                  if (amount > 0) {
                    String dateStr = DateFormat('d MMMM yyyy', localeCode).format(dateKey);
                    _showTopMessage(context, "$dateStr: $amount ml");
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const Gap(16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(isTr ? "Az" : "Less", style: TextStyle(fontSize: 10, color: legendText)),
              const Gap(5),
              _legendBox(isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              _legendBox(theme.primaryColor.withOpacity(0.3)),
              _legendBox(theme.primaryColor.withOpacity(0.6)),
              _legendBox(theme.primaryColor),
              const Gap(5),
              Text(isTr ? "Çok" : "More", style: TextStyle(fontSize: 10, color: legendText)),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 12, height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }

  // --- YARDIMCI METODLAR ---

  Map<String, double> _preparePieData(List<DateTime> logs, AppLocalizations l10n) {
    if (logs.isEmpty) return {};

    int morning = 0;
    int afternoon = 0;
    int evening = 0;
    int night = 0;

    for (var date in logs) {
      int h = date.hour;
      if (h >= 6 && h < 12) morning++;
      else if (h >= 12 && h < 18) afternoon++;
      else if (h >= 18 && h <= 23) evening++;
      else night++;
    }

    int total = logs.length;
    return {
      l10n.morning: (morning / total) * 100,
      l10n.afternoon: (afternoon / total) * 100,
      l10n.evening: (evening / total) * 100,
      l10n.night: (night / total) * 100,
    };
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data, AppLocalizations l10n) {
    List<PieChartSectionData> sections = [];
    int i = 0;
    data.forEach((key, value) {
      if (value > 0) {
        final isTouched = i == _touchedPieIndex;
        final radius = isTouched ? 60.0 : 50.0;
        sections.add(PieChartSectionData(
          color: _getTimeColor(key, l10n),
          value: value,
          title: '${value.toInt()}%',
          radius: radius,
          titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
      i++;
    });
    return sections;
  }

  Color _getTimeColor(String key, AppLocalizations l10n) {
    if (key == l10n.morning) return Colors.orangeAccent;
    if (key == l10n.afternoon) return Colors.yellow.shade700;
    if (key == l10n.evening) return Colors.blue;
    if (key == l10n.night) return Colors.indigo;
    return Colors.grey;
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    );
  }

  BoxDecoration _boxDecoration(Color color, bool isDark) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
    );
  }

  Widget _infoCard(String title, String val, IconData icon, Color iconColor, Color bgColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(bgColor, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const Gap(10),
          Text(val, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        ],
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
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..forward();
    _offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
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
          boxShadow: [BoxShadow(color: (widget.isError ? Colors.red : Colors.blue).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Icon(widget.isError ? Icons.error_outline_rounded : Icons.info_outline_rounded, color: Colors.white),
            const Gap(12),
            Expanded(child: Text(widget.message, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}