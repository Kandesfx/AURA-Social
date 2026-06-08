import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social - Emotion Distribution Chart
///
/// Pie chart hien thi phan bo cac cam xuc trong 7 ngay.
/// Su dung fl_chart PieChart.
class EmotionDistributionChart extends StatelessWidget {
  const EmotionDistributionChart({
    super.key,
    required this.emotionCounts,
    this.height = 200,
  });

  final Map<String, int> emotionCounts;
  final double height;

  static const _emotionMeta = {
    'joy':        {'emoji': '😊', 'label': 'Vui',        'color': Color(0xFF4ADE80)},
    'trust':      {'emoji': '🤝', 'label': 'Tin',        'color': Color(0xFF60A5FA)},
    'anticipation': {'emoji': '🎯', 'label': 'Mong',      'color': Color(0xFFFBBF24)},
    'surprise':   {'emoji': '😮', 'label': 'Ngac',       'color': Color(0xFFFB923C)},
    'sadness':    {'emoji': '😢', 'label': 'Buon',      'color': Color(0xFF818CF8)},
    'fear':       {'emoji': '😰', 'label': 'So',        'color': Color(0xFFA78BFA)},
    'anger':      {'emoji': '😠', 'label': 'Gian',      'color': Color(0xFFF87171)},
    'disgust':    {'emoji': '🤢', 'label': 'Ghe',       'color': Color(0xFF6EE7B7)},
  };

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    if (sections.isEmpty) return const SizedBox.shrink();
    final total = sections.fold<int>(0, (s, sec) => s + sec.value.toInt());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phan bo cam xuc 7 ngay',
            style: AuraTypography.titleSmall.copyWith(
              color: AuraColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: height - 20,
                height: height - 20,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(touchCallback: (event, response) {}),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildLegend(sections, total)),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final result = <PieChartSectionData>[];
    for (final entry in emotionCounts.entries) {
      final count = entry.value;
      if (count <= 0) continue;
      final meta = _emotionMeta[entry.key];
      if (meta == null) continue;
      result.add(PieChartSectionData(
        value: count.toDouble(),
        title: '',
        color: meta['color'] as Color,
        radius: 48,
      ));
    }
    return result;
  }

  Widget _buildLegend(List<PieChartSectionData> sections, int total) {
    final sorted = <_LegendItem>[];
    for (final section in sections) {
      final metaEntry = _emotionMeta.entries.firstWhere(
        (e) => (e.value['color'] as Color).toARGB32() == section.color.toARGB32(),
        orElse: () => MapEntry('joy', _emotionMeta['joy']!),
      );
      final pct = total > 0 ? (section.value / total * 100).round() : 0;
      sorted.add(_LegendItem(key: metaEntry.key, meta: metaEntry.value,
        count: section.value.toInt(), pct: pct));
    }
    sorted.sort((a, b) => b.count.compareTo(a.count));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.take(6).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(width: 10, height: 10,
                decoration: BoxDecoration(
                  color: item.meta['color'] as Color,
                  shape: BoxShape.circle,
                )),
              const SizedBox(width: 6),
              Text(item.meta['emoji'] as String, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(item.meta['label'] as String,
                  style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.textSecondary)),
              ),
              Text('${item.pct}%',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final String key;
  final Map<String, dynamic> meta;
  final int count;
  final int pct;
  _LegendItem({required this.key, required this.meta,
    required this.count, required this.pct});
}
