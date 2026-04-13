import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Compact in-screen headers (below [AppShell] / nested [AppBar]) so primary
/// content gets maximum vertical space while staying readable.
class ScreenHeader {
  ScreenHeader._();

  static const double horizontalPadding = AppColors.spacing4;
  static const double topPadding = AppColors.spacing2;
  static const double bottomPadding = AppColors.spacing2;

  static EdgeInsets padding({double bottom = bottomPadding}) =>
      EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, bottom);

  static TextStyle titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          );

  static TextStyle subtitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppColors.onSurfaceVariant,
          );
}
