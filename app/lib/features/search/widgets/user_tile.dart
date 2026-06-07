import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';

/// AURA Social – User Search Tile
///
/// Widget hiển thị user trong kết quả tìm kiếm.
/// Bao gồm: Aura Ring avatar, tên, bio, emotion badge.
class UserSearchTile extends StatelessWidget {
  const UserSearchTile({
    super.key,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.emotionVector,
    this.dominantEmotion,
    this.isOnline = false,
    required this.onTap,
  });

  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final Map<String, double>? emotionVector;
  final String? dominantEmotion;
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emotionColor = dominantEmotion != null
        ? AuraColors.getEmotionColor(dominantEmotion!)
        : AuraColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Stack(
        children: [
          AuraRing(
            size: 48,
            imageUrl: avatarUrl,
            emotionVector: emotionVector,
            animate: false,
            glowIntensity: 0.2,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AuraColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AuraColors.background,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        displayName,
        style: AuraTypography.titleSmall.copyWith(
          color: AuraColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: bio != null && bio!.isNotEmpty
          ? Text(
              bio!,
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: dominantEmotion != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: emotionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _emotionLabel(dominantEmotion!),
                style: AuraTypography.labelSmall.copyWith(
                  color: emotionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  String _emotionLabel(String emotion) {
    const labels = {
      'joy': '😊 Joy',
      'trust': '🤝 Trust',
      'anticipation': '🔥 Hype',
      'surprise': '✨ Wow',
      'sadness': '💙 Calm',
      'fear': '😰 Fear',
      'anger': '😤 Fire',
      'disgust': '😑 Meh',
    };
    return labels[emotion.toLowerCase()] ?? emotion;
  }
}
