class User {
  final int id;
  final String username;
  final int? familyId;
  final int? memberId;

  const User({
    required this.id,
    required this.username,
    this.familyId,
    this.memberId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      familyId: json['family_id'] as int?,
      memberId: json['member_id'] as int?,
    );
  }

  User copyWith({int? familyId, int? memberId}) {
    return User(
      id: id,
      username: username,
      familyId: familyId ?? this.familyId,
      memberId: memberId ?? this.memberId,
    );
  }
}

class Family {
  final int id;
  final String name;
  final String inviteCode;

  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as int,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
    );
  }
}
