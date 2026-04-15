import 'package:flutter/material.dart';

/// Design system color tokens for "Familienherd" dark mode.
///
/// Usage: `AppColors.surface`, `AppColors.primary`, etc.
class AppColors {
  AppColors._();

  // ── Primary Surfaces ──────────────────────────────────────────────
  static const Color surface = Color(0xFF131312);
  static const Color background = Color(0xFF131312);
  static const Color surfaceDim = Color(0xFF131312);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0C);
  static const Color surfaceContainerLow = Color(0xFF1C1C1A);
  static const Color surfaceContainer = Color(0xFF20201E);
  static const Color surfaceContainerHigh = Color(0xFF2A2A28);
  static const Color surfaceContainerHighest = Color(0xFF353532);
  static const Color surfaceVariant = Color(0xFF353532);

  // ── Accent Colors ─────────────────────────────────────────────────
  static const Color primary = Color(0xFF66D9CC);
  static const Color primaryContainer = Color(0xFF26A69A);
  static const Color primaryFixed = Color(0xFF84F5E8);
  static const Color onPrimary = Color(0xFF003732);
  static const Color onPrimaryContainer = Color(0xFF003430);

  static const Color secondary = Color(0xFFFFD799);
  static const Color secondaryContainer = Color(0xFFFEB300);
  static const Color onSecondary = Color(0xFF432C00);

  static const Color tertiary = Color(0xFFFFB59B);
  static const Color tertiaryContainer = Color(0xFFDA7C5A);

  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // ── Text & Border Colors ──────────────────────────────────────────
  static const Color onSurface = Color(0xFFE5E2DE);
  static const Color onSurfaceVariant = Color(0xFFBCC9C6);
  static const Color outline = Color(0xFF869391);
  static const Color outlineVariant = Color(0xFF3D4947);
  static const Color inverseSurface = Color(0xFFE5E2DE);
  static const Color inverseOnSurface = Color(0xFF31302E);
  static const Color inversePrimary = Color(0xFF006A62);
  static const Color surfaceTint = Color(0xFF66D9CC);

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF26A69A), Color(0xFF66D9CC)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEB300), Color(0xFFFFD799)],
  );

  // ── Border Radius Tokens ──────────────────────────────────────────
  static const double radiusDefault = 16.0;
  static const double radiusMedium = 24.0;
  static const double radiusLarge = 32.0;
  static const double radiusXL = 48.0;
  static const double radiusFull = 9999.0;

  // ── Priority Colors ───────────────────────────────────────────────
  static const List<Color> priorityColors = [
    Color(0xFF869391), // none
    Color(0xFF66D9CC), // low
    Color(0xFFFFD799), // medium
    Color(0xFFFFB4AB), // high
  ];

  // ── Spacing Tokens ────────────────────────────────────────────────
  static const double spacing1 = 4.0;
  static const double spacing2 = 8.0;
  static const double spacing3 = 12.0;
  static const double spacing4 = 16.0;
  static const double spacing6 = 24.0;
  static const double spacing8 = 32.0;
  static const double spacing12 = 48.0;

  /// Parses `#RRGGBB` / `RRGGBB` from family member settings; [fallback] if missing/invalid.
  static Color memberColorFromHex(String? hex,
      {Color fallback = const Color(0xFF869391)}) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      var s = hex.replaceFirst('#', '');
      if (s.length == 6) s = 'FF$s';
      return Color(int.parse(s, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Readable foreground on [background] (member accent swatches).
  static Color onMemberAccent(Color background) {
    return background.computeLuminance() > 0.45
        ? const Color(0xFF1C1B1F)
        : Colors.white;
  }
}
