import 'package:flutter/material.dart';
import '../models/note.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleImportant;
  final bool isSelected;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onToggleImportant,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getDisplayTitle(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getDisplayTitle(context) == AppLocalizations.of(context)!.voiceNote
                            ? Theme.of(context).colorScheme.primary
                            : (note.title.isEmpty
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6)
                                  : null),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isImportant)
                    Icon(Icons.star, color: Colors.amber, size: 20),
                  if (note.isHidden)
                    Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.outline,
                      size: 20,
                    ),
                  if (note.reminderDateTime != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  // Üç nokta menüsü kaldırıldı
                ],
              ),
              if (_shouldShowContent()) ...[
                const SizedBox(height: 8),
                Text(
                  _getDisplayContent(context),
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
                  if (note.audioFiles.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${note.audioFiles.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (note.tags.isNotEmpty) ...[
                    if (note.audioFiles.isNotEmpty) const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: note.tags.take(3).map((tag) {
                          return Container(
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
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(note.updatedAt, context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayTitle(BuildContext context) {
    bool hasText =
        (note.plainTextContent?.trim().isNotEmpty ?? false) ||
        note.content.trim().isNotEmpty;
    bool hasAudio = note.audioFiles.isNotEmpty;

    // Eğer sadece sesli not varsa "Sesli Not" göster
    if (!hasText && hasAudio) {
      return AppLocalizations.of(context)!.voiceNote;
    }

    // Normal durumda başlık veya "Başlıksız Not"
    return note.title.isEmpty ? AppLocalizations.of(context)!.untitledNote : note.title;
  }

  bool _shouldShowContent() {
    bool hasText =
        (note.plainTextContent?.isNotEmpty ?? false) || note.content.isNotEmpty;
    bool hasAudio = note.audioFiles.isNotEmpty;

    // Eğer sadece sesli not varsa içerik gösterme
    if (!hasText && hasAudio) {
      return true; // Sesli not bilgisini göstermek için
    }

    // Normal durumda metin varsa göster
    return hasText;
  }

  String _getDisplayContent(BuildContext context) {
    bool hasText =
        (note.plainTextContent?.trim().isNotEmpty ?? false) ||
        note.content.trim().isNotEmpty;
    bool hasAudio = note.audioFiles.isNotEmpty;

    // Eğer sadece sesli not varsa özel mesaj göster
    if (!hasText && hasAudio) {
      return '${note.audioFiles.length} ${AppLocalizations.of(context)!.voiceRecordingContains}';
    }

    // Normal durumda metin içeriği
    return note.plainTextContent?.isNotEmpty == true
        ? note.plainTextContent!
        : _getPlainTextContent(note.content);
  }

  String _getPlainTextContent(String content) {
    // Quill Delta formatını kontrol et
    if (content.startsWith('[{"insert":')) {
      try {
        // JSON formatından metni çıkar
        final regex = RegExp(r'"insert":"([^"]*)');
        final matches = regex.allMatches(content);
        String extractedText = '';
        for (final match in matches) {
          if (match.group(1) != null) {
            extractedText += '${match.group(1)!} ';
          }
        }
        return extractedText.trim();
      } catch (e) {
        // JSON parse hatası durumunda normal temizleme yap
      }
    }

    // HTML içeriği için normal temizleme
    String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('\\n', '\n')
        .replaceAll(RegExp(r'\s+'), ' ') // Çoklu boşlukları tek boşluğa çevir
        .trim();

    return cleanContent;
  }

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return AppLocalizations.of(context)!.now;
        }
        return '${difference.inMinutes} ${AppLocalizations.of(context)!.minutesAgo}';
      }
      return '${difference.inHours} ${AppLocalizations.of(context)!.hoursAgo}';
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${AppLocalizations.of(context)!.daysAgo}';
    } else {
      return DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(date);
    }
  }
}
