import 'note_attachment.dart';
import 'note_category.dart';
import 'note_comment.dart';
import 'note_member.dart';
import 'note_tag.dart';

enum NoteType { text, link, checklist }

class ChecklistItem {
  final String text;
  final bool checked;

  const ChecklistItem({required this.text, this.checked = false});

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      text: json['text'] as String,
      checked: json['checked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'text': text, 'checked': checked};
}

class Note {
  final int id;
  final bool isPersonal;
  final int? createdByMemberId;
  final NoteMember? createdBy;
  final NoteType type;
  final String title;
  final String? content;
  final String? url;
  final String? linkTitle;
  final String? linkDescription;
  final String? linkThumbnailUrl;
  final String? linkDomain;
  final List<ChecklistItem>? checklistItems;
  final bool isPinned;
  final bool isArchived;
  final String? color;
  final NoteCategory? category;
  final List<NoteTag> tags;
  final List<NoteComment> comments;
  final List<NoteAttachment> attachments;
  final DateTime? reminderAt;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.isPersonal,
    this.createdByMemberId,
    this.createdBy,
    required this.type,
    required this.title,
    this.content,
    this.url,
    this.linkTitle,
    this.linkDescription,
    this.linkThumbnailUrl,
    this.linkDomain,
    this.checklistItems,
    required this.isPinned,
    required this.isArchived,
    this.color,
    this.category,
    required this.tags,
    required this.comments,
    required this.attachments,
    this.reminderAt,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  static NoteType _parseType(String? s) {
    switch (s) {
      case 'link':
        return NoteType.link;
      case 'checklist':
        return NoteType.checklist;
      default:
        return NoteType.text;
    }
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    List<ChecklistItem>? items;
    final rawList = json['checklist_items'] as List<dynamic>?;
    if (rawList != null) {
      items = rawList
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return Note(
      id: json['id'] as int,
      isPersonal: json['is_personal'] as bool? ?? false,
      createdByMemberId: json['created_by_member_id'] as int?,
      createdBy: json['created_by'] != null
          ? NoteMember.fromJson(json['created_by'] as Map<String, dynamic>)
          : null,
      type: _parseType(json['type'] as String?),
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      url: json['url'] as String?,
      linkTitle: json['link_title'] as String?,
      linkDescription: json['link_description'] as String?,
      linkThumbnailUrl: json['link_thumbnail_url'] as String?,
      linkDomain: json['link_domain'] as String?,
      checklistItems: items,
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      color: json['color'] as String?,
      category: json['category'] != null
          ? NoteCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => NoteTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => NoteComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => NoteAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String)
          : null,
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get typeApiValue {
    switch (type) {
      case NoteType.link:
        return 'link';
      case NoteType.checklist:
        return 'checklist';
      case NoteType.text:
        return 'text';
    }
  }

  /// Headline in lists when [title] is empty.
  String get displayTitle {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    switch (type) {
      case NoteType.link:
        if (linkTitle != null && linkTitle!.trim().isNotEmpty) {
          return linkTitle!.trim();
        }
        if (linkDomain != null && linkDomain!.trim().isNotEmpty) {
          return linkDomain!.trim();
        }
        final u = url;
        if (u != null && u.isNotEmpty) {
          final host = Uri.tryParse(u)?.host;
          if (host != null && host.isNotEmpty) return host;
          return u.length > 48 ? '${u.substring(0, 45)}…' : u;
        }
        return 'Link';
      case NoteType.text:
        final c = content?.trim() ?? '';
        if (c.isNotEmpty) {
          var line = c.split(RegExp(r'\r?\n')).first.trim();
          if (line.length > 72) line = '${line.substring(0, 69)}…';
          return line;
        }
        final img = attachments.where((a) => a.isImage).toList();
        if (img.isNotEmpty) {
          return img.length > 1 ? 'Fotos (${img.length})' : 'Foto';
        }
        final vid = attachments.where((a) => a.isVideo).toList();
        if (vid.isNotEmpty) {
          return vid.length > 1 ? 'Videos (${vid.length})' : 'Video';
        }
        if (attachments.isNotEmpty) return 'Anhang';
        return 'Notiz';
      case NoteType.checklist:
        for (final it in checklistItems ?? const []) {
          final x = it.text.trim();
          if (x.isNotEmpty) {
            return x.length > 72 ? '${x.substring(0, 69)}…' : x;
          }
        }
        return 'Checkliste';
    }
  }
}

class LinkPreview {
  final String url;
  final String? linkTitle;
  final String? linkDescription;
  final String? linkThumbnailUrl;
  final String? linkDomain;

  const LinkPreview({
    required this.url,
    this.linkTitle,
    this.linkDescription,
    this.linkThumbnailUrl,
    this.linkDomain,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json) {
    return LinkPreview(
      url: json['url'] as String,
      linkTitle: json['link_title'] as String?,
      linkDescription: json['link_description'] as String?,
      linkThumbnailUrl: json['link_thumbnail_url'] as String?,
      linkDomain: json['link_domain'] as String?,
    );
  }
}

class DuplicateLinkResult {
  final bool exists;
  final int? noteId;
  final String? title;

  const DuplicateLinkResult({
    required this.exists,
    this.noteId,
    this.title,
  });

  factory DuplicateLinkResult.fromJson(Map<String, dynamic> json) {
    return DuplicateLinkResult(
      exists: json['exists'] as bool? ?? false,
      noteId: json['note_id'] as int?,
      title: json['title'] as String?,
    );
  }
}
