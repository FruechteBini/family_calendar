import 'note.dart';

/// Maps a note to todo title/description for the "convert to todo" flow (mirrors backend logic).
NoteTodoPrefill noteTodoPrefillFromNote(Note note) {
  final descParts = <String>[];
  final content = note.content?.trim();
  if (content != null && content.isNotEmpty) {
    descParts.add(note.content!);
  }
  if (note.type == NoteType.link) {
    final u = note.url?.trim();
    if (u != null && u.isNotEmpty) descParts.add(note.url!);
  }
  if (note.type == NoteType.checklist) {
    final items = note.checklistItems;
    if (items != null && items.isNotEmpty) {
      descParts.add(items.map((e) => '- ${e.text}').join('\n'));
    }
  }
  final description =
      descParts.isEmpty ? null : descParts.join('\n\n');

  var titleRaw = note.title.trim();
  if (titleRaw.length > 200) {
    titleRaw = titleRaw.substring(0, 200);
  }
  if (titleRaw.isEmpty) {
    if (note.type == NoteType.link) {
      titleRaw = (note.linkTitle ?? note.linkDomain ?? note.url ?? '').trim();
    }
    if (titleRaw.isEmpty && content != null && content.isNotEmpty) {
      titleRaw = content.split('\n').first.trim();
    }
    if (titleRaw.isEmpty) titleRaw = 'Aus Notiz';
  }
  if (titleRaw.length > 200) {
    titleRaw = titleRaw.substring(0, 200);
  }

  return NoteTodoPrefill(
    title: titleRaw,
    description: description,
    isPersonal: note.isPersonal,
  );
}

class NoteTodoPrefill {
  final String title;
  final String? description;
  final bool isPersonal;

  const NoteTodoPrefill({
    required this.title,
    this.description,
    required this.isPersonal,
  });
}
