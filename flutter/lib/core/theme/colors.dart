import 'package:flutter/material.dart';

/// Stitch Design System — Light Mode Color Tokens
class StitchColorsLight {
  StitchColorsLight._();

  static const primary = Color(0xFF006A62);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF26A69A);
  static const onPrimaryContainer = Color(0xFF003430);
  static const primaryFixed = Color(0xFF84F5E8);
  static const primaryFixedDim = Color(0xFF66D9CC);

  static const secondary = Color(0xFF865300);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFDA625);
  static const onSecondaryContainer = Color(0xFF694000);

  static const tertiary = Color(0xFFAC3509);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFF6693D);
  static const onTertiaryContainer = Color(0xFF5A1500);

  static const surface = Color(0xFFF5FAF8);
  static const onSurface = Color(0xFF171D1C);
  static const surfaceBright = Color(0xFFF5FAF8);
  static const surfaceDim = Color(0xFFD6DBD9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF5F3);
  static const surfaceContainer = Color(0xFFEAEFED);
  static const surfaceContainerHigh = Color(0xFFE4E9E7);
  static const surfaceContainerHighest = Color(0xFFDEE4E1);

  static const background = Color(0xFFF5FAF8);
  static const onBackground = Color(0xFF171D1C);

  static const outline = Color(0xFF6D7A77);
  static const outlineVariant = Color(0xFFBCC9C6);
  static const inverseSurface = Color(0xFF2C3230);
  static const onSurfaceVariant = Color(0xFF3D4947);
  static const inversePrimary = Color(0xFF66D9CC);
  static const inverseOnSurface = Color(0xFFEDF2F0);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

/// Stitch Design System — Dark Mode Color Tokens
class StitchColorsDark {
  StitchColorsDark._();

  static const primary = Color(0xFF66D9CC);
  static const onPrimary = Color(0xFF003732);
  static const primaryContainer = Color(0xFF26A69A);
  static const onPrimaryContainer = Color(0xFF003430);

  static const secondary = Color(0xFFFFD799);
  static const onSecondary = Color(0xFF432C00);
  static const secondaryContainer = Color(0xFFFEB300);
  static const onSecondaryContainer = Color(0xFF6A4800);

  static const tertiary = Color(0xFFFFB59B);
  static const onTertiary = Color(0xFF5B1B02);
  static const tertiaryContainer = Color(0xFFDA7C5A);
  static const onTertiaryContainer = Color(0xFF571800);

  static const surface = Color(0xFF131312);
  static const onSurface = Color(0xFFE5E2DE);
  static const surfaceBright = Color(0xFF3A3937);
  static const surfaceDim = Color(0xFF131312);
  static const surfaceContainerLowest = Color(0xFF0E0E0C);
  static const surfaceContainerLow = Color(0xFF1C1C1A);
  static const surfaceContainer = Color(0xFF20201E);
  static const surfaceContainerHigh = Color(0xFF2A2A28);
  static const surfaceContainerHighest = Color(0xFF353532);

  static const background = Color(0xFF131312);
  static const onBackground = Color(0xFFE5E2DE);

  static const outline = Color(0xFF869391);
  static const outlineVariant = Color(0xFF3D4947);
  static const inverseSurface = Color(0xFFE5E2DE);
  static const onSurfaceVariant = Color(0xFFBCC9C6);
  static const inversePrimary = Color(0xFF006A62);
  static const inverseOnSurface = Color(0xFF31302E);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

/// Legacy AppColors kept for category / member color maps
class AppColors {
  AppColors._();

  // Keep these for category/member usage throughout the app
  static const Map<String, Color> categoryDefaults = {
    'Arbeit': Color(0xFF006A62),
    'Familie': Color(0xFF26A69A),
    'Gesundheit': Color(0xFFAC3509),
    'Einkauf': Color(0xFF865300),
    'Sonstiges': Color(0xFF6D7A77),
  };

  static const List<Color> memberColors = [
    Color(0xFF006A62),
    Color(0xFF26A69A),
    Color(0xFF865300),
    Color(0xFFFDA625),
    Color(0xFFAC3509),
    Color(0xFFF6693D),
    Color(0xFF003430),
    Color(0xFF694000),
  ];

  static const List<Color> priorityColors = [
    Color(0xFF6D7A77), // none
    Color(0xFF006A62), // low
    Color(0xFF865300), // medium
    Color(0xFFAC3509), // high
  ];
}
