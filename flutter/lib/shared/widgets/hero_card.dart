import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'primary_button.dart';

/// Hero card for featured content (dinner, recipe, etc.).
///
/// Full-width card with image, gradient overlay, overlapping content,
/// tag chip, and CTA button.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.tagText,
    required this.title,
    this.description,
    this.imageUrl,
    required this.ctaText,
    this.onCtaPressed,
  });

  final String tagText;
  final String title;
  final String? description;
  final String? imageUrl;
  final String ctaText;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with gradient overlay
          Stack(
            children: [
              // Image
              SizedBox(
                width: double.infinity,
                height: 256,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              // Gradient overlay: transparent → background (top to bottom)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.surfaceContainerLow.withOpacity(0),
                        AppColors.surfaceContainerLow,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content overlapping image by -80px
          Transform.translate(
            offset: const Offset(0, -80),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.spacing6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.spacing4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusFull),
                    ),
                    child: Text(
                      tagText.toUpperCase(),
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.onSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                    ),
                  ),
                  const SizedBox(height: AppColors.spacing3),
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppColors.spacing2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        description!,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppColors.spacing4),
                  // CTA Button
                  PrimaryButton(
                    label: ctaText,
                    onPressed: onCtaPressed,
                  ),
                  // Bottom spacing to compensate for negative translate
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 256,
      color: AppColors.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: AppColors.onSurfaceVariant.withOpacity(0.5),
      ),
    );
  }
}
