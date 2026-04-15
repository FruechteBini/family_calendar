import 'event_recurrence.dart';

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
  /// Eigene Terminfarbe (#RRGGBB). Wenn gesetzt, überschreibt sie die Kategoriefarbe in der Ansicht.
  final String? color;
  final List<int> memberIds;
  final List<EventMember> members;
  final int? notificationLevelId;
  final List<EventLinkedTodo> linkedTodos;
  final List<EventRecurrenceRule> recurrenceRules;
  final DateTime? occurrenceStart;
  final DateTime? recurrenceAnchorStart;
  final DateTime? recurrenceAnchorEnd;

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
    this.color,
    this.memberIds = const [],
    this.members = const [],
    this.notificationLevelId,
    this.linkedTodos = const [],
    this.recurrenceRules = const [],
    this.occurrenceStart,
    this.recurrenceAnchorStart,
    this.recurrenceAnchorEnd,
  });

  bool get isRecurringSeries => recurrenceRules.isNotEmpty;
  bool get isRecurringOccurrence => occurrenceStart != null;

  /// Farbe für Kalender & Listen: Terminfarbe oder Kategoriefarbe.
  String? get displayColorHex => color ?? categoryColor;

  /// GoRouter path including `occurrence` query for recurring instances.
  String get detailLocation {
    if (isRecurringOccurrence && occurrenceStart != null) {
      final q = Uri.encodeComponent(occurrenceStart!.toUtc().toIso8601String());
      return '/events/$id?occurrence=$q';
    }
    return '/events/$id';
  }

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
    final rulesJson = json['recurrence_rules'] as List<dynamic>?;
    final rules = rulesJson
            ?.map((e) => EventRecurrenceRule.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <EventRecurrenceRule>[];
    final occStart = json['occurrence_start'] != null
        ? DateTime.tryParse(json['occurrence_start'] as String)
        : null;
    final anchorStart = json['recurrence_anchor_start'] != null
        ? DateTime.tryParse(json['recurrence_anchor_start'] as String)
        : null;
    final anchorEnd = json['recurrence_anchor_end'] != null
        ? DateTime.tryParse(json['recurrence_anchor_end'] as String)
        : null;
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
      color: json['color'] as String?,
      memberIds: memberIds,
      members: members,
      notificationLevelId: json['notification_level_id'] as int?,
      linkedTodos: linkedTodos,
      recurrenceRules: rules,
      occurrenceStart: occStart,
      recurrenceAnchorStart: anchorStart,
      recurrenceAnchorEnd: anchorEnd,
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
      if (color != null) 'color': color,
      'member_ids': memberIds,
      if (notificationLevelId != null)
        'notification_level_id': notificationLevelId,
      if (recurrenceRules.isNotEmpty)
        'recurrence_rules': recurrenceRules.map((r) => r.toJson()).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final m = toJson();
    if (isRecurringOccurrence && recurrenceAnchorStart != null) {
      m['recurrence_anchor_start'] = recurrenceAnchorStart!.toIso8601String();
    }
    return m;
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
