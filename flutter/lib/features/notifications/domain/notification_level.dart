class NotificationLevel {
  final int id;
  final String name;
  final int position;
  final List<int> remindersMinutes;
  final bool isDefault;

  const NotificationLevel({
    required this.id,
    required this.name,
    required this.position,
    required this.remindersMinutes,
    required this.isDefault,
  });

  factory NotificationLevel.fromJson(Map<String, dynamic> json) {
    return NotificationLevel(
      id: json['id'] as int,
      name: (json['name'] as String?)?.trim() ?? '',
      position: (json['position'] as int?) ?? 0,
      remindersMinutes: ((json['reminders_minutes'] as List?) ?? const [])
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(),
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'position': position,
        'reminders_minutes': remindersMinutes,
        'is_default': isDefault,
      };
}

