import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notevia/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../providers/theme_provider.dart' as providers;
import '../widgets/pin_input_dialog.dart';
import 'note_detail_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/diary_notification_service.dart';

class NoteAddScreen extends StatefulWidget {
  final Note? note;
  final bool isNewNote;
  final String? initialTitle;
  final String? initialContent;

  const NoteAddScreen({
    super.key,
    this.note,
    this.isNewNote = true,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<NoteAddScreen> createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends State<NoteAddScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  late QuillController _contentController;
  final TextEditingController _aiChatController = TextEditingController();
  final TextEditingController _customFilterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _aiChatFocusNode = FocusNode();

  final DatabaseService _databaseService = DatabaseService();
  final GeminiService _geminiService = GeminiService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _toolbarAnimationController;
  late AnimationController _modalAnimationController;
  late AnimationController _extraSettingsAnimationController;
  late AnimationController _aiChatAnimationController;
  late AnimationController _voiceNotesAnimationController;
  late AnimationController _recordingModalAnimationController;
  late Animation<Offset> _toolbarSlideAnimation;
  late Animation<Offset> _modalSlideAnimation;
  late Animation<Offset> _extraSettingsSlideAnimation;
  late Animation<Offset> _aiChatSlideAnimation;
  late Animation<Offset> _voiceNotesSlideAnimation;
  late Animation<Offset> _recordingModalSlideAnimation;
  late Animation<double> _extraSettingsScaleAnimation;
  late Animation<double> _aiChatScaleAnimation;
  late Animation<double> _voiceNotesScaleAnimation;
  late Animation<double> _recordingModalScaleAnimation;
  late Animation<double> _extraSettingsFadeAnimation;
  late Animation<double> _aiChatFadeAnimation;
  late Animation<double> _voiceNotesFadeAnimation;
  late Animation<double> _recordingModalFadeAnimation;

  bool _isImportant = false;
  bool _isHidden = false;
  bool _isSaving = false;
  bool _isAiProcessing = false;
  bool _isRecording = false;
  bool _isRecordingPaused = false;
  bool _isToolbarVisible = true;
  bool _isExtraSettingsVisible = false;
  bool _isAiChatVisible = false;
  bool _isVoiceNotesVisible = false;
  bool _isRecordingModalVisible = false;
  bool _hasUnsavedChanges = false;
  bool _hasReminder = false;
  bool _repeatReminder = false;
  bool _shouldStopAiProcessing = false;

  String _selectedColor = 'default';
  List<String> _selectedCustomFilters = [];
  DateTime? _reminderDateTime;
  List<String> _audioFiles = [];
  List<String> _audioFileNames = []; // Ses dosyalarının özel isimleri
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  List<String> _customFilters = [];

  // Ses oynatma kontrolü için değişkenler
  bool _isPlaying = false;
  String? _currentPlayingFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _positionTimer;
  final Map<String, bool> _playingStates = {}; // Her dosya için oynatma durumu

  final List<Color> _noteColors = [
    Colors.white, // default
    const Color(0xFFFFE5E5), // Soft coral
    const Color(0xFFFFE5CC), // Peach
    const Color(0xFFFFF4E5), // Cream
    const Color(0xFFE5F5E5), // Mint green
    const Color(0xFFE5F0FF), // Sky blue
    const Color(0xFFF0E5FF), // Lavender
    const Color(0xFFFFE5F5), // Rose
  ];

  final List<String> _colorNames = [
    'default',
    'red',
    'orange',
    'yellow',
    'green',
    'blue',
    'purple',
    'pink',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _initializeRecorder();
    _setupScrollListener();
    _loadCustomFilters();
  }

  void _initializeAnimations() {
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _modalAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _extraSettingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _aiChatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _voiceNotesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _toolbarSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1)).animate(
          CurvedAnimation(
            parent: _toolbarAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _modalSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _modalAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // Extra Settings Animations
    _extraSettingsSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _extraSettingsAnimationController,
            curve: Curves.fastOutSlowIn,
          ),
        );

    _extraSettingsScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _extraSettingsAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _extraSettingsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _extraSettingsAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // AI Chat Animations
    _aiChatSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _aiChatAnimationController,
            curve: Curves.fastOutSlowIn,
          ),
        );

    _aiChatScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _aiChatAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _aiChatFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _aiChatAnimationController,
        curve: Curves.easeInOutQuart,
      ),
    );

    // Voice Notes Animations
    _voiceNotesSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _voiceNotesAnimationController,
            curve: Curves.fastOutSlowIn,
          ),
        );

    _voiceNotesScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _voiceNotesAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _voiceNotesFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _voiceNotesAnimationController,
        curve: Curves.easeInOutQuint,
      ),
    );

    // Recording Modal Animations
    _recordingModalAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _recordingModalSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _recordingModalAnimationController,
            curve: Curves.fastOutSlowIn,
          ),
        );

    _recordingModalScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _recordingModalAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _recordingModalFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _recordingModalAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _initializeData() {
    // Initialize QuillController
    if (widget.note != null && widget.note!.content.isNotEmpty) {
      try {
        // Try to parse as Quill document
        final doc = Document.fromJson(jsonDecode(widget.note!.content));
        _contentController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback to plain text
        final doc = Document()..insert(0, widget.note!.content);
        _contentController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else if (widget.initialContent != null &&
        widget.initialContent!.isNotEmpty) {
      // Initialize with TXT file content
      final doc = Document()..insert(0, widget.initialContent!);
      _contentController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _contentController = QuillController.basic();
    }

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _isImportant = widget.note!.isImportant;
      _isHidden = widget.note!.isHidden;
      final customFilter = widget.note!.customFilter ?? '';
      if (customFilter.isNotEmpty) {
        _selectedCustomFilters = customFilter
            .split(',')
            .where((f) => f.isNotEmpty)
            .toList();
      }
      _selectedColor = widget.note!.backgroundColor ?? 'default';
      _audioFiles = List.from(widget.note!.audioFiles);

      if (widget.note!.reminderDateTime != null) {
        _hasReminder = true;
        _reminderDateTime = DateTime.parse(widget.note!.reminderDateTime!);
        _repeatReminder = widget.note!.repeatReminder;
      }
    } else {
      // Set initial title and content from TXT file if provided
      if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
        _titleController.text = widget.initialTitle!;
      }
    }

    _contentController.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Toolbar pozisyonunu scroll durumuna göre güncelle
      setState(() {
        // Toolbar her zaman görünür olsun
        if (!_isToolbarVisible) {
          _isToolbarVisible = true;
        }
      });
    });
  }

  void _addCustomFilter() {
    final filterName = _customFilterController.text.trim();
    if (filterName.isNotEmpty && !_customFilters.contains(filterName)) {
      setState(() {
        _customFilters.add(filterName);
        _customFilterController.clear();
      });
      _saveCustomFilters();
    }
  }

  void _removeCustomFilter(String filter) {
    setState(() {
      _customFilters.remove(filter);
      _selectedCustomFilters.remove(filter);
    });
    _saveCustomFilters();
  }

  Future<void> _saveCustomFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_filters', _customFilters);
  }

  Future<void> _loadCustomFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filters = prefs.getStringList('custom_filters') ?? [];
    setState(() {
      _customFilters = filters;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _aiChatController.dispose();
    _customFilterController.dispose();
    _scrollController.dispose();
    _contentFocusNode.dispose();
    _titleFocusNode.dispose();
    _aiChatFocusNode.dispose();
    _toolbarAnimationController.dispose();
    _modalAnimationController.dispose();
    _extraSettingsAnimationController.dispose();
    _aiChatAnimationController.dispose();
    _voiceNotesAnimationController.dispose();
    _recordingModalAnimationController.dispose();
    _recordingTimer?.cancel();
    _positionTimer?.cancel();
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<providers.ThemeProvider>(context);
    final backgroundColor = _getBackgroundColor();
    final iconColor = _getIconColor();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(iconColor),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildTitleField(),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildContentField(),
                          ),
                          const SizedBox(height: 100), // Space for toolbar
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButtons(iconColor),
                ],
              ),
              _buildFloatingToolbar(iconColor),
              if (_isExtraSettingsVisible) _buildExtraSettingsModal(),
              if (_isAiChatVisible) _buildAiChatModal(),
              if (_isVoiceNotesVisible) _buildVoiceNotesModal(),
              if (_isRecordingModalVisible) _buildRecordingModal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _onBackPressed,
            icon: Icon(Icons.arrow_back, color: iconColor),
          ),
          Expanded(
            child: Text(
              widget.isNewNote
                  ? AppLocalizations.of(context)!.newNoteTitle
                  : AppLocalizations.of(context)!.noteEditorTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _saveNote,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(Icons.save, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      maxLines: null,
      textInputAction: TextInputAction.newline,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _getTextColor(),
      ),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.noteTitlePlaceholder,
        hintStyle: TextStyle(color: _getTextColor().withOpacity(0.6)),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildContentField() {
    return GestureDetector(
      onTap: () {
        // Herhangi bir yere tıklandığında focus'u aktif et
        _contentFocusNode.requestFocus();
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: QuillEditor.basic(
          controller: _contentController,
          focusNode: _contentFocusNode,
          config: QuillEditorConfig(
            padding: EdgeInsets.zero,
            placeholder: AppLocalizations.of(context)!.noteContentPlaceholder,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                TextStyle(fontSize: 16, color: _getTextColor()),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomButton(
            icon: Icons.settings,
            label: AppLocalizations.of(context)!.extraSettings,
            onPressed: _toggleExtraSettings,
            iconColor: iconColor,
          ),
          _buildBottomButton(
            icon: Icons.smart_toy,
            label: AppLocalizations.of(context)!.noteviaAI,
            onPressed: _toggleAiChat,
            iconColor: iconColor,
          ),
          _buildBottomButton(
            icon: Icons.mic,
            label: AppLocalizations.of(context)!.voiceNote,
            onPressed: _toggleVoiceNotes,
            iconColor: iconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: iconColor, size: 28),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: iconColor)),
      ],
    );
  }

  Widget _buildFloatingToolbar(Color iconColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scroll pozisyonuna göre toolbar konumunu hesapla
    double toolbarPosition = 120.0; // Varsayılan bottom pozisyon

    if (_scrollController.hasClients) {
      final scrollOffset = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Scroll başladığında toolbar'ı üste yapıştır
      if (scrollOffset > 100) {
        toolbarPosition =
            MediaQuery.of(context).size.height - 200; // Top pozisyona geç
      }
    }

    return Positioned(
      top: _scrollController.hasClients && _scrollController.offset > 100
          ? 80
          : null,
      bottom: _scrollController.hasClients && _scrollController.offset > 100
          ? null
          : 120,
      left: 0,
      right: 0,
      child: Container(
        height: 65,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: QuillSimpleToolbar(
            controller: _contentController,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showListNumbers: true,
              showListBullets: true,
              showCodeBlock: true,
              showQuote: true,
              showIndent: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
              showDirection: false,
              showSearchButton: true,
              multiRowsDisplay: false,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );
    final colorScheme = Theme.of(context).colorScheme;

    // Eğer özel renk seçilmişse, tema rengini kullan
    if (_selectedColor != 'default') {
      final colorIndex = _colorNames.indexOf(_selectedColor);
      return colorIndex >= 0 ? _noteColors[colorIndex] : colorScheme.surface;
    }

    // Varsayılan olarak tema rengini kullan
    return colorScheme.surface;
  }

  Color _getIconColor() {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.onSurface;
  }

  Color _getTextColor() {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.onSurface;
  }

  void _toggleExtraSettings() {
    if (_isExtraSettingsVisible) {
      _extraSettingsAnimationController.reverse().then((_) {
        setState(() {
          _isExtraSettingsVisible = false;
        });
      });
    } else {
      setState(() {
        _isExtraSettingsVisible = true;
      });
      _extraSettingsAnimationController.forward();
    }
  }

  void _toggleAiChat() {
    if (_isAiChatVisible) {
      _aiChatAnimationController.reverse().then((_) {
        setState(() {
          _isAiChatVisible = false;
        });
      });
    } else {
      setState(() {
        _isAiChatVisible = true;
      });
      _aiChatAnimationController.forward();
    }
  }

  void _toggleVoiceNotes() {
    if (_isVoiceNotesVisible) {
      // Önce kayıt modalını kapat
      if (_isRecordingModalVisible) {
        _recordingModalAnimationController.reverse();
      }
      _voiceNotesAnimationController.reverse().then((_) {
        setState(() {
          _isVoiceNotesVisible = false;
          _isRecordingModalVisible = false; // Kayıt modalını da kapat
        });
      });
    } else {
      setState(() {
        _isVoiceNotesVisible = true;
      });
      _voiceNotesAnimationController.forward();
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _getBackgroundColor(),
          title: Text(
            AppLocalizations.of(context)!.unsavedChanges,
            style: TextStyle(color: _getTextColor()),
          ),
          content: Text(
            AppLocalizations.of(context)!.unsavedChangesMessage,
            style: TextStyle(color: _getTextColor()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: _getIconColor()),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)!.exit,
                style: TextStyle(color: _getIconColor()),
              ),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  void _onBackPressed() async {
    if (await _onWillPop()) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final content = jsonEncode(
        _contentController.document.toDelta().toJson(),
      );
      final plainTextContent = _contentController.document.toPlainText();

      // Otomatik başlık oluşturma - tarih-saat formatında
      String title;
      if (_titleController.text.trim().isEmpty) {
        final now = DateTime.now();
        title =
            '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      } else {
        title = _titleController.text.trim();
      }

      if (title.isEmpty && plainTextContent.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.noteTitleOrContentEmpty,
            ),
          ),
        );
        return;
      }

      final now = DateTime.now();

      final note = Note(
        id: widget.note?.id ?? now.millisecondsSinceEpoch,
        title: title,
        content: content,
        plainTextContent: plainTextContent,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
        isImportant: _isImportant,
        isHidden: _isHidden,
        customFilter: _selectedCustomFilters.isEmpty
            ? null
            : _selectedCustomFilters.join(','),
        reminderDateTime: _reminderDateTime?.toIso8601String(),
        repeatReminder: _repeatReminder,
        backgroundColor: _selectedColor == 'default' ? null : _selectedColor,
        audioFiles: _audioFiles,
        tags: [],
      );

      if (widget.isNewNote) {
        await _databaseService.insertNote(note);
      } else {
        await _databaseService.updateNote(note);
      }

      if (_hasReminder && _reminderDateTime != null) {
        await _scheduleNotification(note);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Eğer düzenleme modundaysa notu geri döndür
      if (!widget.isNewNote) {
        Navigator.pop(context, note);
      } else {
        // Eğer not sadece sesli not içeriyorsa (metin yoksa) sesli notlarım filtresi aktif olsun
        int? initialFilterIndex;
        bool hasText =
            (note.plainTextContent?.trim().isNotEmpty ?? false) ||
            note.content.trim().isNotEmpty;
        bool hasAudio = note.audioFiles.isNotEmpty;

        if (!hasText && hasAudio) {
          initialFilterIndex = 1; // Sesli Notlarım filtresi
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.errorSavingNote}: $e'),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _scheduleNotification(Note note) async {
    if (_reminderDateTime == null) return;

    // Check notification permission first
    final diaryService = DiaryNotificationService();
    final hasPermission = await diaryService.ensureNotificationPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bildirim izni gerekli. Lütfen ayarlardan bildirim iznini açın.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Check notification permissions
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      // Create a simple, safe notification ID
      final notificationId = note.id! % 2147483647;

      // Cancel any existing notifications for this note
      for (int i = 0; i < 365; i++) {
        await AwesomeNotifications().cancel(notificationId + i);
      }

      final scheduledDate = _reminderDateTime!;
      final now = DateTime.now();

      if (_repeatReminder) {
        // For repeating reminders, use periodic scheduling
        var nextScheduledDate = scheduledDate;

        // If the scheduled time has already passed today, schedule for tomorrow
        if (nextScheduledDate.isBefore(now)) {
          nextScheduledDate = DateTime(
            now.year,
            now.month,
            now.day,
            scheduledDate.hour,
            scheduledDate.minute,
          ).add(const Duration(days: 1));
        }

        // Schedule daily notifications for the next year
        for (int i = 0; i < 365; i++) {
          final futureDate = nextScheduledDate.add(Duration(days: i));

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notificationId + i,
              channelKey: 'note_reminders',
              title: AppLocalizations.of(context)!.noteReminderTitle,
              body: note.title.isEmpty
                  ? AppLocalizations.of(context)!.untitledNote
                  : note.title,
              icon: null, // Use default app icon
              payload: {
                'noteId': note.id.toString(),
                'action': 'note_reminder',
              },
            ),
            schedule: NotificationCalendar(
              year: futureDate.year,
              month: futureDate.month,
              day: futureDate.day,
              hour: futureDate.hour,
              minute: futureDate.minute,
              second: 0,
              millisecond: 0,
              repeats: false,
            ),
          );
        }
      } else {
        // For one-time reminders
        if (scheduledDate.isAfter(now)) {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notificationId,
              channelKey: 'note_reminders',
              title: AppLocalizations.of(context)!.noteReminderTitle,
              body: note.title.isEmpty
                  ? AppLocalizations.of(context)!.untitledNote
                  : note.title,
              icon: null, // Use default app icon
              payload: {
                'noteId': note.id.toString(),
                'action': 'note_reminder',
              },
            ),
            schedule: NotificationCalendar(
              year: scheduledDate.year,
              month: scheduledDate.month,
              day: scheduledDate.day,
              hour: scheduledDate.hour,
              minute: scheduledDate.minute,
              second: 0,
              millisecond: 0,
              repeats: false,
            ),
          );
        }
      }

      print('Notification scheduled successfully for note: ${note.id}');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _repeatReminder
                  ? AppLocalizations.of(context)!.dailyReminderSet
                  : AppLocalizations.of(context)!.reminderSet,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.reminderSetError}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPinDialog(VoidCallback onSuccess) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('pin_code');

    if (savedPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pinNotSet)),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        title: AppLocalizations.of(context)!.hiddenNote,
        subtitle: AppLocalizations.of(context)!.enterPinToAccessHiddenNote,
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

  Widget _buildExtraSettingsModal() {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _extraSettingsSlideAnimation,
        child: ScaleTransition(
          scale: _extraSettingsScaleAnimation,
          child: FadeTransition(
            opacity: _extraSettingsFadeAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.extraSettings,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _toggleExtraSettings,
                          icon: Icon(Icons.close, color: _getIconColor()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSettingItem(
                            AppLocalizations.of(context)!.important,
                            AppLocalizations.of(context)!.markNoteAsImportant,
                            Switch(
                              value: _isImportant,
                              onChanged: (value) {
                                setState(() {
                                  _isImportant = value;
                                });
                              },
                            ),
                          ),
                          _buildSettingItem(
                            AppLocalizations.of(context)!.hidden,
                            AppLocalizations.of(context)!.markNoteAsHidden,
                            Switch(
                              value: _isHidden,
                              onChanged: (value) {
                                setState(() {
                                  _isHidden = value;
                                });
                              },
                            ),
                          ),

                          if (_customFilters.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.addedFilters,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _customFilters.map((filter) {
                                final isSelected = _selectedCustomFilters
                                    .contains(filter);
                                return GestureDetector(
                                  onLongPress: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: Text(
                                          AppLocalizations.of(
                                            dialogContext,
                                          )!.deleteFilter,
                                        ),
                                        content: Text(
                                          '"$filter" ${AppLocalizations.of(dialogContext)!.filterDeleteConfirmation}',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogContext),
                                            child: Text(
                                              AppLocalizations.of(
                                                dialogContext,
                                              )!.cancel,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(dialogContext);
                                              _removeCustomFilter(filter);
                                            },
                                            child: Text(
                                              AppLocalizations.of(
                                                dialogContext,
                                              )!.delete,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: FilterChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedCustomFilters.add(filter);
                                        } else {
                                          _selectedCustomFilters.remove(filter);
                                        }
                                      });
                                    },
                                    selectedColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2),
                                    checkmarkColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.reminder,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: _hasReminder,
                                onChanged: (value) {
                                  setState(() {
                                    _hasReminder = value ?? false;
                                    if (!_hasReminder) {
                                      _reminderDateTime = null;
                                      _repeatReminder = false;
                                    }
                                  });
                                },
                              ),
                              Text(AppLocalizations.of(context)!.addReminder),
                            ],
                          ),
                          if (_hasReminder) ...[
                            const SizedBox(height: 8),
                            ListTile(
                              title: Text(
                                _reminderDateTime != null
                                    ? '${_reminderDateTime!.day}/${_reminderDateTime!.month}/${_reminderDateTime!.year} ${_reminderDateTime!.hour}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}'
                                    : AppLocalizations.of(
                                        context,
                                      )!.selectDateTime,
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _selectReminderDateTime,
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: _repeatReminder,
                                  onChanged: (value) {
                                    setState(() {
                                      _repeatReminder = value ?? false;
                                    });
                                  },
                                ),
                                Text(AppLocalizations.of(context)!.repeatDaily),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.customFilter,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customFilterController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.enterCustomFilterName,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addCustomFilter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, Widget trailing) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _selectReminderDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _reminderDateTime ?? DateTime.now(),
        ),
      );

      if (time != null) {
        setState(() {
          _reminderDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildAiChatModal() {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _aiChatSlideAnimation,
        child: ScaleTransition(
          scale: _aiChatScaleAnimation,
          child: FadeTransition(
            opacity: _aiChatFadeAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.25,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.noteviaAI,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _toggleAiChat,
                          icon: Icon(Icons.close, color: _getIconColor()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _aiChatController,
                                  focusNode: _aiChatFocusNode,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(
                                      context,
                                    )!.chatWithAI,
                                    border: const OutlineInputBorder(),
                                  ),
                                  maxLines: null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _isAiProcessing
                                    ? _stopAiProcessing
                                    : _sendAiMessage,
                                icon: Icon(
                                  _isAiProcessing ? Icons.stop : Icons.send,
                                  color: _isAiProcessing
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _insertFormattedTextAnimated(String text) async {
    final currentLength = _contentController.document.length;
    final insertPosition = currentLength > 1 ? currentLength - 1 : 0;

    if (currentLength > 1) {
      _contentController.document.insert(insertPosition, '\n\n');
    }

    // Parse markdown and apply formatting with animation
    final lines = text.split('\n');
    int currentPos = _contentController.document.length > 1
        ? _contentController.document.length - 1
        : 0;

    for (int i = 0; i < lines.length; i++) {
      // Eğer durdurulmuşsa animasyonu sonlandır
      if (_shouldStopAiProcessing) {
        break;
      }

      final line = lines[i];

      if (line.trim().isEmpty) {
        if (i < lines.length - 1) {
          _contentController.document.insert(currentPos, '\n');
          currentPos += 1;
        }
        continue;
      }

      // Process line with formatting
      await _insertLineWithFormattingAnimated(line, currentPos);
      currentPos = _contentController.document.length > 1
          ? _contentController.document.length - 1
          : _contentController.document.length;

      if (i < lines.length - 1) {
        _contentController.document.insert(currentPos, '\n');
        currentPos += 1;
      }
    }
  }

  Future<void> _insertLineWithFormattingAnimated(
    String line,
    int startPos,
  ) async {
    // Handle bullet points
    if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
      final bulletText = line.trim().substring(2);
      _contentController.document.insert(startPos, '• ');
      await _insertFormattedLineAnimated(bulletText, startPos + 2);
      return;
    }

    // Handle numbered lists
    final numberedListRegex = RegExp(r'^\d+\. ');
    if (numberedListRegex.hasMatch(line.trim())) {
      await _insertFormattedLineAnimated(line, startPos);
      return;
    }

    // Handle regular text with formatting
    await _insertFormattedLineAnimated(line, startPos);
  }

  Future<void> _insertFormattedLineAnimated(String line, int startPos) async {
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final italicRegex = RegExp(r'\*(.*?)\*');

    int currentPos = startPos;
    int i = 0;

    while (i < line.length) {
      // Eğer durdurulmuşsa animasyonu sonlandır
      if (_shouldStopAiProcessing) {
        break;
      }

      // Check for bold formatting
      final boldMatch = boldRegex.firstMatch(line.substring(i));
      final italicMatch = italicRegex.firstMatch(line.substring(i));

      if (boldMatch != null && boldMatch.start == 0) {
        // Insert bold text with animation
        final boldText = boldMatch.group(1) ?? '';
        for (int j = 0; j < boldText.length; j++) {
          if (_shouldStopAiProcessing) break;
          _contentController.document.insert(currentPos, boldText[j]);
          _contentController.formatText(currentPos, 1, Attribute.bold);
          currentPos++;
          await Future.delayed(const Duration(milliseconds: 10));
          setState(() {});
        }
        i += boldMatch.end;
      } else if (italicMatch != null &&
          italicMatch.start == 0 &&
          !line.substring(i).startsWith('**')) {
        // Insert italic text with animation (avoid conflict with bold)
        final italicText = italicMatch.group(1) ?? '';
        for (int j = 0; j < italicText.length; j++) {
          if (_shouldStopAiProcessing) break;
          _contentController.document.insert(currentPos, italicText[j]);
          _contentController.formatText(currentPos, 1, Attribute.italic);
          currentPos++;
          await Future.delayed(const Duration(milliseconds: 10));
          setState(() {});
        }
        i += italicMatch.end;
      } else {
        // Insert regular character with animation
        if (_shouldStopAiProcessing) break;
        _contentController.document.insert(currentPos, line[i]);
        // Clear any previous formatting for regular text
        _contentController.formatText(
          currentPos,
          1,
          Attribute.clone(Attribute.bold, null),
        );
        _contentController.formatText(
          currentPos,
          1,
          Attribute.clone(Attribute.italic, null),
        );
        currentPos++;
        i++;
        await Future.delayed(const Duration(milliseconds: 10));
        setState(() {});
      }
    }
  }

  Future<void> _sendAiMessage() async {
    final message = _aiChatController.text.trim();
    if (message.isEmpty) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    _shouldStopAiProcessing = false;
    setState(() {
      _isAiProcessing = true;
    });

    try {
      final currentContent = _contentController.document.toPlainText();

      // Hızlı yanıt için beklemeden AI yanıtını al
      final response = await _geminiService.generateResponse(
        message,
        context: currentContent.isNotEmpty ? currentContent : null,
      );

      // Eğer durdurulmuşsa işlemi sonlandır
      if (_shouldStopAiProcessing) {
        setState(() {
          _isAiProcessing = false;
        });
        return;
      }

      // Add AI response with animated formatting
      await _insertFormattedTextAnimated(response);

      _aiChatController.clear();

      setState(() {
        _hasUnsavedChanges = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.aiError}: $e')),
      );
    } finally {
      setState(() {
        _isAiProcessing = false;
      });
    }
  }

  void _stopAiProcessing() {
    // AI işlemini gerçekten durdurmak için flag kullan
    _shouldStopAiProcessing = true;
    setState(() {
      _isAiProcessing = false;
    });
  }

  Widget _buildVoiceNotesModal() {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _voiceNotesSlideAnimation,
        child: ScaleTransition(
          scale: _voiceNotesScaleAnimation,
          child: FadeTransition(
            opacity: _voiceNotesFadeAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.voiceNotes,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isRecordingModalVisible = true;
                            });
                            _recordingModalAnimationController.forward();
                          },
                          icon: Icon(Icons.add, color: _getIconColor()),
                        ),
                        IconButton(
                          onPressed: _toggleVoiceNotes,
                          icon: Icon(Icons.close, color: _getIconColor()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _audioFiles.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.noVoiceNotesYet,
                              style: TextStyle(
                                color: _getTextColor().withOpacity(0.6),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _audioFiles.length,
                            itemBuilder: (context, index) {
                              final audioFile = _audioFiles[index];
                              final isCurrentlyPlaying =
                                  _playingStates[audioFile] ?? false;
                              final showProgressBar =
                                  _currentPlayingFile == audioFile;

                              return Card(
                                color: _getBackgroundColor(),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.audiotrack,
                                            color: _getIconColor(),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  index < _audioFileNames.length
                                                      ? _audioFileNames[index]
                                                      : '${AppLocalizations.of(context)!.voiceNoteTitle} ${index + 1}',
                                                  style: TextStyle(
                                                    color: _getTextColor(),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  audioFile.split('/').last,
                                                  style: TextStyle(
                                                    color: _getTextColor()
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _playAudio(audioFile),
                                            icon: Icon(
                                              isCurrentlyPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: _getIconColor(),
                                              size: 28,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _renameAudioFile(index),
                                            icon: Icon(
                                              Icons.edit,
                                              color: _getIconColor(),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _deleteAudioFile(index),
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (showProgressBar) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              _formatDuration(_currentPosition),
                                              style: TextStyle(
                                                color: _getTextColor()
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                            Expanded(
                                              child: Slider(
                                                value:
                                                    _totalDuration
                                                            .inMilliseconds >
                                                        0
                                                    ? _currentPosition
                                                          .inMilliseconds
                                                          .toDouble()
                                                    : 0.0,
                                                max: _totalDuration
                                                    .inMilliseconds
                                                    .toDouble(),
                                                onChanged: (value) {
                                                  _seekToPosition(
                                                    Duration(
                                                      milliseconds: value
                                                          .toInt(),
                                                    ),
                                                  );
                                                },
                                                activeColor: _getIconColor(),
                                                inactiveColor: _getIconColor()
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(_totalDuration),
                                              style: TextStyle(
                                                color: _getTextColor()
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingModal() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _recordingModalSlideAnimation,
        child: ScaleTransition(
          scale: _recordingModalScaleAnimation,
          child: FadeTransition(
            opacity: _recordingModalFadeAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.saveVoiceNote,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(_recordingDuration),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!_isRecording)
                          ElevatedButton(
                            onPressed: _startRecording,
                            child: Text(
                              AppLocalizations.of(context)!.startRecording,
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: _isRecordingPaused
                                    ? _resumeRecording
                                    : _pauseRecording,
                                icon: Icon(
                                  _isRecordingPaused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  size: 32,
                                  color: _getIconColor(),
                                ),
                              ),
                              IconButton(
                                onPressed: _stopRecording,
                                icon: Icon(
                                  Icons.stop,
                                  size: 32,
                                  color: _getIconColor(),
                                ),
                              ),
                              IconButton(
                                onPressed: _cancelRecording,
                                icon: Icon(
                                  Icons.close,
                                  size: 32,
                                  color: _getIconColor(),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            _recordingModalAnimationController.reverse().then((
                              _,
                            ) {
                              setState(() {
                                _isRecordingModalVisible = false;
                              });
                            });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: TextStyle(color: _getIconColor()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    print('_startRecording çağrıldı');

    try {
      // Recorder'ı yeniden başlat
      await _recorder.openRecorder();

      final permission = await Permission.microphone.request();
      print('Mikrofon izni: $permission');
      if (permission != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.microphonePermissionRequired,
            ),
          ),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      _currentRecordingPath = '${directory.path}/$fileName';

      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
        bitRate: 128000, // 128 kbps yüksek kalite
        sampleRate: 44100, // CD kalitesi sample rate
      );

      print('Kayıt başlatıldı: $_currentRecordingPath');
    } catch (e) {
      print('${AppLocalizations.of(context)!.recordingStartErrorMessage}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.recordingStartError}: $e',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _isRecordingPaused = false;
      _recordingDuration = Duration.zero;
    });

    // Start timer for recording duration
    _startRecordingTimer();
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (_isRecording && !_isRecordingPaused) {
        setState(() {
          _recordingDuration = Duration(
            milliseconds: _recordingDuration.inMilliseconds + 100,
          );
        });
      }
    });
  }

  Future<void> _pauseRecording() async {
    await _recorder.pauseRecorder();
    setState(() {
      _isRecordingPaused = true;
    });
  }

  Future<void> _resumeRecording() async {
    await _recorder.resumeRecorder();
    setState(() {
      _isRecordingPaused = false;
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stopRecorder();

    if (_currentRecordingPath != null) {
      final fileName = await _showSaveAudioDialog();
      if (fileName != null) {
        setState(() {
          _audioFiles.add(_currentRecordingPath!);
          _audioFileNames.add(fileName); // Kullanıcının verdiği ismi kaydet
          _hasUnsavedChanges = true;
        });
      }
    }

    setState(() {
      _isRecording = false;
      _isRecordingPaused = false;
      _isRecordingModalVisible = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _cancelRecording() async {
    // Onay kutusu göster
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getBackgroundColor(),
        title: Text(
          AppLocalizations.of(context)!.cancelRecording,
          style: TextStyle(color: _getTextColor()),
        ),
        content: Text(
          AppLocalizations.of(context)!.cancelRecordingConfirmation,
          style: TextStyle(color: _getTextColor()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.no,
              style: TextStyle(color: _getIconColor()),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.yes,
              style: TextStyle(color: _getIconColor()),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      _recordingTimer?.cancel();
      await _recorder.stopRecorder();

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _isRecordingPaused = false;
        _isRecordingModalVisible = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  Future<String?> _showSaveAudioDialog() async {
    final controller = TextEditingController(
      text:
          '${AppLocalizations.of(context)!.voiceNoteTitle} ${DateTime.now().hour}:${DateTime.now().minute}',
    );

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getBackgroundColor(),
        title: Text(
          AppLocalizations.of(context)!.saveVoiceNote,
          style: TextStyle(color: _getTextColor()),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _getTextColor()),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.voiceNotes,
            hintStyle: TextStyle(color: _getTextColor().withOpacity(0.6)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: _getIconColor()),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _getIconColor().withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _getIconColor()),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: _getIconColor()),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              AppLocalizations.of(context)!.save,
              style: TextStyle(color: _getIconColor()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playAudio(String filePath) async {
    try {
      // Eğer aynı dosya çalıyorsa duraklat/devam ettir
      if (_currentPlayingFile == filePath && _isPlaying) {
        await _audioPlayer.pause();
        _positionTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _playingStates[filePath] = false;
        });
        return;
      }

      // Başka bir dosya çalıyorsa durdur
      if (_isPlaying && _currentPlayingFile != null) {
        await _audioPlayer.stop();
        _positionTimer?.cancel();
        setState(() {
          _playingStates[_currentPlayingFile!] = false;
        });
      }

      // Eğer aynı dosya duraklatılmışsa devam ettir
      if (_currentPlayingFile == filePath && !_isPlaying) {
        await _audioPlayer.resume();
        _startPositionTimer();
        setState(() {
          _isPlaying = true;
          _playingStates[filePath] = true;
        });
        return;
      }

      // Yeni dosyayı oynat
      await _audioPlayer.play(DeviceFileSource(filePath));

      // Ses dosyasının toplam süresini al
      _audioPlayer.getDuration().then((duration) {
        if (duration != null) {
          setState(() {
            _totalDuration = duration;
          });
        }
      });

      setState(() {
        _isPlaying = true;
        _currentPlayingFile = filePath;
        _currentPosition = Duration.zero;
        _playingStates[filePath] = true;
        // Diğer dosyaların oynatma durumunu false yap
        _playingStates.updateAll(
          (key, value) => key == filePath ? true : false,
        );
      });

      _startPositionTimer();

      // Oynatma bittiğinde
      _audioPlayer.onPlayerComplete.listen((_) {
        _positionTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _currentPlayingFile = null;
          _currentPosition = Duration.zero;
          _playingStates[filePath] = false;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.audioPlaybackError}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      if (_isPlaying) {
        final position = await _audioPlayer.getCurrentPosition();
        if (position != null) {
          setState(() {
            _currentPosition = position;
          });
        }
      }
    });
  }

  Future<void> _seekToPosition(Duration position) async {
    await _audioPlayer.seek(position);
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _renameAudioFile(int index) async {
    final currentName = index < _audioFileNames.length
        ? _audioFileNames[index]
        : '${AppLocalizations.of(context)!.voiceNoteTitle} ${index + 1}';
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentName);
        return AlertDialog(
          backgroundColor: _getBackgroundColor(),
          title: Text(
            AppLocalizations.of(context)!.renameAudioFile,
            style: TextStyle(color: _getTextColor()),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: _getTextColor()),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterNewName,
              hintStyle: TextStyle(color: _getTextColor().withOpacity(0.6)),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: _getIconColor()),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _getIconColor().withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _getIconColor()),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: _getIconColor()),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(
                AppLocalizations.of(context)!.save,
                style: TextStyle(color: _getIconColor()),
              ),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      setState(() {
        _audioFileNames[index] = newName;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _deleteAudioFile(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getBackgroundColor(),
        title: Text(
          AppLocalizations.of(context)!.deleteAudioFile,
          style: TextStyle(color: _getTextColor()),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteConfirmation,
          style: TextStyle(color: _getTextColor()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: _getIconColor()),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final audioFile = _audioFiles[index];

      // Eğer silinen dosya şu anda oynatılıyorsa durdur
      if (_currentPlayingFile == audioFile) {
        await _audioPlayer.stop();
        _positionTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _currentPlayingFile = null;
          _currentPosition = Duration.zero;
        });
      }

      setState(() {
        _audioFiles.removeAt(index);
        if (index < _audioFileNames.length) {
          _audioFileNames.removeAt(index);
        }
        _playingStates.remove(audioFile);
        _hasUnsavedChanges = true;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds =
        (duration.inMilliseconds % 1000) ~/ 10; // Get centiseconds
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }
}
