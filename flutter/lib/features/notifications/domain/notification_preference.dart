enum NotificationType {
  eventReminder('event_reminder'),
  todoReminder('todo_reminder'),
  noteReminder('note_reminder'),
  eventAssigned('event_assigned'),
  todoAssigned('todo_assigned'),
  proposalNew('proposal_new'),
  proposalResponse('proposal_response'),
  eventUpdated('event_updated'),
  eventDeleted('event_deleted'),
  todoCompleted('todo_completed'),
  shoppingListChanged('shopping_list_changed'),
  mealPlanChanged('meal_plan_changed'),
  noteComment('note_comment');

  final String apiValue;
  const NotificationType(this.apiValue);
}

class NotificationPreference {
  final NotificationType type;
  final bool enabled;

  const NotificationPreference({required this.type, required this.enabled});

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final raw = (json['notification_type'] as String?) ?? '';
    final type = NotificationType.values.firstWhere(
      (t) => t.apiValue == raw,
      orElse: () => NotificationType.eventReminder,
    );
    return NotificationPreference(
      type: type,
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'notification_type': type.apiValue,
        'enabled': enabled,
      };
}

