class User {
  final int id;
  final String username;
  final int? familyId;
  final int? memberId;
  final String? googleEmail;
  final bool syncCalendarEnabled;
  final bool syncTodosEnabled;
  final int? personalCalendarCategoryId;

  const User({
    required this.id,
    required this.username,
    this.familyId,
    this.memberId,
    this.googleEmail,
    this.syncCalendarEnabled = false,
    this.syncTodosEnabled = false,
    this.personalCalendarCategoryId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      familyId: json['family_id'] as int?,
      memberId: json['member_id'] as int?,
      googleEmail: json['google_email'] as String?,
      syncCalendarEnabled: (json['sync_calendar_enabled'] as bool?) ?? false,
      syncTodosEnabled: (json['sync_todos_enabled'] as bool?) ?? false,
      personalCalendarCategoryId:
          json['personal_calendar_category_id'] as int?,
    );
  }

  User copyWith({
    int? familyId,
    int? memberId,
    String? googleEmail,
    bool? syncCalendarEnabled,
    bool? syncTodosEnabled,
    int? personalCalendarCategoryId,
  }) {
    return User(
      id: id,
      username: username,
      familyId: familyId ?? this.familyId,
      memberId: memberId ?? this.memberId,
      googleEmail: googleEmail ?? this.googleEmail,
      syncCalendarEnabled: syncCalendarEnabled ?? this.syncCalendarEnabled,
      syncTodosEnabled: syncTodosEnabled ?? this.syncTodosEnabled,
      personalCalendarCategoryId:
          personalCalendarCategoryId ?? this.personalCalendarCategoryId,
    );
  }
}

class Family {
  final int id;
  final String name;
  final String inviteCode;
  final int? defaultFamilyCalendarCategoryId;

  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.defaultFamilyCalendarCategoryId,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as int,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      defaultFamilyCalendarCategoryId:
          json['default_family_calendar_category_id'] as int?,
    );
  }
}
