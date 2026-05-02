final _urlInClipboard = RegExp(
  r'https?://[^\s<>\[\]()]+',
  caseSensitive: false,
);

bool looksLikeHttpUrl(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  final u = Uri.tryParse(t);
  return u != null &&
      u.hasScheme &&
      (u.scheme == 'http' || u.scheme == 'https') &&
      u.host.isNotEmpty;
}

String _trimUrlTrailingPunctuation(String url) {
  const trailing = '.,;:!?)]}\'"»«';
  var s = url;
  while (s.isNotEmpty && trailing.contains(s[s.length - 1])) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// If [rest] without the URL is longer than this, clipboard is treated as a text note
/// (e.g. meeting notes with a link at the end).
const _maxCharsOutsideUrlForLinkNote = 120;

/// First http(s) URL for a **link** quick-capture when the paste is mostly that URL.
/// Embeds a URL inside long text → `null` (text note).
String? urlForLinkNote(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final firstLine = t.split(RegExp(r'\r?\n')).first.trim();
  if (looksLikeHttpUrl(t)) return t;
  if (looksLikeHttpUrl(firstLine)) return firstLine;
  final m = _urlInClipboard.firstMatch(t);
  if (m == null) return null;
  final u = _trimUrlTrailingPunctuation(m.group(0)!);
  if (!looksLikeHttpUrl(u)) return null;
  final rest =
      '${t.substring(0, m.start)}${t.substring(m.end)}'.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (rest.length > _maxCharsOutsideUrlForLinkNote) {
    return null;
  }
  return u;
}

/// Build API body for quick capture (clipboard or share). Server fetches link preview.
Map<String, dynamic> buildQuickNotePayload(
  String raw, {
  required bool isPersonal,
  int? categoryId,
}) {
  final url = urlForLinkNote(raw);
  final map = url != null
      ? <String, dynamic>{
          'title': '',
          'type': 'link',
          'url': url,
          'is_personal': isPersonal,
          'tag_ids': <int>[],
        }
      : <String, dynamic>{
          'title': '',
          'type': 'text',
          'content': raw,
          'is_personal': isPersonal,
          'tag_ids': <int>[],
        };
  if (categoryId != null) {
    map['category_id'] = categoryId;
  }
  return map;
}
