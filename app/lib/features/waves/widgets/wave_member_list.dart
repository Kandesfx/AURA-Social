import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../models/wave_model.dart';

/// AURA Social – Wave Member List Widget
///
/// Hiển thị stacked avatars với Aura Ring + expandable member list.
class WaveMemberList extends StatelessWidget {
  const WaveMemberList({
    super.key,
    required this.members,
    this.maxVisible = 4,
    this.remainingCount = 0,
  });

  final List<WaveMember> members;
  final int maxVisible;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    final visibleMembers = members.take(maxVisible).toList();
    final extra = remainingCount > 0
        ? remainingCount
        : (members.length > maxVisible ? members.length - maxVisible : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Stacked avatars ──
        SizedBox(
          height: 36,
          width: (visibleMembers.length * 26) + (extra > 0 ? 30 : 0) + 10,
          child: Stack(
            children: [
              for (int i = 0; i < visibleMembers.length; i++)
                Positioned(
                  left: i * 26.0,
                  child: AuraRing(
                    size: 36,
                    emotionVector: visibleMembers[i].emotionVector,
                    animate: false,
                    glowIntensity: 0.2,
                  ),
                ),
              if (extra > 0)
                Positioned(
                  left: visibleMembers.length * 26.0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AuraColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AuraColors.surfaceBorder,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+$extra',
                        style: AuraTypography.labelSmall.copyWith(
                          color: AuraColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Expandable member list (full view)
class WaveMemberListExpanded extends StatelessWidget {
  const WaveMemberListExpanded({
    super.key,
    required this.members,
  });

  final List<WaveMember> members;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AuraRing(
                size: 40,
                emotionVector: member.emotionVector,
                animate: false,
                glowIntensity: 0.2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: AuraTypography.titleSmall.copyWith(
                        color: AuraColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${member.messageCount} tin nhắn',
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
