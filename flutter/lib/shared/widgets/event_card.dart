import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'app_card.dart';

/// Event card with a colored left bar indicating category/member.
///
/// Layout: [Time column (50px) | Content | Optional trailing widget].
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.time,
    required this.title,
    this.location,
    this.description,
    required this.barColor,
    this.trailing,
  });

  final String time;
  final String title;
  final String? location;
  final String? description;
  final Color barColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          // Color bar
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppColors.radiusDefault),
                bottomLeft: Radius.circular(AppColors.radiusDefault),
              ),
            ),
          ),
          // Time column
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.spacing2,
                vertical: AppColors.spacing4,
              ),
              child: Text(
                time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppColors.spacing4,
              ).copyWith(right: AppColors.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                  ),
                  if (location != null || description != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (location != null) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              location!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (description != null && location == null) ...[
                          Flexible(
                            child: Text(
                              description!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Optional trailing widget (e.g., avatar)
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: AppColors.spacing4),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
