import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// AURA Social – Theme Configuration
///
/// Dark and Light themes.
class AuraTheme {
  AuraTheme._();

  static ThemeData _buildTheme({required bool isLight}) {
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0A0A0F);
    final surfaceColor = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF14141F);
    final surfaceVariantColor = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E1E2E);
    final surfaceHighColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF262640);
    final surfaceBorderColor = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2A2A3E);

    final textPrimaryColor = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final textSecondaryColor = isLight ? const Color(0xFF334155) : const Color(0xFF94A3B8);
    final textTertiaryColor = isLight ? const Color(0xFF64748B) : const Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: GoogleFonts.inter().fontFamily,

      colorScheme: isLight ? ColorScheme.light(
        primary: AuraColors.primary,
        onPrimary: AuraColors.textOnPrimary,
        secondary: AuraColors.secondary,
        onSecondary: AuraColors.textOnPrimary,
        tertiary: AuraColors.tertiary,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        error: AuraColors.error,
        onError: AuraColors.textOnPrimary,
      ) : ColorScheme.dark(
        primary: AuraColors.primary,
        onPrimary: AuraColors.textOnPrimary,
        secondary: AuraColors.secondary,
        onSecondary: AuraColors.textOnPrimary,
        tertiary: AuraColors.tertiary,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        error: AuraColors.error,
        onError: AuraColors.textOnPrimary,
      ),

      textTheme: TextTheme(
        displayLarge: AuraTypography.displayLarge.copyWith(color: textPrimaryColor),
        displayMedium: AuraTypography.displayMedium.copyWith(color: textPrimaryColor),
        displaySmall: AuraTypography.displaySmall.copyWith(color: textPrimaryColor),
        headlineLarge: AuraTypography.headlineLarge.copyWith(color: textPrimaryColor),
        headlineMedium: AuraTypography.headlineMedium.copyWith(color: textPrimaryColor),
        headlineSmall: AuraTypography.headlineSmall.copyWith(color: textPrimaryColor),
        titleLarge: AuraTypography.titleLarge.copyWith(color: textPrimaryColor),
        titleMedium: AuraTypography.titleMedium.copyWith(color: textPrimaryColor),
        titleSmall: AuraTypography.titleSmall.copyWith(color: textSecondaryColor),
        bodyLarge: AuraTypography.bodyLarge.copyWith(color: textPrimaryColor),
        bodyMedium: AuraTypography.bodyMedium.copyWith(color: textSecondaryColor),
        bodySmall: AuraTypography.bodySmall.copyWith(color: textTertiaryColor),
        labelLarge: AuraTypography.labelLarge.copyWith(color: textPrimaryColor),
        labelMedium: AuraTypography.labelMedium.copyWith(color: textSecondaryColor),
        labelSmall: AuraTypography.labelSmall.copyWith(color: textTertiaryColor),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AuraTypography.headlineSmall.copyWith(
          color: textPrimaryColor,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: surfaceColor,
          systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: AuraColors.primary,
        unselectedItemColor: textTertiaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: surfaceBorderColor, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantColor,
        hintStyle: AuraTypography.bodyMedium.copyWith(color: textTertiaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surfaceBorderColor, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AuraColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AuraColors.error, width: 1),
        ),
      ),

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

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: BorderSide(color: surfaceBorderColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AuraTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AuraColors.primary,
          textStyle: AuraTypography.labelLarge,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: textPrimaryColor,
        unselectedLabelColor: textTertiaryColor,
        labelStyle: AuraTypography.labelLarge,
        unselectedLabelStyle: AuraTypography.labelLarge,
        indicatorColor: AuraColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(
        color: surfaceBorderColor,
        thickness: 0.5,
        space: 0,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceVariantColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHighColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AuraTypography.headlineSmall.copyWith(color: textPrimaryColor),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantColor,
        selectedColor: AuraColors.primary.withValues(alpha: 0.2),
        labelStyle: AuraTypography.labelMedium.copyWith(color: textPrimaryColor),
        side: BorderSide(color: surfaceBorderColor, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHighColor,
        contentTextStyle: AuraTypography.bodyMedium.copyWith(color: textPrimaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DARK THEME (Default)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static ThemeData get dark => _buildTheme(isLight: false);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIGHT THEME
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static ThemeData get light => _buildTheme(isLight: true);
}
