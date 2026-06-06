import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// AURA Social – Design System Colors
/// 
/// Bảng màu chính thức hỗ trợ Dark và Light Mode tự động.
class AuraColors {
  AuraColors._();

  static ThemeMode themeMode = ThemeMode.dark;

  static bool get _isLight {
    if (themeMode == ThemeMode.light) return true;
    if (themeMode == ThemeMode.dark) return false;
    return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BRAND COLORS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Color get primary => const Color(0xFF8B5CF6);       // Purple – brand chính
  static Color get primaryLight => const Color(0xFFA78BFA);
  static Color get primaryDark => const Color(0xFF7C3AED);
  
  static Color get secondary => const Color(0xFF06B6D4);     // Cyan – accent
  static Color get secondaryLight => const Color(0xFF22D3EE);
  static Color get secondaryDark => const Color(0xFF0891B2);

  static Color get tertiary => const Color(0xFFF472B6);      // Pink – accent phụ
  static Color get tertiaryLight => const Color(0xFFF9A8D4);
  static Color get tertiaryDark => const Color(0xFFEC4899);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DYNAMIC THEME SURFACES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Color get background => _isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0A0A0F);
  static Color get surface => _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF14141F);
  static Color get surfaceVariant => _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E1E2E);
  static Color get surfaceHigh => _isLight ? const Color(0xFFE2E8F0) : const Color(0xFF262640);
  static Color get surfaceBorder => _isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2A2A3E);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TEXT COLORS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Color get textPrimary => _isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
  static Color get textSecondary => _isLight ? const Color(0xFF334155) : const Color(0xFF94A3B8);
  static Color get textTertiary => _isLight ? const Color(0xFF64748B) : const Color(0xFF64748B);
  static Color get textOnPrimary => const Color(0xFFFFFFFF);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SEMANTIC COLORS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Color get success => const Color(0xFF22C55E);
  static Color get warning => const Color(0xFFF59E0B);
  static Color get error => const Color(0xFFEF4444);
  static Color get info => const Color(0xFF3B82F6);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EMOTION COLORS (8 cảm xúc Plutchik)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Color get emotionJoy => const Color(0xFFF59E0B);         // Amber
  static Color get emotionTrust => const Color(0xFF22C55E);       // Green
  static Color get emotionAnticipation => const Color(0xFFF97316); // Orange
  static Color get emotionSurprise => const Color(0xFF06B6D4);    // Cyan
  static Color get emotionSadness => const Color(0xFF3B82F6);     // Blue
  static Color get emotionFear => const Color(0xFF8B5CF6);        // Purple
  static Color get emotionAnger => const Color(0xFFEF4444);       // Red
  static Color get emotionDisgust => const Color(0xFF84CC16);     // Lime

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // GRADIENTS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradient => LinearGradient(
    colors: _isLight 
      ? [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)]
      : [const Color(0xFF1A1A2E), const Color(0xFF16162A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get shimmerGradient => LinearGradient(
    colors: [
      surfaceVariant,
      surfaceHigh,
      surfaceVariant,
    ],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Lấy color theo emotion type
  static Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':           return emotionJoy;
      case 'trust':         return emotionTrust;
      case 'anticipation':  return emotionAnticipation;
      case 'surprise':      return emotionSurprise;
      case 'sadness':       return emotionSadness;
      case 'fear':          return emotionFear;
      case 'anger':         return emotionAnger;
      case 'disgust':       return emotionDisgust;
      default:              return primary;
    }
  }
}
