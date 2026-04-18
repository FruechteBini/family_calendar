import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';

/// Authorization for recipe thumbnail URLs (same pattern as todo attachments).
Map<String, String>? recipeImageRequestHeaders(WidgetRef ref) {
  final t = ref.watch(authStateProvider).token;
  if (t == null) return null;
  return {'Authorization': 'Bearer $t'};
}

/// Absolute URL for [imageUrl] from the API (relative `/api/...` or absolute).
String recipeImageAbsoluteUrl(WidgetRef ref, String imageUrl) {
  final u = imageUrl.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  var base = ref.read(dioProvider).options.baseUrl;
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  final path = u.startsWith('/') ? u : '/$u';
  return '$base$path';
}

bool recipeImageUrlNeedsAuth(String? imageUrl) {
  final u = imageUrl?.trim();
  if (u == null || u.isEmpty) return false;
  return !u.startsWith('http://') && !u.startsWith('https://');
}
