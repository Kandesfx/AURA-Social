import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social - Mood Trend Chart
///
/// Line chart hien thi mood/valence trend trong 7 ngay.
/// Su dung fl_chart LineChart.
class MoodTrendChart extends StatelessWidget {
  const MoodTrendChart({
    super.key,
    required this.weeklyData,
    this.height = 200,
  });

  final Map<String, dynamic> weeklyData;
  final double height;

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 0.5,
                getTitlesWidget: (value, meta) {
                  String label;
                  if (value >= 0.6) {
                    label = 'Tot';
                  } else if (value >= 0.2) {
                    label = 'Kha';
                  } else if (value >= -0.2) {
                    label = 'BT';
                  } else if (value >= -0.6) {
                    label = 'Thap';
                  } else {
                    label = 'Kem';
                  }
                  return Text(label, style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.textTertiary, fontSize: 9));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final labels = _getDayLabels();
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[idx],
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.textTertiary, fontSize: 9)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: -1.0,
          maxY: 1.0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AuraColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: _getSpotColor(spot.y),
                    strokeWidth: 2,
                    strokeColor: AuraColors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AuraColors.primary.withValues(alpha: 0.25),
                    AuraColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (touchedSpot) => AuraColors.surfaceHigh,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    _formatValence(spot.y),
                    AuraTypography.labelSmall.copyWith(
                      color: _getSpotColor(spot.y),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final result = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      final key = 'day_$i';
      if (weeklyData.containsKey(key)) {
        final val = (weeklyData[key] as num?)?.toDouble() ?? 0.0;
        result.add(FlSpot(i.toDouble(), val.clamp(-1.0, 1.0)));
      } else {
        if (result.isNotEmpty) {
          final prev = result.last.y;
          result.add(FlSpot(i.toDouble(), prev));
        }
      }
    }
    return result;
  }

  List<String> _getDayLabels() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return 'T${day.weekday} ${day.day}';
    });
  }

  Color _getSpotColor(double valence) {
    if (valence >= 0.5) return AuraColors.success;
    if (valence >= 0.2) return const Color(0xFF22C55E);
    if (valence >= -0.2) return AuraColors.warning;
    return AuraColors.error;
  }

  String _formatValence(double v) {
    final pct = ((v + 1) / 2 * 100).round();
    final sign = v >= 0 ? '+' : '';
    return 'Valence: $sign${v.toStringAsFixed(2)} ($pct%)';
  }
}
