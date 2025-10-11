import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary.dart';
import '../l10n/app_localizations.dart';

class DiaryCard extends StatelessWidget {
  final Diary diary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DiaryCard({
    super.key,
    required this.diary,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: diary.backgroundColor != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(diary.backgroundColor!).withOpacity(0.15),
                        Color(diary.backgroundColor!).withOpacity(0.08),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        colorScheme.surface,
                      ],
                    ),
              border: Border.all(
                color: diary.backgroundColor != null
                    ? Color(diary.backgroundColor!).withOpacity(0.2)
                    : colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: diary.backgroundColor != null
                              ? Color(diary.backgroundColor!).withOpacity(0.2)
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: diary.backgroundColor != null
                                  ? Color(diary.backgroundColor!)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd MMM yyyy',
                                Localizations.localeOf(context).toString(),
                              ).format(diary.date),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: diary.backgroundColor != null
                                    ? Color(diary.backgroundColor!)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Builder(
                              builder: (context) => Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.delete,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    diary.title.isEmpty ? AppLocalizations.of(context)!.untitledDiary : diary.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: diary.title.isEmpty
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6)
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (diary.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _getCleanContent(context, diary.content),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (diary.audioFiles.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic,
                                size: 14,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${diary.audioFiles.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.secure,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatTime(context, diary.updatedAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCleanContent(BuildContext context, String content) {
    if (content.isEmpty) {
      return AppLocalizations.of(context)!.noContent;
    }

    // Try to parse Quill JSON format first
    try {
      // Check if it's Quill JSON format
      if (content.startsWith('[{') && content.contains('"insert"')) {
        // Extract text from Quill JSON format
        final matches = RegExp(r'"insert":"([^"]*)"|"insert":([^,}]*)')
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

  String _formatTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes < 1) {
          return AppLocalizations.of(context)!.now;
        }
        return '${difference.inMinutes} ${AppLocalizations.of(context)!.minutesAgo}';
      }
      return DateFormat('HH:mm', Localizations.localeOf(context).toString()).format(date);
    } else if (difference.inDays == 1) {
      return '${AppLocalizations.of(context)!.yesterday} ${DateFormat('HH:mm', Localizations.localeOf(context).toString()).format(date)}';
    } else {
      return DateFormat('dd.MM HH:mm', Localizations.localeOf(context).toString()).format(date);
    }
  }
}
