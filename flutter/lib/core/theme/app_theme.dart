import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  // Border radius constants
  static const double radiusSmall = 16.0;
  static const double radiusMedium = 24.0;
  static const double radiusLarge = 32.0;

  static TextTheme _buildTextTheme(TextTheme base) {
    final headlineFont = GoogleFonts.plusJakartaSansTextTheme(base);
    final bodyFont = GoogleFonts.interTextTheme(base);

    return base.copyWith(
      displayLarge: headlineFont.displayLarge,
      displayMedium: headlineFont.displayMedium,
      displaySmall: headlineFont.displaySmall,
      headlineLarge: headlineFont.headlineLarge,
      headlineMedium: headlineFont.headlineMedium,
      headlineSmall: headlineFont.headlineSmall,
      titleLarge: headlineFont.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: headlineFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: headlineFont.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: bodyFont.bodyLarge,
      bodyMedium: bodyFont.bodyMedium,
      bodySmall: bodyFont.bodySmall,
      labelLarge: bodyFont.labelLarge,
      labelMedium: bodyFont.labelMedium,
      labelSmall: bodyFont.labelSmall,
    );
  }

  static ThemeData light() {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: StitchColorsLight.primary,
      onPrimary: StitchColorsLight.onPrimary,
      primaryContainer: StitchColorsLight.primaryContainer,
      onPrimaryContainer: StitchColorsLight.onPrimaryContainer,
      secondary: StitchColorsLight.secondary,
      onSecondary: StitchColorsLight.onSecondary,
      secondaryContainer: StitchColorsLight.secondaryContainer,
      onSecondaryContainer: StitchColorsLight.onSecondaryContainer,
      tertiary: StitchColorsLight.tertiary,
      onTertiary: StitchColorsLight.onTertiary,
      tertiaryContainer: StitchColorsLight.tertiaryContainer,
      onTertiaryContainer: StitchColorsLight.onTertiaryContainer,
      surface: StitchColorsLight.surface,
      onSurface: StitchColorsLight.onSurface,
      surfaceContainerLowest: StitchColorsLight.surfaceContainerLowest,
      surfaceContainerLow: StitchColorsLight.surfaceContainerLow,
      surfaceContainer: StitchColorsLight.surfaceContainer,
      surfaceContainerHigh: StitchColorsLight.surfaceContainerHigh,
      surfaceContainerHighest: StitchColorsLight.surfaceContainerHighest,
      onSurfaceVariant: StitchColorsLight.onSurfaceVariant,
      outline: StitchColorsLight.outline,
      outlineVariant: StitchColorsLight.outlineVariant,
      inverseSurface: StitchColorsLight.inverseSurface,
      onInverseSurface: StitchColorsLight.inverseOnSurface,
      inversePrimary: StitchColorsLight.inversePrimary,
      error: StitchColorsLight.error,
      onError: StitchColorsLight.onError,
      errorContainer: StitchColorsLight.errorContainer,
      onErrorContainer: StitchColorsLight.onErrorContainer,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: cs);

    return base.copyWith(
      scaffoldBackgroundColor: StitchColorsLight.background,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: StitchColorsLight.surface,
        foregroundColor: StitchColorsLight.primary,
        iconTheme: IconThemeData(color: StitchColorsLight.primary),
        titleTextStyle: TextStyle(
          color: StitchColorsLight.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: Color.fromRGBO(0, 106, 98, 0), // transparent — custom pill per item
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: StitchColorsLight.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: StitchColorsLight.primary, width: 2),
        ),
        filled: true,
        fillColor: StitchColorsLight.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: StitchColorsLight.primary,
        foregroundColor: StitchColorsLight.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: StitchColorsLight.outlineVariant,
        thickness: 1,
      ),
    );
  }

  static ThemeData dark() {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: StitchColorsDark.primary,
      onPrimary: StitchColorsDark.onPrimary,
      primaryContainer: StitchColorsDark.primaryContainer,
      onPrimaryContainer: StitchColorsDark.onPrimaryContainer,
      secondary: StitchColorsDark.secondary,
      onSecondary: StitchColorsDark.onSecondary,
      secondaryContainer: StitchColorsDark.secondaryContainer,
      onSecondaryContainer: StitchColorsDark.onSecondaryContainer,
      tertiary: StitchColorsDark.tertiary,
      onTertiary: StitchColorsDark.onTertiary,
      tertiaryContainer: StitchColorsDark.tertiaryContainer,
      onTertiaryContainer: StitchColorsDark.onTertiaryContainer,
      surface: StitchColorsDark.surface,
      onSurface: StitchColorsDark.onSurface,
      surfaceContainerLowest: StitchColorsDark.surfaceContainerLowest,
      surfaceContainerLow: StitchColorsDark.surfaceContainerLow,
      surfaceContainer: StitchColorsDark.surfaceContainer,
      surfaceContainerHigh: StitchColorsDark.surfaceContainerHigh,
      surfaceContainerHighest: StitchColorsDark.surfaceContainerHighest,
      onSurfaceVariant: StitchColorsDark.onSurfaceVariant,
      outline: StitchColorsDark.outline,
      outlineVariant: StitchColorsDark.outlineVariant,
      inverseSurface: StitchColorsDark.inverseSurface,
      onInverseSurface: StitchColorsDark.inverseOnSurface,
      inversePrimary: StitchColorsDark.inversePrimary,
      error: StitchColorsDark.error,
      onError: StitchColorsDark.onError,
      errorContainer: StitchColorsDark.errorContainer,
      onErrorContainer: StitchColorsDark.onErrorContainer,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: cs);

    return base.copyWith(
      scaffoldBackgroundColor: StitchColorsDark.background,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: StitchColorsDark.surface,
        foregroundColor: StitchColorsDark.primary,
        iconTheme: IconThemeData(color: StitchColorsDark.primary),
        titleTextStyle: TextStyle(
          color: StitchColorsDark.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: Color.fromRGBO(102, 217, 204, 0), // transparent — custom pill per item
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: StitchColorsDark.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: StitchColorsDark.primary, width: 2),
        ),
        filled: true,
        fillColor: StitchColorsDark.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: StitchColorsDark.primary,
        foregroundColor: StitchColorsDark.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: StitchColorsDark.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
