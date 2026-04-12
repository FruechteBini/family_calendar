class EventLinkedTodo {
  final int id;
  final String title;
  final bool completed;

  const EventLinkedTodo({
    required this.id,
    required this.title,
    required this.completed,
  });

  factory EventLinkedTodo.fromJson(Map<String, dynamic> json) {
    return EventLinkedTodo(
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final List<int> memberIds;
  final List<EventMember> members;
  final int? notificationLevelId;
  final List<EventLinkedTodo> linkedTodos;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.memberIds = const [],
    this.members = const [],
    this.notificationLevelId,
    this.linkedTodos = const [],
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    final members = (json['members'] as List<dynamic>?)
            ?.map((e) => EventMember.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final memberIds = (json['member_ids'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        (members.isNotEmpty ? members.map((m) => m.id).toList() : <int>[]);
    final linkedTodos = (json['todos'] as List<dynamic>?)
            ?.map((e) => EventLinkedTodo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <EventLinkedTodo>[];
    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse((json['start'] ?? json['start_time']) as String),
      endTime: DateTime.parse((json['end'] ?? json['end_time']) as String),
      allDay: json['all_day'] as bool? ?? false,
      categoryId: json['category_id'] as int? ?? cat?['id'] as int?,
      categoryName: json['category_name'] as String? ?? cat?['name'] as String?,
      categoryColor: json['category_color'] as String? ?? cat?['color'] as String?,
      memberIds: memberIds,
      members: members,
      notificationLevelId: json['notification_level_id'] as int?,
      linkedTodos: linkedTodos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'start': startTime.toIso8601String(),
      'end': endTime.toIso8601String(),
      'all_day': allDay,
      if (categoryId != null) 'category_id': categoryId,
      'member_ids': memberIds,
      if (notificationLevelId != null)
        'notification_level_id': notificationLevelId,
    };
  }
}

class EventMember {
  final int id;
  final String name;
  final String? emoji;
  final String? color;

  const EventMember({
    required this.id,
    required this.name,
    this.emoji,
    this.color,
  });

  factory EventMember.fromJson(Map<String, dynamic> json) {
    return EventMember(
      id: json['id'] as int,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? json['avatar_emoji'] as String?,
      color: json['color'] as String?,
    );
  }
}
