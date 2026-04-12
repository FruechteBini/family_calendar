import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../domain/todo_attachment.dart';

bool todoAttachmentIsImage(TodoAttachment a) {
  final ct = a.contentType.toLowerCase();
  if (ct.startsWith('image/')) return true;
  final n = a.filename.toLowerCase();
  return n.endsWith('.png') ||
      n.endsWith('.jpg') ||
      n.endsWith('.jpeg') ||
      n.endsWith('.gif') ||
      n.endsWith('.webp') ||
      n.endsWith('.heic') ||
      n.endsWith('.bmp');
}

bool todoAttachmentIsVideo(TodoAttachment a) {
  final ct = a.contentType.toLowerCase();
  if (ct.startsWith('video/')) return true;
  final n = a.filename.toLowerCase();
  return n.endsWith('.mp4') ||
      n.endsWith('.mov') ||
      n.endsWith('.webm') ||
      n.endsWith('.mkv') ||
      n.endsWith('.m4v');
}

String todoAttachmentFullUrl(WidgetRef ref, TodoAttachment a) {
  final u = a.downloadUrl;
  if (u == null || u.isEmpty) return '';
  if (u.startsWith('http')) return u;
  var base = ref.read(dioProvider).options.baseUrl;
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  final path = u.startsWith('/') ? u : '/$u';
  return '$base$path';
}

Map<String, String>? todoImageRequestHeaders(WidgetRef ref) {
  final t = ref.watch(authStateProvider).token;
  if (t == null) return null;
  return {'Authorization': 'Bearer $t'};
}
