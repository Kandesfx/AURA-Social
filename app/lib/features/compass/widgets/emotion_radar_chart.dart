
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Emotion Radar Chart
///
/// Person 4, Task #13
/// 8-axis radar chart hiển thị emotion vector (Plutchik's wheel).
/// Sử dụng fl_chart RadarChart.
class EmotionRadarChart extends StatelessWidget {
  const EmotionRadarChart({
    super.key,
    required this.emotionVector,
    this.size = 220,
    this.showLabels = true,
  });

  final Map<String, double> emotionVector;
  final double size;
  final bool showLabels;

  static const _emotions = [
    {'key': 'joy', 'label': 'Joy', 'emoji': '😊'},
    {'key': 'trust', 'label': 'Trust', 'emoji': '🤝'},
    {'key': 'anticipation', 'label': 'Anticip.', 'emoji': '🎯'},
    {'key': 'surprise', 'label': 'Surprise', 'emoji': '😮'},
    {'key': 'sadness', 'label': 'Sadness', 'emoji': '😢'},
    {'key': 'fear', 'label': 'Fear', 'emoji': '😰'},
    {'key': 'anger', 'label': 'Anger', 'emoji': '😠'},
    {'key': 'disgust', 'label': 'Disgust', 'emoji': '🤢'},
  ];

  @override
  Widget build(BuildContext context) {
    final dataEntries = _emotions.map((e) {
      final value = emotionVector[e['key']] ?? 0.0;
      return RadarEntry(value: value * 100);
    }).toList();

    return SizedBox(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: dataEntries,
              fillColor: AuraColors.primary.withValues(alpha: 0.15),
              borderColor: AuraColors.primary,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(
            color: AuraColors.surfaceBorder.withValues(alpha: 0.5),
            width: 0.5,
          ),
          gridBorderData: BorderSide(
            color: AuraColors.surfaceBorder.withValues(alpha: 0.3),
            width: 0.5,
          ),
          tickCount: 4,
          ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
          tickBorderData: BorderSide(
            color: AuraColors.surfaceBorder.withValues(alpha: 0.2),
            width: 0.5,
          ),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: AuraTypography.labelSmall.copyWith(
            color: AuraColors.textSecondary,
            fontSize: 10,
          ),
          getTitle: (index, angle) {
            if (!showLabels || index >= _emotions.length) {
              return RadarChartTitle(text: '');
            }
            final emotion = _emotions[index];
            final value = emotionVector[emotion['key']] ?? 0.0;
            return RadarChartTitle(
              text: '${emotion['emoji']} ${(value * 100).round()}%',
              angle: angle,
              positionPercentageOffset: 0.15,
            );
          },
          radarShape: RadarShape.polygon,
        ),
      ),
    );
  }
}
