import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart' as providers;
import '../providers/user_provider.dart';
import '../services/database_service.dart';
import '../models/note.dart';
import '../widgets/sidebar.dart';
import '../widgets/note_card.dart';
import '../widgets/pin_input_dialog.dart';
import '../l10n/app_localizations.dart';
import 'note_add_screen.dart';
import 'note_detail_screen.dart';
import 'diary_screen.dart';
import 'diary_add_screen.dart';
import 'voice_notes_screen.dart';

import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final Set<int> _selectedNotes = {};
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearchVisible = false;
  bool _isSelectionMode = false;
  int _selectedFilter = 0; // 0: Tümü, 1: Önemli, 2: Yaklaşan, 3: Gizli
  List<String> _customFilters = [];

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Settings'ten döndüğümüzde kullanıcı verilerini yenile - artık Provider kullanıyoruz
  }

  // Public method for external access - artık gerekli değil
  void refreshUserData() {
    // Provider otomatik olarak günceller
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _removeExpiredReminders();
      final notes = await _databaseService.getNotes();
      await _loadCustomFilters();

      setState(() {
        _notes = notes;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLoadingData}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadCustomFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filters = prefs.getStringList('custom_filters') ?? [];
    setState(() {
      _customFilters = filters;
    });
  }

  void _applyFilters() {
    List<Note> filteredNotes = _notes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 0: // Tümü - gizli notları hariç tut
        filteredNotes = filteredNotes.where((note) => !note.isHidden).toList();
        break;
      case 1: // Önemli
        filteredNotes = filteredNotes
            .where((note) => note.isImportant && !note.isHidden)
            .toList();
        break;
      case 2: // Yaklaşan (hatırlatıcı olan notlar)
        final now = DateTime.now();
        filteredNotes = filteredNotes
            .where((note) => note.reminderDateTime != null && !note.isHidden)
            .toList();
        // Hatırlatıcı tarihe göre sırala (yaklaşan önce)
        filteredNotes.sort((a, b) {
          final aReminder = DateTime.parse(a.reminderDateTime!);
          final bReminder = DateTime.parse(b.reminderDateTime!);
          return aReminder.compareTo(bReminder);
        });
        break;
      case 3: // Gizli
        filteredNotes = filteredNotes.where((note) => note.isHidden).toList();
        break;
      default:
        // Özel filtreler için - gizli notları hariç tut
        if (_selectedFilter >= 4) {
          final customFilterIndex = _selectedFilter - 4;
          if (customFilterIndex < _customFilters.length) {
            final customFilterName = _customFilters[customFilterIndex];
            filteredNotes = filteredNotes
                .where(
                  (note) =>
                      !note.isHidden &&
                      note.customFilter != null &&
                      note.customFilter!.split(',').contains(customFilterName),
                )
                .toList();
          }
        }
        break;
    }

    // Sort by updated date (newest first) - except for reminder filter
    if (_selectedFilter != 2) {
      filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    setState(() {
      _filteredNotes = filteredNotes;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(int filter) {
    if (filter == 3) {
      // Gizli notlar
      _showPinDialog(() {
        setState(() {
          _selectedFilter = filter;
        });
        _applyFilters();
      });
    } else {
      setState(() {
        _selectedFilter = filter;
      });
      _applyFilters();
    }
  }

  Future<void> _showPinDialog(VoidCallback onSuccess) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('pin_code');

    if (savedPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.setPinCode)),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        title: AppLocalizations.of(context)!.hiddenNotes,
        subtitle: AppLocalizations.of(context)!.enterPinToAccessHiddenNotes,
        onPinEntered: (pin) {
          if (pin == savedPin) {
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.wrongPinCode),
              ),
            );
            Navigator.of(context).pop(false);
          }
        },
      ),
    );

    if (result == true) {
      onSuccess();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });

    if (_isSearchVisible) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
      _searchController.clear();
      _onSearchChanged('');
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedNotes.clear();
    });
  }

  void _toggleNoteSelection(int noteId) {
    setState(() {
      if (_selectedNotes.contains(noteId)) {
        _selectedNotes.remove(noteId);
        // Eğer hiç seçili not kalmadıysa seçim modundan çık
        if (_selectedNotes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotes.add(noteId);
      }
    });
  }

  Future<void> _deleteSelectedNotes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNotes),
        content: Text(
          '${_selectedNotes.length} ${AppLocalizations.of(context)!.notes.toLowerCase()} ${AppLocalizations.of(context)!.deleteConfirmation.toLowerCase()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final noteId in _selectedNotes) {
        await _databaseService.deleteNote(noteId);
      }
      setState(() {
        _selectedNotes.clear();
        _isSelectionMode = false;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<providers.ThemeProvider>(context);
    themeProvider.updateSystemOverlay(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildNotesView(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton(
              onPressed: _selectedNotes.isNotEmpty
                  ? _deleteSelectedNotes
                  : null,
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _showAddOptionsBottomSheet,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return Text(
                      userProvider.userName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _searchAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchInNotes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(AppLocalizations.of(context)!.allNotes, 0),
            const SizedBox(width: 8),
            _buildFilterChip(AppLocalizations.of(context)!.important, 1),
            const SizedBox(width: 8),
            _buildFilterChip(AppLocalizations.of(context)!.recentNotes, 2),
            const SizedBox(width: 8),
            _buildFilterChip(AppLocalizations.of(context)!.hiddenNotes, 3),
            ..._customFilters.asMap().entries.map((entry) {
              final index = entry.key;
              final filter = entry.value;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildFilterChip(filter, 4 + index),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(value),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildNotesView() {
    if (_filteredNotes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          final note = _filteredNotes[index];
          final isSelected = _selectedNotes.contains(note.id);

          return GestureDetector(
            onTap: () {
              if (_isSelectionMode) {
                _toggleNoteSelection(note.id!);
              } else {
                _openNote(note);
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode();
              }
              _toggleNoteSelection(note.id!);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: NoteCard(
                note: note,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleNoteSelection(note.id!);
                  } else {
                    _openNote(note);
                  }
                },
                onDelete: () => _deleteNote(note),
                onToggleImportant: () => _toggleNoteImportant(note),
                isSelected: isSelected,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 1:
        title = AppLocalizations.of(context)!.noNotesFound;
        subtitle = AppLocalizations.of(context)!.noNotesFound;
        icon = Icons.star_outline;
        break;
      case 2:
        title = AppLocalizations.of(context)!.noNotesFound;
        subtitle = AppLocalizations.of(context)!.noNotesFound;
        icon = Icons.schedule_outlined;
        break;
      case 3:
        title = AppLocalizations.of(context)!.noNotesFound;
        subtitle = AppLocalizations.of(context)!.noNotesFound;
        icon = Icons.lock_outline;
        break;
      default:
        title = AppLocalizations.of(context)!.noNotesFound;
        subtitle = AppLocalizations.of(context)!.noNotesFound;
        icon = Icons.note_add_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return AppLocalizations.of(context)!.goodMorning;
    } else if (hour >= 12 && hour < 18) {
      return AppLocalizations.of(context)!.goodAfternoon;
    } else if (hour >= 18 && hour < 22) {
      return AppLocalizations.of(context)!.goodEvening;
    } else {
      return AppLocalizations.of(context)!.goodNight;
    }
  }

  void _openNote(Note note) {
    // Eğer not sadece sesli not içeriyorsa (metin yoksa) sesli notlarım filtresi aktif olsun
    int? initialFilterIndex;
    bool hasText =
        (note.plainTextContent?.trim().isNotEmpty ?? false) ||
        note.content.trim().isNotEmpty;
    bool hasAudio = note.audioFiles.isNotEmpty;

    if (!hasText && hasAudio) {
      initialFilterIndex = 1; // Sesli Notlarım filtresi
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          note: note,
          initialFilterIndex: initialFilterIndex,
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNote),
        content: Text(AppLocalizations.of(context)!.deleteNoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (note.id != null) {
        await _databaseService.deleteNote(note.id!);
      }
      _loadData();
    }
  }

  Future<void> _toggleNoteImportant(Note note) async {
    final updatedNote = note.copyWith(isImportant: !note.isImportant);
    await _databaseService.updateNote(updatedNote);
    _loadData();
  }

  Widget _buildDrawer() {
    return Sidebar(
      onUserDataChanged: refreshUserData,
    );
  }

  Future<void> _removeExpiredReminders() async {
    try {
      final notes = await _databaseService.getNotes();
      final now = DateTime.now();

      for (final note in notes) {
        if (note.reminderDateTime != null) {
          final reminderTime = DateTime.parse(note.reminderDateTime!);

          // Eğer hatırlatıcı zamanı geçmişse ve tekrar etmiyorsa, hatırlatıcıyı kaldır
          if (reminderTime.isBefore(now) && !note.repeatReminder) {
            final updatedNote = note.copyWith(
              reminderDateTime: null,
              repeatReminder: false,
            );
            await _databaseService.updateNote(updatedNote);
          }
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      print('Expired reminders cleanup error: $e');
    }
  }

  void _showAddOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.createNew,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.note_add,
              title: AppLocalizations.of(context)!.writeNote,
              subtitle: AppLocalizations.of(context)!.createNewNote,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoteAddScreen(),
                  ),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.book,
              title: AppLocalizations.of(context)!.writeDiary,
              subtitle: AppLocalizations.of(context)!.createDiaryEntry,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DiaryAddScreen(isNewDiary: true),
                  ),
                ).then((_) => _loadData());
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
