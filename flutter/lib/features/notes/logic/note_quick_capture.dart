bool looksLikeHttpUrl(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  final u = Uri.tryParse(t);
  return u != null &&
      u.hasScheme &&
      (u.scheme == 'http' || u.scheme == 'https') &&
      u.host.isNotEmpty;
}

/// First line only URL (typical browser share).
String? urlForLinkNote(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final firstLine = t.split(RegExp(r'\r?\n')).first.trim();
  if (looksLikeHttpUrl(t)) return t;
  if (looksLikeHttpUrl(firstLine)) return firstLine;
  return null;
}

/// Build API body for quick capture (clipboard or share). Server fetches link preview.
Map<String, dynamic> buildQuickNotePayload(
  String raw, {
  required bool isPersonal,
}) {
  final url = urlForLinkNote(raw);
  if (url != null) {
    return {
      'title': '',
      'type': 'link',
      'url': url,
      'is_personal': isPersonal,
      'tag_ids': <int>[],
    };
  }
  return {
    'title': '',
    'type': 'text',
    'content': raw,
    'is_personal': isPersonal,
    'tag_ids': <int>[],
  };
}
