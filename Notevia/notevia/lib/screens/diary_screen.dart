import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart' as providers;
import '../widgets/diary_card.dart';
import '../widgets/pin_input_dialog.dart';
import 'diary_add_screen.dart';
import 'diary_detail_screen.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Diary> _diaries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkPinAndLoadDiaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPinAndLoadDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('pin_code');

    if (savedPin != null) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PinInputDialog(
          title: AppLocalizations.of(context)!.diaryAccess,
          subtitle: AppLocalizations.of(context)!.enterPinToAccessDiaries,
          onPinEntered: (pin) {
            if (pin == savedPin) {
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.wrongPinCode),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.of(context).pop(false);
            }
          },
        ),
      );

      if (result == true) {
        _loadDiaries();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      _loadDiaries();
    }
  }

  Future<void> _loadDiaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diaries = await _databaseService.getDiaries();
      setState(() {
        _diaries = diaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingDiaries}: $e')));
    }
  }

  List<Diary> get _filteredDiaries {
    var filtered = _diaries;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((diary) {
        return diary.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (diary.plainTextContent?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Filter by selected month
    filtered = filtered.where((diary) {
      return diary.date.year == _selectedMonth.year &&
          diary.date.month == _selectedMonth.month;
    }).toList();

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Map<String, List<Diary>> get _groupedDiaries {
    final grouped = <String, List<Diary>>{};

    for (final diary in _filteredDiaries) {
      final dateKey = diary.dateKey;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(diary);
    }

    return grouped;
  }

  Future<void> _navigateToEditor({Diary? diary}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            DiaryAddScreen(diary: diary, isNewDiary: diary == null),
      ),
    );

    if (result == true) {
      _loadDiaries();
    }
  }

  Future<void> _navigateToDetail(Diary diary) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => DiaryDetailScreen(diary: diary)),
    );

    if (result == true) {
      _loadDiaries();
    }
  }

  Future<void> _deleteDiary(Diary diary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteDiaryTitle),
        content: Text(
          '"${diary.title}" ${AppLocalizations.of(context)!.deleteDiaryConfirmation}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (diary.id != null) {
          await _databaseService.deleteDiary(diary.id!);
        }
        _loadDiaries();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.diaryDeleted)));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.deleteError}: $e')));
      }
    }
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<providers.ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myDiaries,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _showMonthPicker,
              tooltip: AppLocalizations.of(context)!.selectMonth,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: BoxDecoration(color: colorScheme.surface),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchInDiaries,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          // Month indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.4),
                  colorScheme.primaryContainer.withOpacity(0.2),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMMM yyyy', Localizations.localeOf(context).toString()).format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDiaries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(
                                0.2,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.book_outlined,
                              size: 64,
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isNotEmpty
                                ? AppLocalizations.of(context)!.noSearchResults
                                : AppLocalizations.of(context)!.noDiariesYet,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? AppLocalizations.of(context)!.noSearchResultsDescription
                                : AppLocalizations.of(context)!.noDiariesDescription,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToEditor(),
                              icon: const Icon(Icons.add),
                              label: Text(AppLocalizations.of(context)!.writeFirstDiary),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groupedDiaries.length,
                    itemBuilder: (context, index) {
                      final dateKey = _groupedDiaries.keys.elementAt(index);
                      final diariesForDate = _groupedDiaries[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dateKey,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),

                          // Diaries for this date
                          ...diariesForDate.map((diary) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DiaryCard(
                                diary: diary,
                                onTap: () => _navigateToDetail(diary),
                                onDelete: () => _deleteDiary(diary),
                              ),
                            );
                          }),

                          if (index < _groupedDiaries.length - 1)
                            const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToEditor(),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          icon: const Icon(Icons.edit, size: 20),
          label: Text(
            AppLocalizations.of(context)!.writeDiary,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
