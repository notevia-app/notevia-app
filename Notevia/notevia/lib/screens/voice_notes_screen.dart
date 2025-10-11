import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart' as providers;
import 'dart:io';
import 'package:intl/intl.dart';

class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();

  List<Note> _voiceNotes = [];
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingPath;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadVoiceNotes();
    _setupAudioPlayer();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _player.onDurationChanged.listen((duration) {
      setState(() {
        _playbackDuration = duration;
      });
    });

    _player.onPositionChanged.listen((position) {
      setState(() {
        _playbackPosition = position;
      });
    });

    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentPlayingPath = null;
        _playbackPosition = Duration.zero;
      });
    });
  }

  Future<void> _loadVoiceNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _databaseService.getNotes();
      final voiceNotes = notes
          .where((note) => note.audioFiles.isNotEmpty)
          .toList();

      setState(() {
        _voiceNotes = voiceNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.voiceNoteLoadingError}: $e')),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.microphonePermissionRequired)));
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = '${directory.path}/$fileName';

      await _recorder.startRecorder(
        toFile: _recordingPath!,
        codec: Codec.aacMP4,
        bitRate: 128000, // 128 kbps yüksek kalite
        sampleRate: 44100, // CD kalitesi sample rate
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start duration timer
      _startRecordingTimer();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.recordingStartErrorMessage}: $e')));
    }
  }

  void _startRecordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + 1,
          );
        });
        _startRecordingTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (_recordingPath != null) {
        _showSaveRecordingDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.recordingStopErrorMessage}: $e')));
    }
  }

  void _showSaveRecordingDialog() {
    final titleController = TextEditingController(
      text:
          '${AppLocalizations.of(context)!.voiceNoteTitle} - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.saveVoiceNote),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.noteTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.duration}: ${_formatDuration(_recordingDuration)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Delete the recording file
              if (_recordingPath != null) {
                File(_recordingPath!).deleteSync();
              }
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveVoiceNote(titleController.text.trim());
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVoiceNote(String title) async {
    if (_recordingPath == null) return;

    try {
      final now = DateTime.now();
      final note = Note(
        id: now.millisecondsSinceEpoch,
        title: title.isEmpty ? AppLocalizations.of(context)!.untitledVoiceNote : title,
        content: '',
        plainTextContent: '${AppLocalizations.of(context)!.voiceNoteTitle} - ${_formatDuration(_recordingDuration)}',
        createdAt: now,
        updatedAt: now,
        audioFiles: [_recordingPath!],
      );

      await _databaseService.insertNote(note);
      _loadVoiceNotes();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.voiceNoteSaved)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.saveError}: $e')));
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      if (_isPlaying && _currentPlayingPath == path) {
        await _player.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_isPlaying) {
          await _player.stop();
        }

        await _player.play(DeviceFileSource(path));
        setState(() {
          _isPlaying = true;
          _currentPlayingPath = path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.playbackError}: $e')));
    }
  }

  Future<void> _deleteVoiceNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteVoiceNote),
        content: Text(
          '"${note.title}" ${AppLocalizations.of(context)!.deleteVoiceNoteConfirmation}',
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
        // Delete audio files
        for (final audioPath in note.audioFiles) {
          final file = File(audioPath);
          if (await file.exists()) {
            await file.delete();
          }
        }

        if (note.id != null) {
          await _databaseService.deleteNote(note.id!);
        }
        _loadVoiceNotes();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.voiceNoteDeleted)));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.deleteError}: $e')));
      }
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.voiceNotes),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVoiceNotes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Recording controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: Column(
              children: [
                if (_isRecording) ...[
                  Text(
                    '${AppLocalizations.of(context)!.recordingDuration}: ${_formatDuration(_recordingDuration)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.large(
                      onPressed: _isRecording
                          ? _stopRecording
                          : _startRecording,
                      backgroundColor: _isRecording
                          ? Colors.red
                          : colorScheme.primary,
                      foregroundColor: Colors.white,
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  _isRecording ? AppLocalizations.of(context)!.stopRecording : AppLocalizations.of(context)!.startRecording,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Voice notes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _voiceNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noVoiceNotesYet,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.recordFirstVoiceNote,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _voiceNotes.length,
                    itemBuilder: (context, index) {
                      final note = _voiceNotes[index];
                      final audioPath = note.audioFiles.first;
                      final isCurrentlyPlaying =
                          _currentPlayingPath == audioPath && _isPlaying;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteVoiceNote(note);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(AppLocalizations.of(context)!.delete),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                DateFormat(
                                  'dd MMMM yyyy, HH:mm',
                                  'tr_TR',
                                ).format(note.createdAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                              ),

                              const SizedBox(height: 16),

                              // Audio player controls
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _playAudio(audioPath),
                                    icon: Icon(
                                      isCurrentlyPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 32,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isCurrentlyPlaying &&
                                            _playbackDuration.inSeconds > 0)
                                          LinearProgressIndicator(
                                            value:
                                                _playbackPosition.inSeconds /
                                                _playbackDuration.inSeconds,
                                            backgroundColor: colorScheme
                                                .surfaceContainerHighest,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  colorScheme.primary,
                                                ),
                                          ),

                                        const SizedBox(height: 4),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              isCurrentlyPlaying
                                                  ? _formatDuration(
                                                      _playbackPosition,
                                                    )
                                                  : '00:00',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                            Text(
                                              isCurrentlyPlaying
                                                  ? _formatDuration(
                                                      _playbackDuration,
                                                    )
                                                  : note.plainTextContent
                                                            ?.replaceAll(
                                                              '${AppLocalizations.of(context)!.voiceNoteTitle} - ',
                                                              '',
                                                            ) ??
                                                        '',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
