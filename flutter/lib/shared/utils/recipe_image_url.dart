import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';

/// Volle Bild-URL für CachedNetworkImage; relative API-Pfade gegen [baseUrl].
String recipeCoverFullUrl(WidgetRef ref, String? imageUrl) {
  final u = imageUrl;
  if (u == null || u.trim().isEmpty) return '';
  final trimmed = u.trim();
  if (trimmed.startsWith('http')) return trimmed;
  if (trimmed.startsWith('/api/')) {
    var base = ref.read(dioProvider).options.baseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return '$base$trimmed';
  }
  return trimmed;
}

/// Authorization nur für hochgeladene Rezept-Cover ([/api/recipes/…/cover]).
Map<String, String>? recipeCoverImageHeaders(WidgetRef ref, String? imageUrl) {
  final u = imageUrl;
  if (u == null || u.trim().isEmpty) return null;
  final t = u.trim();
  if (t.startsWith('http')) return null;
  if (t.contains('/api/recipes/') && t.contains('/cover')) {
    final token = ref.watch(authStateProvider).token;
    if (token == null) return null;
    return {'Authorization': 'Bearer $token'};
  }
  return null;
}
