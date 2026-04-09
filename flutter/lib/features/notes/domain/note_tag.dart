class NoteTag {
  final int id;
  final String name;
  final String color;

  const NoteTag({
    required this.id,
    required this.name,
    required this.color,
  });

  factory NoteTag.fromJson(Map<String, dynamic> json) {
    return NoteTag(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6B7280',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
      };
}
