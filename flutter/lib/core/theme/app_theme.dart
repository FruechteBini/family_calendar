import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Gradient for primary-style buttons (matches [ColorScheme.primary] / [primaryContainer]).
@immutable
class FamilienThemeTokens extends ThemeExtension<FamilienThemeTokens> {
  const FamilienThemeTokens({required this.accentGradient});

  final LinearGradient accentGradient;

  static FamilienThemeTokens fromColorScheme(ColorScheme scheme) {
    return FamilienThemeTokens(
      accentGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.primaryContainer, scheme.primary],
      ),
    );
  }

  @override
  FamilienThemeTokens copyWith({LinearGradient? accentGradient}) {
    return FamilienThemeTokens(
      accentGradient: accentGradient ?? this.accentGradient,
    );
  }

  @override
  ThemeExtension<FamilienThemeTokens> lerp(
    ThemeExtension<FamilienThemeTokens>? other,
    double t,
  ) {
    if (other is! FamilienThemeTokens) return this;
    return FamilienThemeTokens(
      accentGradient: LinearGradient.lerp(
            accentGradient,
            other.accentGradient,
            t,
          ) ??
          accentGradient,
    );
  }
}

/// Dark-mode-only [ThemeData] for "Familienherd".
///
/// Usage in `MaterialApp`:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.dark(),
///   darkTheme: AppTheme.dark(),
///   themeMode: ThemeMode.dark,
/// );
/// ```
class AppTheme {
  AppTheme._();

  // ── Font references ───────────────────────────────────────────────
  static const String _plusJakarta = 'Plus Jakarta Sans';
  static const String _inter = 'Inter';

  // ── Letter-spacing helpers ────────────────────────────────────────
  /// -0.02 em (display tight)
  static double get _lsTight => -0.02;

  /// -0.01 em (headline tight)
  static double get _lsHeadline => -0.01;

  /// +0.01 em (label large)
  static double get _lsLabelLg => 0.01;

  /// +0.05 em (label medium / small)
  static double get _lsLabelSm => 0.05;

  // ── Text Theme ────────────────────────────────────────────────────
  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: _lsTight,
      ),
      displayMedium: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: _lsTight,
      ),
      displaySmall: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: _lsTight,
      ),
      headlineLarge: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: _lsHeadline,
      ),
      headlineMedium: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: _lsHeadline,
      ),
      headlineSmall: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.getFont(
        _plusJakarta,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.getFont(
        _inter,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.getFont(
        _inter,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.getFont(
        _inter,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.getFont(
        _inter,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: _lsLabelLg,
      ),
      labelMedium: GoogleFonts.getFont(
        _inter,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: _lsLabelSm,
      ),
      labelSmall: GoogleFonts.getFont(
        _inter,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: _lsLabelSm,
      ),
    );
  }

  // ── Color Scheme (surfaces + secondaries fixed; primary family from seed) ──
  static const ColorScheme _baseColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    tertiary: AppColors.tertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    surfaceDim: AppColors.surfaceDim,
    surfaceTint: AppColors.surfaceTint,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    inversePrimary: AppColors.inversePrimary,
    onSurfaceVariant: AppColors.onSurfaceVariant,
  );

  static ColorScheme colorSchemeWithAccent(Color accentSeed) {
    final derived = ColorScheme.fromSeed(
      seedColor: accentSeed,
      brightness: Brightness.dark,
    );
    return _baseColorScheme.copyWith(
      primary: derived.primary,
      onPrimary: derived.onPrimary,
      primaryContainer: derived.primaryContainer,
      onPrimaryContainer: derived.onPrimaryContainer,
      primaryFixed: derived.primaryFixed,
      primaryFixedDim: derived.primaryFixedDim,
      onPrimaryFixed: derived.onPrimaryFixed,
      onPrimaryFixedVariant: derived.onPrimaryFixedVariant,
      surfaceTint: derived.surfaceTint,
      inversePrimary: derived.inversePrimary,
    );
  }

  // ── Full ThemeData ────────────────────────────────────────────────
  static ThemeData dark({Color? accentSeed}) {
    final cs = colorSchemeWithAccent(accentSeed ?? AppColors.primary);
    final tokens = FamilienThemeTokens.fromColorScheme(cs);

    return ThemeData.dark(
      useMaterial3: true,
    ).copyWith(
      // ── Scaffold ───────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.surface,

      // ── Color scheme ───────────────────────────────────────────
      colorScheme: cs,

      // ── Custom tokens ──────────────────────────────────────────
      extensions: <ThemeExtension<dynamic>>[tokens],

      // ── Typography ─────────────────────────────────────────────
      textTheme: _textTheme,

      // ── Dividers: NO dividers ──────────────────────────────────
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),

      // ── AppBar (compact: ~half default toolbar for more content space) ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 28,
        titleTextStyle: GoogleFonts.getFont(
          _plusJakarta,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: _lsHeadline,
          color: cs.primary,
        ),
        iconTheme: IconThemeData(size: 20, color: cs.primary),
        actionsIconTheme: IconThemeData(size: 20, color: cs.primary),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(4),
          visualDensity: VisualDensity.compact,
          iconSize: 20,
        ),
      ),

      // ── Cards ──────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Decoration ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          borderSide: BorderSide(
            color: cs.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppColors.spacing4,
          vertical: AppColors.spacing3,
        ),
        hintStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.outline,
        ),
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: cs.primary,
        unselectedItemColor: AppColors.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Floating Action Button ─────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
        ),
      ),

      // ── Chips ──────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        selectedColor: AppColors.secondaryContainer,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.onSecondary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spacing3,
          vertical: AppColors.spacing2,
        ),
        side: BorderSide.none,
      ),

      // ── Elevated Button ────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing6,
            vertical: AppColors.spacing3,
          ),
          textStyle: GoogleFonts.getFont(
            _inter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing4,
            vertical: AppColors.spacing2,
          ),
          textStyle: GoogleFonts.getFont(
            _inter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: const BorderSide(color: AppColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing4,
            vertical: AppColors.spacing2,
          ),
          textStyle: GoogleFonts.getFont(
            _inter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Icon Theme ─────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariant,
        size: 24,
      ),

      // ── Snackbar ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainer,
        modalBackgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusLarge),
          ),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        ),
        titleTextStyle: GoogleFonts.getFont(
          _plusJakarta,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        contentTextStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
      ),

      // ── Switch ─────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary;
          }
          return AppColors.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primaryContainer;
          }
          return AppColors.surfaceContainerHighest;
        }),
      ),

      // ── Checkbox ───────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primaryContainer;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(cs.onPrimary),
        side: const BorderSide(color: AppColors.outline, width: 2),
        shape: const StadiumBorder(),
      ),

      // ── Slider ─────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: cs.primary,
        inactiveTrackColor: AppColors.surfaceContainerHighest,
        thumbColor: cs.primary,
        overlayColor: cs.primary.withOpacity(0.12),
        trackShape: const RoundedRectSliderTrackShape(),
      ),

      // ── Tab Bar ────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: AppColors.outline,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Navigation Rail ────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: cs.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.outline),
        selectedLabelTextStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
        unselectedLabelTextStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.outline,
        ),
      ),

      // ── Progress Indicator ─────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: AppColors.surfaceContainerHighest,
      ),

      // ── Tooltip ────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
        ),
        textStyle: GoogleFonts.getFont(
          _inter,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.inverseOnSurface,
        ),
        waitDuration: const Duration(milliseconds: 700),
      ),

      // ── Scrollbar ──────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          AppColors.outline.withOpacity(0.4),
        ),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(AppColors.radiusDefault),
      ),
    );
  }
}
