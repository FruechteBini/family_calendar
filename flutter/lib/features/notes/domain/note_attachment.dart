class NoteAttachment {
  final int id;
  final String filename;
  final String contentType;
  final int fileSize;
  final DateTime createdAt;
  final String? downloadUrl;

  bool get isImage {
    final ct = contentType.toLowerCase();
    if (ct.startsWith('image/')) return true;
    final n = filename.toLowerCase();
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.gif') ||
        n.endsWith('.webp') ||
        n.endsWith('.heic') ||
        n.endsWith('.bmp');
  }

  bool get isVideo {
    final ct = contentType.toLowerCase();
    if (ct.startsWith('video/')) return true;
    final n = filename.toLowerCase();
    return n.endsWith('.mp4') ||
        n.endsWith('.mov') ||
        n.endsWith('.webm') ||
        n.endsWith('.mkv') ||
        n.endsWith('.m4v');
  }

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
