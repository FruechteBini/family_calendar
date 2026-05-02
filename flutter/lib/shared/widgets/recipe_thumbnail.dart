import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/recipe_image_url.dart';

class RecipeThumbnail extends ConsumerWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final Widget? fallback;

  const RecipeThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 48,
    this.borderRadius = 10,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final u = imageUrl;

    Widget buildFallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        alignment: Alignment.center,
        child: fallback ?? const Icon(Icons.restaurant),
      );
    }

    if (u == null || u.trim().isEmpty) return buildFallback();

    final fullUrl = recipeCoverFullUrl(ref, u);
    if (fullUrl.isEmpty) return buildFallback();
    final headers = recipeCoverImageHeaders(ref, u);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        httpHeaders: headers,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => buildFallback(),
      ),
    );
  }
}
