import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AURA Social – Typography System
///
/// Sử dụng Inter (Google Fonts) cho toàn bộ app.
/// Tất cả text styles PHẢI lấy từ đây.
class AuraTypography {
  AuraTypography._();

  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  /// Helper: tạo TextStyle Inter với đầy đủ Unicode/tiếng Việt.
  /// Dùng GoogleFonts.inter() thay vì set fontFamily thủ công
  /// để đảm bảo font loader đăng ký đúng và hỗ trợ dấu tiếng Việt.
  static TextStyle _inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double height = 1.5,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DISPLAY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static TextStyle get displayLarge => _inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displayMedium => _inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle get displaySmall => _inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.3,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEADLINE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static TextStyle get headlineLarge => _inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle get headlineMedium => _inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle get headlineSmall => _inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TITLE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static TextStyle get titleLarge => _inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get titleMedium => _inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static TextStyle get titleSmall => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BODY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static TextStyle get bodyLarge => _inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle get bodyMedium => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );

  static TextStyle get bodySmall => _inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.4,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LABEL / BUTTON
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static TextStyle get labelLarge => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle get labelMedium => _inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => _inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );
}
