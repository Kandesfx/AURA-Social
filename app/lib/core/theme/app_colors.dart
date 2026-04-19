import 'package:flutter/material.dart';

/// AURA Social – Design System Colors
/// 
/// Bảng màu chính thức. Tất cả các screen/widget PHẢI sử dụng colors từ đây.
/// KHÔNG được hardcode màu trong widget.
class AuraColors {
  AuraColors._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BRAND COLORS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color primary = Color(0xFF8B5CF6);       // Purple – brand chính
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF7C3AED);
  
  static const Color secondary = Color(0xFF06B6D4);     // Cyan – accent
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);

  static const Color tertiary = Color(0xFFF472B6);      // Pink – accent phụ
  static const Color tertiaryLight = Color(0xFFF9A8D4);
  static const Color tertiaryDark = Color(0xFFEC4899);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DARK THEME SURFACES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color background = Color(0xFF0A0A0F);     // Gần đen, hơi tím
  static const Color surface = Color(0xFF14141F);        // Card background
  static const Color surfaceVariant = Color(0xFF1E1E2E); // Elevated surface
  static const Color surfaceHigh = Color(0xFF262640);    // Dialog, modal
  static const Color surfaceBorder = Color(0xFF2A2A3E);  // Border subtle

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TEXT COLORS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color textPrimary = Color(0xFFE2E8F0);    // Text chính
  static const Color textSecondary = Color(0xFF94A3B8);  // Text phụ
  static const Color textTertiary = Color(0xFF64748B);   // Text muted
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // Text trên primary

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SEMANTIC COLORS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EMOTION COLORS (8 cảm xúc Plutchik)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color emotionJoy = Color(0xFFF59E0B);         // Amber
  static const Color emotionTrust = Color(0xFF22C55E);       // Green
  static const Color emotionAnticipation = Color(0xFFF97316); // Orange
  static const Color emotionSurprise = Color(0xFF06B6D4);    // Cyan
  static const Color emotionSadness = Color(0xFF3B82F6);     // Blue
  static const Color emotionFear = Color(0xFF8B5CF6);        // Purple
  static const Color emotionAnger = Color(0xFFEF4444);       // Red
  static const Color emotionDisgust = Color(0xFF84CC16);     // Lime

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // GRADIENTS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16162A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFF1E1E2E),
      Color(0xFF2A2A3E),
      Color(0xFF1E1E2E),
    ],
    stops: [0.0, 0.5, 1.0],
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
