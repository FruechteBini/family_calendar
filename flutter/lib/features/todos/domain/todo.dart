class Todo {
  final int id;
  final String title;
  final String? description;
  final String priority; // none, low, medium, high
  final bool completed;
  final DateTime? dueDate;
  final int? categoryId;
  final String? categoryName;
  final int? eventId;
  final int? parentId;
  final bool requiresMultiple;
  final List<int> memberIds;
  final List<TodoMember> members;
  final List<Todo> subtodos;
  final int proposalCount;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'none',
    this.completed = false,
    this.dueDate,
    this.categoryId,
    this.categoryName,
    this.eventId,
    this.parentId,
    this.requiresMultiple = false,
    this.memberIds = const [],
    this.members = const [],
    this.subtodos = const [],
    this.proposalCount = 0,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'none',
      completed: json['completed'] as bool? ?? false,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      eventId: json['event_id'] as int?,
      parentId: json['parent_id'] as int?,
      requiresMultiple: json['requires_multiple'] as bool? ?? false,
      memberIds: (json['member_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => TodoMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtodos: (json['subtodos'] as List<dynamic>?)
              ?.map((e) => Todo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      proposalCount: json['proposal_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (categoryId != null) 'category_id': categoryId,
      if (parentId != null) 'parent_id': parentId,
      'requires_multiple': requiresMultiple,
      'member_ids': memberIds,
    };
  }
}

class TodoMember {
  final int id;
  final String name;
  final String? emoji;

  const TodoMember({required this.id, required this.name, this.emoji});

  factory TodoMember.fromJson(Map<String, dynamic> json) {
    return TodoMember(
      id: json['id'] as int,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
    );
  }
}

class Proposal {
  final int id;
  final int todoId;
  final String? todoTitle;
  final int proposerId;
  final String? proposerName;
  final DateTime proposedDate;
  final String? message;
  final String status; // pending, accepted, rejected, counter
  final DateTime? counterDate;
  final String? counterMessage;

  const Proposal({
    required this.id,
    required this.todoId,
    this.todoTitle,
    required this.proposerId,
    this.proposerName,
    required this.proposedDate,
    this.message,
    this.status = 'pending',
    this.counterDate,
    this.counterMessage,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] as int,
      todoId: json['todo_id'] as int,
      todoTitle: json['todo_title'] as String?,
      proposerId: json['proposer_id'] as int,
      proposerName: json['proposer_name'] as String?,
      proposedDate: DateTime.parse(json['proposed_date'] as String),
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      counterDate: json['counter_date'] != null
          ? DateTime.parse(json['counter_date'] as String)
          : null,
      counterMessage: json['counter_message'] as String?,
    );
  }
}
