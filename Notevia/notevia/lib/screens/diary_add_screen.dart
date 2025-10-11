import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart' as providers;
import 'diary_detail_screen.dart';
import 'package:intl/intl.dart';

class DiaryAddScreen extends StatefulWidget {
  final Diary? diary;
  final bool isNewDiary;

  const DiaryAddScreen({super.key, this.diary, this.isNewDiary = true});

  @override
  State<DiaryAddScreen> createState() => _DiaryAddScreenState();
}

class _DiaryAddScreenState extends State<DiaryAddScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  late QuillController _contentController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();

  final DatabaseService _databaseService = DatabaseService();

  late AnimationController _toolbarAnimationController;
  late Animation<Offset> _toolbarSlideAnimation;

  bool _isSaving = false;
  final bool _isToolbarVisible = true;
  bool _hasUnsavedChanges = false;

  int? _backgroundColor;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _loadDiary();
  }

  void _initializeControllers() {
    _contentController = QuillController.basic();
    _contentController.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      }
    });

    _titleController.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      }
    });
  }

  void _setupAnimations() {
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _toolbarSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _toolbarAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _toolbarAnimationController.forward();
  }

  void _loadDiary() {
    if (widget.diary != null) {
      _titleController.text = widget.diary!.title;
      _backgroundColor = widget.diary!.backgroundColor;
      _selectedDate = widget.diary!.date;

      if (widget.diary!.content.isNotEmpty) {
        try {
          final doc = Document.fromJson(jsonDecode(widget.diary!.content));
          _contentController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          _contentController.document.insert(0, widget.diary!.content);
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _getBackgroundColor(),
          title: Text(
            AppLocalizations.of(context)!.saveChanges,
            style: TextStyle(color: _getTextColor()),
          ),
          content: Text(
            AppLocalizations.of(context)!.unsavedChangesMessage,
            style: TextStyle(color: _getTextColor()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: _getIconColor())),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.exit, style: TextStyle(color: Colors.red)),
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

  Future<void> _saveDiary() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // İçerik kontrolü - boş içerik durumunda özel işlem
      String content;
      final plainText = _contentController.document.toPlainText().trim();
      
      if (plainText.isEmpty) {
        // İçerik boşsa boş string olarak kaydet
        content = '';
      } else {
        // Normal içerik varsa JSON formatında kaydet
        content = jsonEncode(
          _contentController.document.toDelta().toJson(),
        );
      }
      
      // Arkaplan rengi artık kullanılmıyor
      _backgroundColor = null;

      final diary = Diary(
        id: widget.diary?.id,
        title: _titleController.text.trim().isEmpty
            ? AppLocalizations.of(context)!.untitledDiary
            : _titleController.text.trim(),
        content: content,
        plainTextContent: plainText,
        date: _selectedDate,
        createdAt: widget.diary?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        backgroundColor: _backgroundColor,
      );

      if (widget.isNewDiary) {
        await _databaseService.insertDiary(diary);
      } else {
        await _databaseService.updateDiary(diary);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.diarySaved),
          backgroundColor: Colors.green,
        ),
      );

      // Günlük kaydedildiğini belirt ve önceki sayfaya dön
      Navigator.of(context).pop(true);
  } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Color _getBackgroundColor() {
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );
    final colorScheme = Theme.of(context).colorScheme;
    
    // Varsayılan olarak tema rengini kullan
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        return colorScheme.surface;
      case ThemeMode.dark:
        return colorScheme.surface;
      default:
        return Theme.of(context).brightness == Brightness.light
            ? colorScheme.surface
            : colorScheme.surface;
    }
  }

  Color _getTextColor() {
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        return colorScheme.onSurface;
      case ThemeMode.dark:
        return colorScheme.onSurface;
      default:
        return Theme.of(context).brightness == Brightness.light
            ? colorScheme.onSurface
            : colorScheme.onSurface;
    }
  }

  Color _getIconColor() {
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        return colorScheme.onSurface.withOpacity(0.7);
      case ThemeMode.dark:
        return colorScheme.onSurface.withOpacity(0.7);
      default:
        return Theme.of(context).brightness == Brightness.light
            ? colorScheme.onSurface.withOpacity(0.7)
            : colorScheme.onSurface.withOpacity(0.7);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    _contentFocusNode.dispose();
    _titleFocusNode.dispose();
    _toolbarAnimationController.dispose();
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
                  _buildDateHeader(),
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
                ],
              ),
              _buildFloatingToolbar(iconColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color iconColor) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _onBackPressed,
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          ),
          Expanded(
            child: Text(
              widget.isNewDiary ? AppLocalizations.of(context)!.newDiary : AppLocalizations.of(context)!.editDiary,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _saveDiary,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  )
                : Icon(Icons.save, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd MMMM yyyy, EEEE', Localizations.localeOf(context).toString()).format(_selectedDate),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextField(
      controller: _titleController,
      maxLines: null,
      textInputAction: TextInputAction.newline,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.diaryTitlePlaceholder,
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return QuillEditor.basic(
      controller: _contentController,
      focusNode: _contentFocusNode,
      config: QuillEditorConfig(
        padding: EdgeInsets.zero,
        placeholder: AppLocalizations.of(context)!.diaryContentPlaceholder,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            TextStyle(fontSize: 16, color: colorScheme.onSurface),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }



  Widget _buildFloatingToolbar(Color iconColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar
          SlideTransition(
            position: _toolbarSlideAnimation,
            child: Container(
              height: 65,
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
                    multiRowsDisplay: false,
                    showDividers: false,
                    showFontFamily: false,
                    showFontSize: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showInlineCode: true,
                    showColorButton: true,
                    showBackgroundColorButton: true,
                    showClearFormat: true,
                    showAlignmentButtons: false,
                    showLeftAlignment: false,
                    showCenterAlignment: false,
                    showRightAlignment: false,
                    showJustifyAlignment: false,
                    showHeaderStyle: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: true,
                    showCodeBlock: true,
                    showQuote: true,
                    showIndent: true,
                    showLink: true,
                    showUndo: true,
                    showRedo: true,
                    showDirection: false,
                    showSearchButton: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
