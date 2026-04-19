import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AURA Social – Emotion Gradients
///
/// Map mỗi cảm xúc → gradient tương ứng cho Aura Ring và UI elements.
class EmotionGradients {
  EmotionGradients._();

  static const Map<String, List<Color>> _emotionColors = {
    'joy':          [Color(0xFFF59E0B), Color(0xFFEF7C00)],
    'trust':        [Color(0xFF22C55E), Color(0xFF0D9488)],
    'anticipation': [Color(0xFFF97316), Color(0xFFF59E0B)],
    'surprise':     [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    'sadness':      [Color(0xFF3B82F6), Color(0xFF6366F1)],
    'fear':         [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    'anger':        [Color(0xFFEF4444), Color(0xFFE11D48)],
    'disgust':      [Color(0xFF84CC16), Color(0xFF22C55E)],
  };

  /// Gradient cho 1 cảm xúc cụ thể
  static LinearGradient forEmotion(String emotion) {
    final colors = _emotionColors[emotion.toLowerCase()] ??
        [AuraColors.primary, AuraColors.secondary];
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Gradient dựa trên emotion vector (blend top 3 emotions)
  static SweepGradient fromVector(Map<String, double> emotionVector) {
    if (emotionVector.isEmpty) {
      return const SweepGradient(
        colors: [AuraColors.primary, AuraColors.secondary, AuraColors.primary],
      );
    }

    // Sort by value descending → top 3
    final sorted = emotionVector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEmotions = sorted.take(3).toList();
    final colors = <Color>[];

    for (final entry in topEmotions) {
      final emotionColors = _emotionColors[entry.key.toLowerCase()];
      if (emotionColors != null) {
        colors.add(emotionColors[0]);
      }
    }

    // Ensure at least 2 colors for gradient
    while (colors.length < 2) {
      colors.add(AuraColors.primary);
    }
    // Close the sweep
    colors.add(colors.first);

    return SweepGradient(colors: colors);
  }

  /// Gradient mặc định (khi chưa có dữ liệu)
  static const SweepGradient defaultAuraGradient = SweepGradient(
    colors: [
      AuraColors.primary,
      AuraColors.secondary,
      AuraColors.tertiary,
      AuraColors.primary,
    ],
  );

  /// Gradient cho card highlight
  static LinearGradient cardHighlight(String emotion) {
    final colors = _emotionColors[emotion.toLowerCase()] ??
        [AuraColors.primary, AuraColors.secondary];
    return LinearGradient(
      colors: [
        colors[0].withValues(alpha: 0.15),
        colors[1].withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
