import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// AURA Social – Theme Configuration
///
/// Dark theme mặc định. ThemeData hoàn chỉnh cho toàn bộ app.
class AuraTheme {
  AuraTheme._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DARK THEME (Default)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AuraColors.background,

    // ── Color Scheme ──
    colorScheme: const ColorScheme.dark(
      primary: AuraColors.primary,
      onPrimary: AuraColors.textOnPrimary,
      secondary: AuraColors.secondary,
      onSecondary: AuraColors.textOnPrimary,
      tertiary: AuraColors.tertiary,
      surface: AuraColors.surface,
      onSurface: AuraColors.textPrimary,
      error: AuraColors.error,
      onError: AuraColors.textOnPrimary,
    ),

    // ── Text Theme ──
    textTheme: TextTheme(
      displayLarge: AuraTypography.displayLarge.copyWith(color: AuraColors.textPrimary),
      displayMedium: AuraTypography.displayMedium.copyWith(color: AuraColors.textPrimary),
      displaySmall: AuraTypography.displaySmall.copyWith(color: AuraColors.textPrimary),
      headlineLarge: AuraTypography.headlineLarge.copyWith(color: AuraColors.textPrimary),
      headlineMedium: AuraTypography.headlineMedium.copyWith(color: AuraColors.textPrimary),
      headlineSmall: AuraTypography.headlineSmall.copyWith(color: AuraColors.textPrimary),
      titleLarge: AuraTypography.titleLarge.copyWith(color: AuraColors.textPrimary),
      titleMedium: AuraTypography.titleMedium.copyWith(color: AuraColors.textPrimary),
      titleSmall: AuraTypography.titleSmall.copyWith(color: AuraColors.textSecondary),
      bodyLarge: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary),
      bodyMedium: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary),
      bodySmall: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary),
      labelLarge: AuraTypography.labelLarge.copyWith(color: AuraColors.textPrimary),
      labelMedium: AuraTypography.labelMedium.copyWith(color: AuraColors.textSecondary),
      labelSmall: AuraTypography.labelSmall.copyWith(color: AuraColors.textTertiary),
    ),

    // ── App Bar ──
    appBarTheme: AppBarTheme(
      backgroundColor: AuraColors.background,
      foregroundColor: AuraColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AuraTypography.headlineSmall.copyWith(
        color: AuraColors.textPrimary,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ── Bottom Navigation ──
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AuraColors.surface,
      selectedItemColor: AuraColors.primary,
      unselectedItemColor: AuraColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      color: AuraColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    // ── Input Decoration ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuraColors.surfaceVariant,
      hintStyle: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AuraColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AuraColors.error, width: 1),
      ),
    ),

    // ── Elevated Button ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AuraColors.primary,
        foregroundColor: AuraColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AuraTypography.labelLarge,
      ),
    ),

    // ── Outlined Button ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AuraColors.textPrimary,
        side: const BorderSide(color: AuraColors.surfaceBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AuraTypography.labelLarge,
      ),
    ),

    // ── Text Button ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AuraColors.primary,
        textStyle: AuraTypography.labelLarge,
      ),
    ),

    // ── Tab Bar ──
    tabBarTheme: TabBarThemeData(
      labelColor: AuraColors.textPrimary,
      unselectedLabelColor: AuraColors.textTertiary,
      labelStyle: AuraTypography.labelLarge,
      unselectedLabelStyle: AuraTypography.labelLarge,
      indicatorColor: AuraColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: AuraColors.surfaceBorder,
      thickness: 0.5,
      space: 0,
    ),

    // ── Bottom Sheet ──
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AuraColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: AuraColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: AuraTypography.headlineSmall.copyWith(color: AuraColors.textPrimary),
    ),

    // ── Chip ──
    chipTheme: ChipThemeData(
      backgroundColor: AuraColors.surfaceVariant,
      selectedColor: AuraColors.primary.withValues(alpha: 0.2),
      labelStyle: AuraTypography.labelMedium.copyWith(color: AuraColors.textPrimary),
      side: const BorderSide(color: AuraColors.surfaceBorder, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // ── Snackbar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AuraColors.surfaceHigh,
      contentTextStyle: AuraTypography.bodyMedium.copyWith(color: AuraColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIGHT THEME (Future)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static ThemeData get light => dark; // TODO: Implement light theme
}
