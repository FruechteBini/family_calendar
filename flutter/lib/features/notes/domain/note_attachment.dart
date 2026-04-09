class NoteAttachment {
  final int id;
  final String filename;
  final String contentType;
  final int fileSize;
  final DateTime createdAt;
  final String? downloadUrl;

  const NoteAttachment({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.fileSize,
    required this.createdAt,
    this.downloadUrl,
  });

  factory NoteAttachment.fromJson(Map<String, dynamic> json) {
    return NoteAttachment(
      id: json['id'] as int,
      filename: json['filename'] as String,
      contentType: json['content_type'] as String? ?? 'application/octet-stream',
      fileSize: json['file_size'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      downloadUrl: json['download_url'] as String?,
    );
  }
}
