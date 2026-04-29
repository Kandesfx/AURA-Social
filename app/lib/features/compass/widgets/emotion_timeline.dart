import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Emotion Timeline Widget
///
/// Person 4, Task #14
/// 7-day line chart showing valence trend.
class EmotionTimeline extends StatelessWidget {
  const EmotionTimeline({
    super.key,
    this.height = 180,
  });

  final double height;

  // Mock 7-day data (valence: -1.0 to 1.0)
  static const _mockData = [
    {'day': 'T2', 'valence': 0.3, 'arousal': 0.5},
    {'day': 'T3', 'valence': -0.1, 'arousal': 0.7},
    {'day': 'T4', 'valence': -0.2, 'arousal': 0.6},
    {'day': 'T5', 'valence': 0.4, 'arousal': 0.4},
    {'day': 'T6', 'valence': 0.6, 'arousal': 0.5},
    {'day': 'T7', 'valence': 0.7, 'arousal': 0.3},
    {'day': 'CN', 'valence': 0.5, 'arousal': 0.4},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AuraColors.surfaceBorder.withValues(alpha: 0.3),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 0.5,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  if (value == 1.0) {
                    text = '😊';
                  } else if (value == 0.0) {
                    text = '😐';
                  } else if (value == -1.0) {
                    text = '😢';
                  }
                  return Text(text, style: const TextStyle(fontSize: 14));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _mockData.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _mockData[index]['day'] as String,
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: -1,
          maxY: 1,
          lineBarsData: [
            // Valence line
            LineChartBarData(
              spots: _mockData.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), (e.value['valence'] as num).toDouble());
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: AuraColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AuraColors.primary,
                    strokeWidth: 2,
                    strokeColor: AuraColors.background,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AuraColors.primary.withValues(alpha: 0.2),
                    AuraColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Zero line reference
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), 0)),
              isCurved: false,
              color: AuraColors.surfaceBorder.withValues(alpha: 0.5),
              barWidth: 0.5,
              dotData: const FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AuraColors.surfaceHigh,
              tooltipRoundedRadius: 8,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  if (spot.barIndex != 0) return null;
                  final valence = spot.y;
                  final mood = valence > 0.3
                      ? '😊 Tích cực'
                      : valence < -0.3
                          ? '😢 Tiêu cực'
                          : '😐 Bình thường';
                  return LineTooltipItem(
                    mood,
                    AuraTypography.labelMedium.copyWith(color: AuraColors.textPrimary),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ),
    );
  }
}
