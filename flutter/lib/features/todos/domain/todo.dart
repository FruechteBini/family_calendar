class Todo {
  final int id;
  final bool isPersonal;
  final int? createdByMemberId;
  final TodoMember? createdBy;
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
    this.isPersonal = false,
    this.createdByMemberId,
    this.createdBy,
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
    final category = json['category'];
    final catId = json['category_id'] as int? ??
        (category is Map<String, dynamic> ? category['id'] as int? : null);
    final catName = json['category_name'] as String? ??
        (category is Map<String, dynamic> ? category['name'] as String? : null);

    final membersRaw = (json['members'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];

    return Todo(
      id: json['id'] as int,
      isPersonal: json['is_personal'] as bool? ?? false,
      createdByMemberId: json['created_by_member_id'] as int?,
      createdBy: (json['created_by'] is Map<String, dynamic>)
          ? TodoMember.fromJson(json['created_by'] as Map<String, dynamic>)
          : null,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'none',
      completed: json['completed'] as bool? ?? false,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      categoryId: catId,
      categoryName: catName,
      eventId: json['event_id'] as int?,
      parentId: json['parent_id'] as int?,
      requiresMultiple: json['requires_multiple'] as bool? ?? false,
      memberIds: (json['member_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          membersRaw.map((m) => m['id'] as int).toList(),
      members: membersRaw.map(TodoMember.fromJson).toList(),
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
      'is_personal': isPersonal,
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
      emoji: json['emoji'] as String? ?? json['avatar_emoji'] as String?,
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
    final proposer = json['proposer'];
    final proposerId = (json['proposer_id'] as int?) ??
        (proposer is Map<String, dynamic> ? proposer['id'] as int? : null) ??
        0;
    final proposerName = (json['proposer_name'] as String?) ??
        (proposer is Map<String, dynamic> ? proposer['name'] as String? : null);
    return Proposal(
      id: json['id'] as int,
      todoId: json['todo_id'] as int,
      todoTitle: json['todo_title'] as String?,
      proposerId: proposerId,
      proposerName: proposerName,
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
