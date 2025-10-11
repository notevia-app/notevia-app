import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/diary.dart';
import '../providers/theme_provider.dart' as providers;
import 'diary_add_screen.dart';
import '../l10n/app_localizations.dart';

class DiaryDetailScreen extends StatelessWidget {
  final Diary diary;

  const DiaryDetailScreen({super.key, required this.diary});

  String _getCleanContent(BuildContext context, String content) {
    if (content.isEmpty) {
      return AppLocalizations.of(context)!.noContent;
    }

    // Try to parse Quill JSON format first
    try {
      // Check if it's Quill JSON format
      if (content.startsWith('[{') && content.contains('"insert"')) {
        // Extract text from Quill JSON format
        final matches = RegExp(r'"insert":"([^"]*)"')
            .allMatches(content);
        
        String extractedText = '';
        for (final match in matches) {
          String? text = match.group(1) ?? match.group(2);
          if (text != null && text.isNotEmpty && text != '\\n') {
            extractedText += text + ' ';
          }
        }
        
        if (extractedText.isNotEmpty) {
          content = extractedText;
        }
      }
    } catch (e) {
      // If parsing fails, continue with regular cleaning
    }

    // Remove HTML tags and clean up the content
    String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('\\n', ' ') // Replace newlines
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple whitespaces with single space
        .trim();

    // If content is empty after cleaning, return a placeholder
    return cleanContent.isEmpty ? AppLocalizations.of(context)!.noContent : cleanContent;
  }

  Widget _buildFormattedContent(BuildContext context, ColorScheme colorScheme) {
    try {
      if (diary.content != null && diary.content!.isNotEmpty) {
        // Quill JSON formatında mı kontrol et
        if (diary.content!.startsWith('[{') && diary.content!.contains('"insert"')) {
          // Boş içerik kontrolü - sadece boş satır içeren JSON formatı
          if (diary.content == '[{"insert":"\n"}]' || diary.content == '[{"insert":"\\n"}]') {
            return Text(
              AppLocalizations.of(context)!.noContent,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            );
          }
          
          final doc = Document.fromJson(jsonDecode(diary.content!));
          final controller = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
          controller.readOnly = true;
          
          return QuillEditor.basic(
            controller: controller,
            config: QuillEditorConfig(
              padding: EdgeInsets.zero,
              customStyles: DefaultStyles(
                paragraph: DefaultTextBlockStyle(
                  TextStyle(fontSize: 16, color: colorScheme.onSurface, height: 1.6),
                  const HorizontalSpacing(0, 0),
                  const VerticalSpacing(0, 0),
                  const VerticalSpacing(0, 0),
                  null,
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // If parsing fails, fall back to plain text
    }
    
    // Fallback to plain text or empty content
    return Text(
      _getCleanContent(context, diary.content ?? ''),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        height: 1.6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<providers.ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = diary.backgroundColor != null
        ? Color(diary.backgroundColor!)
        : colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.diaryDetail,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Modern Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor.withOpacity(0.1),
                    backgroundColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: backgroundColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean Date Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: backgroundColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: backgroundColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'dd MMMM yyyy',
                              Localizations.localeOf(context).toString(),
                            ).format(diary.date),
                            style: TextStyle(
                              color: backgroundColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Clean Title Typography
                    Text(
                      diary.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            height: 1.3,
                            letterSpacing: 0.5,
                            fontSize: 28,
                          ),
                    ),

                    const SizedBox(height: 16),

                    // Minimal Metadata
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('HH:mm', Localizations.localeOf(context).toString()).format(diary.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (diary.updatedAt != diary.createdAt) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.edited,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Clean Content Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattedContent(context, colorScheme),
                  ],
                ),
              ),
            ),

            // Audio files section (if any)
            if (diary.audioFiles.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            color: backgroundColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.audioRecordings,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                  fontSize: 20,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: backgroundColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${diary.audioFiles.length}',
                              style: TextStyle(
                                color: backgroundColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...diary.audioFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final audioFile = entry.value;
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: index < diary.audioFiles.length - 1
                                ? 12
                                : 0,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: backgroundColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.audiotrack_rounded,
                                  color: backgroundColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ses Kaydı ${index + 1}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      audioFile.split('/').last,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.play_circle_rounded,
                                  color: backgroundColor,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 120), // Bottom padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) =>
                      DiaryAddScreen(diary: diary, isNewDiary: false),
                ),
              )
              .then((result) {
                if (result == true) {
                  Navigator.of(context).pop(true);
                }
              });
        },
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.edit_rounded, size: 24),
      ),
    );
  }
}
