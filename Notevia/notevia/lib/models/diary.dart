class Diary {
  final int? id;
  final String title;
  final String content;
  final String? plainTextContent;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? backgroundColor;
  final List<String> audioFiles;
  final bool reminderEnabled;
  final String? dailyReminderTime; // Format: "HH:mm" (e.g., "20:00" for 8 PM)
  
  Diary({
    this.id,
    required this.title,
    required this.content,
    this.plainTextContent,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundColor,
    this.audioFiles = const [],
    this.reminderEnabled = false,
    this.dailyReminderTime,
  });
  
  Diary copyWith({
    int? id,
    String? title,
    String? content,
    String? plainTextContent,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? backgroundColor,
    List<String>? audioFiles,
    bool? reminderEnabled,
    String? dailyReminderTime,
  }) {
    return Diary(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainTextContent: plainTextContent ?? this.plainTextContent,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      audioFiles: audioFiles ?? this.audioFiles,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'plainTextContent': plainTextContent,
      'date': date.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'backgroundColor': backgroundColor,
      'audioFiles': audioFiles.join(','),
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'dailyReminderTime': dailyReminderTime,
    };
  }
  
  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'] is String ? int.tryParse(map['id']) : map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      plainTextContent: map['plainTextContent'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      backgroundColor: map['backgroundColor'],
      audioFiles: map['audioFiles'] != null && map['audioFiles'].isNotEmpty
          ? map['audioFiles'].split(',')
          : [],
      reminderEnabled: (map['reminderEnabled'] ?? 0) == 1,
      dailyReminderTime: map['dailyReminderTime'],
    );
  }
  
  String get dateKey => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}