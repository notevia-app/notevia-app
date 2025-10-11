import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/note.dart';
import '../providers/theme_provider.dart' as providers;
import '../services/database_service.dart';
import 'note_add_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/modern_popup.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final int? initialFilterIndex;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.initialFilterIndex,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note currentNote;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseService _databaseService = DatabaseService();
  bool _isPlaying = false;
  String? _currentPlayingFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final Map<String, bool> _playingStates = {};
  int _selectedFilterIndex = 0; // 0: Okuma Modu, 1: Sesli Notlarım
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    currentNote = widget.note;
    _selectedFilterIndex = widget.initialFilterIndex ?? 0;
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        if (_currentPlayingFile != null) {
          _playingStates[_currentPlayingFile!] = false;
        }
        _currentPlayingFile = null;
        _currentPosition = Duration.zero;
      });
    });
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      if (_currentPlayingFile == audioPath && _isPlaying) {
        // Pause the current audio
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
          _playingStates[audioPath] = false;
        });
      } else {
        // Stop any currently playing audio
        if (_currentPlayingFile != null && _currentPlayingFile != audioPath) {
          await _audioPlayer.stop();
          _playingStates[_currentPlayingFile!] = false;
        }

        // If this is a different file or resuming the same file
        if (_currentPlayingFile != audioPath) {
          // Play new file from beginning
          await _audioPlayer.play(DeviceFileSource(audioPath));
        } else {
          // Resume the same file from current position
          await _audioPlayer.resume();
        }
        
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
        setState(() {
          _isPlaying = true;
          _currentPlayingFile = audioPath;
          _playingStates[audioPath] = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.audioPlaybackFailed}: $e',
          ),
        ),
      );
    }
  }

  Future<void> _deleteAudioFile(int index, String audioPath) async {
    // Onay mesajı göster
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteAudioFile),
          content: Text(
            AppLocalizations.of(context)!.deleteAudioFileConfirmation,
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
        );
      },
    );

    // Kullanıcı iptal ettiyse işlemi durdur
    if (shouldDelete != true) return;

    try {
      if (_currentPlayingFile == audioPath) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _currentPlayingFile = null;
          _playingStates.remove(audioPath);
        });
      }

      final file = File(audioPath);
      if (await file.exists()) {
        await file.delete();
      }

      final updatedAudioFiles = List<String>.from(currentNote.audioFiles);
      updatedAudioFiles.removeAt(index);

      final updatedNote = currentNote.copyWith(
        audioFiles: updatedAudioFiles,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateNote(updatedNote);

      setState(() {
        currentNote = updatedNote;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.audioFileDeleted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.audioFileDeletionFailed}: $e',
          ),
        ),
      );
    }
  }

  Future<void> _seekForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition < _totalDuration) {
      await _audioPlayer.seek(newPosition);
    }
  }

  Future<void> _seekBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> _seekToPosition(Duration position) async {
    if (position <= _totalDuration) {
      await _audioPlayer.seek(position);
    }
  }

  Future<void> _changePlaybackSpeed() async {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });

    if (_isPlaying) {
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<providers.ThemeProvider>(context);
    final backgroundColor = _getBackgroundColor();
    final textColor = _getTextColor();
    final iconColor = _getIconColor();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _showShareModal,
                  icon: Icon(Icons.share, color: colorScheme.onSurface),
                ),
              ),

              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _editNote,
                  icon: Icon(Icons.edit, color: colorScheme.onSurface),
                ),
              ),
            ],
          ),

          // Filter Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFilterIndex == 0
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest.withOpacity(
                                  0.5,
                                ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: _selectedFilterIndex == 0
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.readingMode,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _selectedFilterIndex == 0
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFilterIndex == 1
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest.withOpacity(
                                  0.5,
                                ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: _selectedFilterIndex == 1
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.myVoiceNotes,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _selectedFilterIndex == 1
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _selectedFilterIndex == 0
                  ? _buildReadingMode()
                  : _buildAudioNotesMode(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(BuildContext context, ColorScheme colorScheme) {
    try {
      // Try to parse Quill document from JSON
      final doc = Document.fromJson(jsonDecode(currentNote.content));
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      return QuillEditor.basic(controller: controller);
    } catch (e) {
      // Fallback to plain text if JSON parsing fails
      return Text(
        currentNote.plainTextContent ?? currentNote.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          height: 1.6,
        ),
      );
    }
  }

  Widget _buildReadingMode() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                currentNote.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Date and status indicators
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(currentNote.updatedAt),
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (currentNote.isImportant)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                    ),
                  if (currentNote.isImportant && currentNote.isHidden)
                    const SizedBox(width: 8),
                  if (currentNote.isHidden)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Content Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.content,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFormattedContent(context, colorScheme),
            ],
          ),
        ),

        // Reminder info if set
        if (currentNote.reminderDateTime != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.reminder,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  currentNote.reminderDateTime!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                if (currentNote.repeatReminder) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.repeatReminder}: ${currentNote.repeatReminder ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Tags if any
        if (currentNote.tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.label, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.tags,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentNote.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAudioNotesMode() {
    final colorScheme = Theme.of(context).colorScheme;

    if (currentNote.audioFiles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.audiotrack_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noVoiceRecordingYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.audiotrack, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                '${AppLocalizations.of(context)!.myVoiceNotes} (${currentNote.audioFiles.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Audio Files List
        ...currentNote.audioFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final audioFile = entry.value;
          final isCurrentlyPlaying = _playingStates[audioFile] ?? false;
          final showProgressBar =
              _currentPlayingFile == audioFile;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audioFile.split('/').last,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (showProgressBar)
                            Text(
                              '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Bar with Slider
                if (showProgressBar) ...[
                  Row(
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _totalDuration.inMilliseconds > 0
                              ? _currentPosition.inMilliseconds.toDouble()
                              : 0.0,
                          max: _totalDuration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _seekToPosition(Duration(milliseconds: value.toInt()));
                          },
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Backward 10s
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: showProgressBar ? _seekBackward : null,
                        icon: const Icon(Icons.replay_10),
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Play/Pause
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _playAudio(audioFile),
                        icon: Icon(
                          isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                          size: 28,
                        ),
                        color: colorScheme.onPrimary,
                      ),
                    ),

                    // Forward 10s
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: showProgressBar ? _seekForward : null,
                        icon: const Icon(Icons.forward_10),
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Speed Control
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _changePlaybackSpeed,
                        icon: Text(
                          '${_playbackSpeed}x',
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Delete
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _deleteAudioFile(index, audioFile),
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getBackgroundColor() {
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        return const Color(0xFFF8F9FA);
      case ThemeMode.dark:
        return const Color(0xFF1A1A1A);
      default:
        return Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFF8F9FA)
            : const Color(0xFF1A1A1A);
    }
  }

  Color _getTextColor() {
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        return const Color(0xFF2C3E50);
      case ThemeMode.dark:
        return const Color(0xFFE8E8E8);
      default:
        return Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF2C3E50)
            : const Color(0xFFE8E8E8);
    }
  }

  Color _getIconColor() {
    final themeProvider = Provider.of<providers.ThemeProvider>(
      context,
      listen: false,
    );
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        return const Color(0xFF34495E);
      case ThemeMode.dark:
        return const Color(0xFFBDC3C7);
      default:
        return Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF34495E)
            : const Color(0xFFBDC3C7);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getRepeatTypeText(String repeatType) {
    switch (repeatType) {
      case 'daily':
        return AppLocalizations.of(context)!.daily;
      case 'weekly':
        return AppLocalizations.of(context)!.weekly;
      case 'monthly':
        return AppLocalizations.of(context)!.monthly;
      case 'yearly':
        return AppLocalizations.of(context)!.yearly;
      default:
        return AppLocalizations.of(context)!.none;
    }
  }

  void _editNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NoteAddScreen(note: currentNote, isNewNote: false),
      ),
    ).then((updatedNote) {
      if (updatedNote != null) {
        setState(() {
          currentNote = updatedNote;
        });
      }
    });
  }

  void _showShareModal() {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.share,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Format seçimi
            Text(
              localizations.shareFormat,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Format butonları
            Row(
              children: [
                Expanded(
                  child: _buildFormatButton(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _shareAsPdfToPlatform('general');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormatButton(
                    icon: Icons.text_snippet,
                    label: 'TXT',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _shareAsTxtToPlatform('general');
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // İndirme seçenekleri
            Text(
              localizations.downloadToDevice,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // İndirme butonları
            Row(
              children: [
                Expanded(
                  child: _buildDownloadButton(
                    icon: Icons.download,
                    label: 'PDF İndir',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _downloadAsPdf();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDownloadButton(
                    icon: Icons.download,
                    label: 'TXT İndir',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _downloadAsTxt();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  void _showPlatformSelectionModal(String format) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${format.toUpperCase()} ile Paylaş',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Platform seçimi
            Text(
              'Platform Seçin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Platform ikonları grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildSharePlatformItem(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    _shareToSpecificPlatform('whatsapp', format);
                  },
                ),
                _buildSharePlatformItem(
                  icon: Icons.email,
                  label: 'Gmail',
                  color: const Color(0xFFEA4335),
                  onTap: () {
                    Navigator.pop(context);
                    _shareToSpecificPlatform('gmail', format);
                  },
                ),
                _buildSharePlatformItem(
                  icon: Icons.email_outlined,
                  label: 'Outlook',
                  color: const Color(0xFF0078D4),
                  onTap: () {
                    Navigator.pop(context);
                    _shareToSpecificPlatform('outlook', format);
                  },
                ),
                _buildSharePlatformItem(
                  icon: Icons.cloud,
                  label: 'Drive',
                  color: const Color(0xFF4285F4),
                  onTap: () {
                    Navigator.pop(context);
                    _shareToSpecificPlatform('drive', format);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormatButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSharePlatformItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDownloadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yeni paylaşma platformları fonksiyonları
  void _shareToSpecificPlatform(String platform, String format) async {
    try {
      if (format == 'pdf') {
        await _shareAsPdfToPlatform(platform);
      } else {
        await _shareAsTxtToPlatform(platform);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getPlatformName(platform)} paylaşımı başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareAsPdfToPlatform(String platform) async {
    try {
      final pdf = pw.Document();

      // PDF içeriği oluştur
      final content = _cleanContent(currentNote.content);
      final lines = content.split('\n');
      const maxLinesPerPage = 35;
      final pageCount = (lines.length / maxLinesPerPage).ceil();

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final startIndex = pageIndex * maxLinesPerPage;
        final endIndex = (startIndex + maxLinesPerPage < lines.length)
            ? startIndex + maxLinesPerPage
            : lines.length;
        final pageLines = lines.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (pageIndex == 0) ...
                  [
                    pw.Text(
                      currentNote.title,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                  pw.Expanded(
                    child: pw.Text(
                      pageLines.join('\n'),
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Sayfa ${pageIndex + 1} / $pageCount',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Geçici dosya oluştur
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${currentNote.title}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Platforma göre paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: currentNote.title,
      );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.pdfSharedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.pdfShareFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareAsTxtToPlatform(String platform) async {
    try {
      // UTF-8 BOM ekle
      const utf8Bom = [0xEF, 0xBB, 0xBF];
      final content = '${currentNote.title}\n\n${_cleanContent(currentNote.content)}';
      final contentBytes = utf8.encode(content);
      final finalBytes = Uint8List.fromList([...utf8Bom, ...contentBytes]);

      // Geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${currentNote.title}.txt');
      await file.writeAsBytes(finalBytes);

      // Platforma göre paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: currentNote.title,
      );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.txtSharedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.txtShareFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPlatformName(String platform) {
    switch (platform) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'gmail':
        return 'Gmail';
      case 'outlook':
        return 'Outlook';
      case 'drive':
        return 'Drive';
      default:
        return platform;
    }
  }

  // İndirme fonksiyonları
  Future<void> _downloadAsPdf() async {
    try {
      final pdf = pw.Document();

      // Roboto fontunu yükle
      final robotoRegular = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final robotoBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final robotoItalic = await rootBundle.load(
        'assets/fonts/Roboto-Italic.ttf',
      );
      final robotoBoldItalic = await rootBundle.load(
        'assets/fonts/Roboto-BoldItalic.ttf',
      );

      final regularFont = pw.Font.ttf(robotoRegular);
      final boldFont = pw.Font.ttf(robotoBold);
      final italicFont = pw.Font.ttf(robotoItalic);
      final boldItalicFont = pw.Font.ttf(robotoBoldItalic);

      // Quill Delta formatını parse et ve biçimlendirilmiş içerik oluştur
      final formattedContent = _parseQuillToPdf(
        currentNote.content,
        regularFont,
        boldFont,
        italicFont,
        boldItalicFont,
      );

      // Çok sayfalı PDF oluştur
      _addMultiPageContent(
        pdf,
        currentNote.title,
        formattedContent,
        regularFont,
        boldFont,
        italicFont,
        boldItalicFont,
      );

      // İndirilenler klasörüne kaydet
       Directory? directory;
       if (Platform.isAndroid) {
         directory = Directory('/storage/emulated/0/Download');
       } else {
         directory = await getDownloadsDirectory();
       }
       
       if (directory != null && !await directory.exists()) {
         await directory.create(recursive: true);
       }
       
       final file = File('${directory!.path}/${currentNote.title}.pdf');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.pdfDownloadedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.pdfDownloadError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAsTxt() async {
    try {
      // İndirilenler klasörüne kaydet
       Directory? directory;
       if (Platform.isAndroid) {
         directory = Directory('/storage/emulated/0/Download');
       } else {
         directory = await getDownloadsDirectory();
       }
       
       if (directory != null && !await directory.exists()) {
         await directory.create(recursive: true);
       }
       
       final file = File('${directory!.path}/${currentNote.title}.txt');
      
      // İçeriği temizle
      String cleanedContent = _cleanContent(currentNote.content);
      
      // Türkçe karakterleri normalize et
      cleanedContent = cleanedContent
          .replaceAll(RegExp(r'[Ä±Ã±]'), 'ı')
          .replaceAll(RegExp(r'[Ã§Ã‡]'), 'ç')
          .replaceAll(RegExp(r'[Ã¶Ã–]'), 'ö')
          .replaceAll(RegExp(r'[Ã¼Ãœ]'), 'ü')
          .replaceAll(RegExp(r'[ÅŸÅž]'), 'ş')
          .replaceAll(RegExp(r'[Ä\u009fÄž]'), 'ğ');
      
      final content = '${currentNote.title}\n\n$cleanedContent';

      // UTF-8 BOM ile yaz
      final bytes = utf8.encode(content);
      final bomBytes = [0xEF, 0xBB, 0xBF] + bytes;
      await file.writeAsBytes(bomBytes);

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.txtDownloadedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.txtDownloadError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareAsPdf() async {
    try {
      final pdf = pw.Document();

      // Roboto fontunu yükle
      final robotoRegular = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final robotoBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final robotoItalic = await rootBundle.load(
        'assets/fonts/Roboto-Italic.ttf',
      );
      final robotoBoldItalic = await rootBundle.load(
        'assets/fonts/Roboto-BoldItalic.ttf',
      );

      final regularFont = pw.Font.ttf(robotoRegular);
      final boldFont = pw.Font.ttf(robotoBold);
      final italicFont = pw.Font.ttf(robotoItalic);
      final boldItalicFont = pw.Font.ttf(robotoBoldItalic);

      // Quill Delta formatını parse et ve biçimlendirilmiş içerik oluştur
      final formattedContent = _parseQuillToPdf(
        currentNote.content,
        regularFont,
        boldFont,
        italicFont,
        boldItalicFont,
      );

      // Çok sayfalı PDF oluştur
      _addMultiPageContent(
        pdf,
        currentNote.title,
        formattedContent,
        regularFont,
        boldFont,
        italicFont,
        boldItalicFont,
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${currentNote.title}.pdf');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: currentNote.title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pdfDownloaded),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.pdfDownloadError}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareAsTxt() async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${currentNote.title}.txt');
      
      // İçeriği temizle
      String cleanedContent = _cleanContent(currentNote.content);
      
      // Türkçe karakterleri normalize et
      cleanedContent = cleanedContent
          // Önce bozuk karakterleri temizle
          .replaceAll(RegExp(r'[Ä±Ã±]'), 'ı')
          .replaceAll(RegExp(r'[Ã§Ã‡]'), 'ç')
          .replaceAll(RegExp(r'[Ã¶Ã–]'), 'ö')
          .replaceAll(RegExp(r'[Ã¼Ãœ]'), 'ü')
          .replaceAll(RegExp(r'[ÅŸÅž]'), 'ş')
          .replaceAll(RegExp(r'[Ä\u009fÄž]'), 'ğ')
          .replaceAll(RegExp(r'[Ä°Ä°]'), 'İ')
          .replaceAll(RegExp(r'[Ä\u009eÄž]'), 'Ğ')
          .replaceAll(RegExp(r'[Ã\u0096Ã–]'), 'Ö')
          .replaceAll(RegExp(r'[Ã\u009cÃœ]'), 'Ü')
          .replaceAll(RegExp(r'[Ã\u0087Ã‡]'), 'Ç')
          .replaceAll(RegExp(r'[Å\u009eÅž]'), 'Ş')
          // Sonra doğru karakterleri koy
          .replaceAll('Ä±', 'ı')
          .replaceAll('Ã§', 'ç')
          .replaceAll('Ã¶', 'ö')
          .replaceAll('Ã¼', 'ü')
          .replaceAll('ÅŸ', 'ş')
          .replaceAll('Ä\u009f', 'ğ')
          .replaceAll('Ä°', 'İ')
          .replaceAll('Ä\u009e', 'Ğ')
          .replaceAll('Ã\u0096', 'Ö')
          .replaceAll('Ã\u009c', 'Ü')
          .replaceAll('Ã\u0087', 'Ç')
          .replaceAll('Å\u009e', 'Ş');
      
      final content = '${currentNote.title}\n\n$cleanedContent';

      // UTF-8 BOM ile yaz
      final bytes = utf8.encode(content);
      final bomBytes = [0xEF, 0xBB, 0xBF] + bytes;
      await file.writeAsBytes(bomBytes);

      await Share.shareXFiles([XFile(file.path)], text: currentNote.title);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('TXT paylaşımında hata: $e')));
    }
  }

  void _addMultiPageContent(
    pw.Document pdf,
    String title,
    List<pw.Widget> content,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
    pw.Font boldItalicFont,
  ) {
    // A4 sayfa boyutları (595 x 842 points)
    const double pageHeight = 1200; // A4 yüksekliği
    const double topMargin = 50; // Üst margin
    const double bottomMargin = 50; // Alt margin
    const double titleHeight = 40; // Başlık için ayrılan alan
    const double availableHeight =
        pageHeight -
        topMargin -
        bottomMargin -
        titleHeight -
        20; // İçerik için kullanılabilir alan
    const double lineHeight = 14; // Daha küçük satır yüksekliği
    final int maxLinesPerPage = (availableHeight / lineHeight).floor();

    if (content.isEmpty) {
      // Boş içerik için tek sayfa
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(50),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'İçerik bulunamadı.',
                  style: pw.TextStyle(font: regularFont, fontSize: 12),
                ),
              ],
            );
          },
        ),
      );
      return;
    }

    // İçeriği sayfalara böl
    List<List<pw.Widget>> pages = [];
    List<pw.Widget> currentPage = [];
    int currentLines = 0;

    for (pw.Widget widget in content) {
      // Her widget için tahmini satır sayısını hesapla
      int estimatedLines = 1;
      if (widget is pw.RichText) {
        // RichText için metin uzunluğuna göre satır sayısını tahmin et
        String text = _extractTextFromRichText(widget);
        estimatedLines = (text.length / 80).ceil().clamp(
          1,
          10,
        ); // 80 karakter = 1 satır
      }

      // Eğer bu widget eklenirse sayfa sınırını aşacaksa yeni sayfa başlat
      if (currentLines + estimatedLines > maxLinesPerPage &&
          currentPage.isNotEmpty) {
        pages.add(List.from(currentPage));
        currentPage.clear();
        currentLines = 0;
      }

      currentPage.add(widget);
      currentLines += estimatedLines;
    }

    // Son sayfayı ekle
    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    // Sayfaları PDF'e ekle
    for (int i = 0; i < pages.length; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(50),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // İlk sayfada başlık göster
                if (i == 0) ...[
                  pw.Text(
                    title
                        .replaceAll('Ä±', 'ı')
                        .replaceAll('Ã§', 'ç')
                        .replaceAll('Ã¶', 'ö')
                        .replaceAll('Ã¼', 'ü')
                        .replaceAll('ÅŸ', 'ş')
                        .replaceAll('Ä\u009f', 'ğ')
                        .replaceAll('Ä°', 'İ')
                        .replaceAll('Ä\u009e', 'Ğ')
                        .replaceAll('Ã\u0096', 'Ö')
                        .replaceAll('Ã\u009c', 'Ü')
                        .replaceAll('Ã\u0087', 'Ç')
                        .replaceAll('Å\u009e', 'Ş'),
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                ],
                // Sayfa içeriği
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: pages[i],
                  ),
                ),
                // Sayfa numarası (birden fazla sayfa varsa)
                if (pages.length > 1)
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      '${i + 1} / ${pages.length}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }
  }

  String _extractTextFromRichText(pw.RichText richText) {
    // RichText'ten metin çıkar (basit implementasyon)
    try {
      if (richText.text is pw.TextSpan) {
        return _extractTextFromSpan(richText.text as pw.TextSpan);
      }
    } catch (e) {
      // Hata durumunda varsayılan uzunluk döndür
    }
    return 'Sample text'; // Varsayılan metin
  }

  String _extractTextFromSpan(pw.TextSpan span) {
    String text = span.text ?? '';
    if (span.children != null) {
      for (var child in span.children!) {
        if (child is pw.TextSpan) {
          text += _extractTextFromSpan(child);
        }
      }
    }
    return text;
  }

  List<pw.Widget> _parseQuillToPdf(
    String content,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
    pw.Font boldItalicFont,
  ) {
    List<pw.Widget> widgets = [];

    try {
      // Quill Delta formatını parse et
      if (content.contains('[{"insert":')) {
        final List<dynamic> jsonList = jsonDecode(content);
        List<pw.InlineSpan> spans = [];

        for (final item in jsonList) {
          if (item is Map<String, dynamic> && item.containsKey('insert')) {
            final insertValue = item['insert'];
            final attributes = item['attributes'] as Map<String, dynamic>?;

            if (insertValue is String) {
              // Satır sonlarını kontrol et
              if (insertValue.contains('\n')) {
                final parts = insertValue.split('\n');
                for (int i = 0; i < parts.length; i++) {
                  if (parts[i].isNotEmpty) {
                    spans.add(
                      _createTextSpan(
                        parts[i],
                        attributes,
                        regularFont,
                        boldFont,
                        italicFont,
                        boldItalicFont,
                      ),
                    );
                  }

                  // Satır sonu varsa ve son parça değilse yeni satır ekle
                  if (i < parts.length - 1) {
                    if (spans.isNotEmpty) {
                      widgets.add(
                        pw.RichText(text: pw.TextSpan(children: spans)),
                      );
                      spans = [];
                    }
                    widgets.add(pw.SizedBox(height: 4)); // Satır arası boşluk
                  }
                }
              } else {
                spans.add(
                  _createTextSpan(
                    insertValue,
                    attributes,
                    regularFont,
                    boldFont,
                    italicFont,
                    boldItalicFont,
                  ),
                );
              }
            }
          }
        }

        // Kalan span'ları ekle
        if (spans.isNotEmpty) {
          widgets.add(pw.RichText(text: pw.TextSpan(children: spans)));
        }
      } else {
        // Düz metin ise - Türkçe karakterleri düzelt
        String cleanContent = content
            .replaceAll('Ä±', 'ı')
            .replaceAll('Ã§', 'ç')
            .replaceAll('Ã¶', 'ö')
            .replaceAll('Ã¼', 'ü')
            .replaceAll('ÅŸ', 'ş')
            .replaceAll('Ä\u009f', 'ğ')
            .replaceAll('Ä°', 'İ')
            .replaceAll('Ä\u009e', 'Ğ')
            .replaceAll('Ã\u0096', 'Ö')
            .replaceAll('Ã\u009c', 'Ü')
            .replaceAll('Ã\u0087', 'Ç')
            .replaceAll('Å\u009e', 'Ş');
        
        widgets.add(
          pw.Text(
            cleanContent,
            style: pw.TextStyle(font: regularFont, fontSize: 12),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda düz metin olarak göster - Türkçe karakterleri düzelt
      String cleanContent = content
          .replaceAll('Ä±', 'ı')
          .replaceAll('Ã§', 'ç')
          .replaceAll('Ã¶', 'ö')
          .replaceAll('Ã¼', 'ü')
          .replaceAll('ÅŸ', 'ş')
          .replaceAll('Ä\u009f', 'ğ')
          .replaceAll('Ä°', 'İ')
          .replaceAll('Ä\u009e', 'Ğ')
          .replaceAll('Ã\u0096', 'Ö')
          .replaceAll('Ã\u009c', 'Ü')
          .replaceAll('Ã\u0087', 'Ç')
          .replaceAll('Å\u009e', 'Ş');
      
      widgets.add(
        pw.Text(cleanContent, style: pw.TextStyle(font: regularFont, fontSize: 12)),
      );
    }

    return widgets.isEmpty
        ? [pw.Text('', style: pw.TextStyle(font: regularFont, fontSize: 12))]
        : widgets;
  }

  pw.TextSpan _createTextSpan(
    String text,
    Map<String, dynamic>? attributes,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
    pw.Font boldItalicFont,
  ) {
    bool isBold = attributes?['bold'] == true;
    bool isItalic = attributes?['italic'] == true;
    bool isUnderline = attributes?['underline'] == true;

    pw.Font font;
    if (isBold && isItalic) {
      font = boldItalicFont;
    } else if (isBold) {
      font = boldFont;
    } else if (isItalic) {
      font = italicFont;
    } else {
      font = regularFont;
    }

    // Türkçe karakterleri düzelt
    String cleanText = text
        .replaceAll('Ä±', 'ı')
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ã¶', 'ö')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('ÅŸ', 'ş')
        .replaceAll('Ä\u009f', 'ğ')
        .replaceAll('Ä°', 'İ')
        .replaceAll('Ä\u009e', 'Ğ')
        .replaceAll('Ã\u0096', 'Ö')
        .replaceAll('Ã\u009c', 'Ü')
        .replaceAll('Ã\u0087', 'Ç')
        .replaceAll('Å\u009e', 'Ş');

    return pw.TextSpan(
      text: cleanText,
      style: pw.TextStyle(
        font: font,
        fontSize: 12,
        decoration: isUnderline ? pw.TextDecoration.underline : null,
      ),
    );
  }

  String _cleanContent(String content) {
    try {
      // Önce UTF-8 encoding sorununu çöz
      String fixedContent = content;

      // Yaygın UTF-8 encoding sorunlarını düzelt
      final Map<String, String> encodingFixes = {
        'Ä±': 'ı',
        'Ã§': 'ç',
        'Ã¶': 'ö',
        'Ã¼': 'ü',
        'ÅŸ': 'ş',
        'Ä\u009f': 'ğ',
        'Ä°': 'İ',
        'Ä\u009e': 'Ğ',
        'Ã\u0096': 'Ö',
        'Ã\u009c': 'Ü',
        'Ã\u0087': 'Ç',
        'Å\u009e': 'Ş',
      };

      encodingFixes.forEach((wrong, correct) {
        fixedContent = fixedContent.replaceAll(wrong, correct);
      });

      // Quill formatındaki JSON yapısını temizle
      if (fixedContent.contains('[{"insert":')) {
        try {
          // JSON olarak parse etmeyi dene
          final List<dynamic> jsonList = jsonDecode(fixedContent);
          String cleanedContent = '';

          for (final item in jsonList) {
            if (item is Map<String, dynamic> && item.containsKey('insert')) {
              final insertValue = item['insert'];
              if (insertValue is String) {
                cleanedContent += insertValue;
              }
            }
          }

          return cleanedContent.isNotEmpty ? cleanedContent : fixedContent;
        } catch (jsonError) {
          // JSON parse başarısız olursa regex kullan
          final regex = RegExp(
            r'\{"insert":"([^"]*?)"[^}]*\}',
            multiLine: true,
          );
          final matches = regex.allMatches(fixedContent);
          if (matches.isNotEmpty) {
            String cleanedContent = '';
            for (final match in matches) {
              final text = match.group(1) ?? '';
              // Unicode escape karakterlerini düzelt
              String decodedText = text
                  .replaceAll('\\n', '\n')
                  .replaceAll('\\t', '\t')
                  .replaceAll('\\r', '\r')
                  .replaceAll('\\"', '"')
                  .replaceAll('\\\\', '\\');
              cleanedContent += decodedText;
            }
            return cleanedContent.isNotEmpty ? cleanedContent : fixedContent;
          }
        }
      }

      // Basit JSON temizleme
      String cleaned = fixedContent
          .replaceAll(RegExp(r'\[\{"insert":"'), '')
          .replaceAll(RegExp(r'"[^}]*\}[^\]]*\]'), '')
          .replaceAll('\\n', '\n')
          .replaceAll('\\t', '\t')
          .replaceAll('\\"', '"');

      return cleaned.trim().isNotEmpty ? cleaned.trim() : fixedContent;
    } catch (e) {
      return content;
    }
  }
}
