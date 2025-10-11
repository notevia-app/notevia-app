class Note {
  final int? id;
  final String title;
  final String content;
  final String? plainTextContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isImportant;
  final bool isHidden;
  final String? customFilter;
  final String? reminderDateTime;
  final bool repeatReminder;
  final String? backgroundColor;
  final List<String> audioFiles;
  final List<String> tags;
  
  Note({
    this.id,
    required this.title,
    required this.content,
    this.plainTextContent,
    required this.createdAt,
    required this.updatedAt,
    this.isImportant = false,
    this.isHidden = false,
    this.customFilter,
    this.reminderDateTime,
    this.repeatReminder = false,
    this.backgroundColor,
    this.audioFiles = const [],
    this.tags = const [],
  });
  
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? plainTextContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isImportant,
    bool? isHidden,
    String? customFilter,
    String? reminderDateTime,
    bool? repeatReminder,
    String? backgroundColor,
    List<String>? audioFiles,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainTextContent: plainTextContent ?? this.plainTextContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isImportant: isImportant ?? this.isImportant,
      isHidden: isHidden ?? this.isHidden,
      customFilter: customFilter ?? this.customFilter,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      repeatReminder: repeatReminder ?? this.repeatReminder,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      audioFiles: audioFiles ?? this.audioFiles,
      tags: tags ?? this.tags,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'plainTextContent': plainTextContent,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isImportant': isImportant ? 1 : 0,
      'isHidden': isHidden ? 1 : 0,
      'customFilter': customFilter,
      'reminderDateTime': reminderDateTime,
      'repeatReminder': repeatReminder ? 1 : 0,
      'backgroundColor': backgroundColor,
      'audioFiles': audioFiles.join(','),
      'tags': tags.join(','),
    };
  }
  
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      plainTextContent: map['plainTextContent'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isImportant: (map['isImportant'] ?? 0) == 1,
      isHidden: (map['isHidden'] ?? 0) == 1,
      customFilter: map['customFilter'],
      reminderDateTime: map['reminderDateTime'],
      repeatReminder: (map['repeatReminder'] ?? 0) == 1,
      backgroundColor: map['backgroundColor'],
      audioFiles: map['audioFiles'] != null && map['audioFiles'].isNotEmpty
          ? map['audioFiles'].split(',')
          : [],
      tags: map['tags'] != null && map['tags'].isNotEmpty
          ? map['tags'].split(',')
          : [],
    );
  }
}