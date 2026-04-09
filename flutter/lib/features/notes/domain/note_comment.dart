import 'note_member.dart';

class NoteComment {
  final int id;
  final NoteMember? member;
  final String content;
  final DateTime createdAt;

  const NoteComment({
    required this.id,
    this.member,
    required this.content,
    required this.createdAt,
  });

  factory NoteComment.fromJson(Map<String, dynamic> json) {
    return NoteComment(
      id: json['id'] as int,
      member: json['member'] != null
          ? NoteMember.fromJson(json['member'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
