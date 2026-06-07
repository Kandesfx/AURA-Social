import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/message_model.dart';

/// AURA Social – Message Actions Sheet
///
/// Bottom sheet hiện khi long-press tin nhắn.
/// Actions: React, Reply, Copy, Delete (own msg only)
class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReaction,
    required this.onReply,
    required this.onCopy,
    this.onDelete,
    this.currentUserId,
  });

  final MessageModel message;
  final bool isMine;
  final void Function(String emotion) onReaction;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback? onDelete;
  final String? currentUserId;

  /// 8 Plutchik emotions cho reactions
  static const emotionReactions = [
    ('joy', '😊', 'Joy'),
    ('trust', '🤝', 'Trust'),
    ('anticipation', '🤩', 'Hype'),
    ('surprise', '😮', 'Wow'),
    ('sadness', '😢', 'Sad'),
    ('fear', '😰', 'Fear'),
    ('anger', '😡', 'Angry'),
    ('disgust', '🤢', 'Ugh'),
  ];

  @override
  Widget build(BuildContext context) {
    // Check xem current user đã react chưa
    final myReaction = currentUserId != null
        ? message.reactions[currentUserId]
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AuraColors.primary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AuraColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Reaction Picker ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AuraColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AuraColors.surfaceBorder,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: emotionReactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final (emotion, emoji, _) = entry.value;
                    final isSelected = myReaction == emotion;

                    return GestureDetector(
                      onTap: () {
                        onReaction(emotion);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AuraColors.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 24,
                          ),
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: 30 * index))
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: 250.ms,
                          curve: Curves.elasticOut,
                        );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Message preview ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AuraColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.content.length > 100
                      ? '${message.content.substring(0, 100)}...'
                      : message.content,
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Action buttons ──
            _ActionTile(
              icon: Icons.reply_rounded,
              label: 'Trả lời',
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            _ActionTile(
              icon: Icons.copy_rounded,
              label: 'Sao chép',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                onCopy();
              },
            ),
            if (isMine && onDelete != null)
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Xóa tin nhắn',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Một dòng action trong bottom sheet
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AuraColors.error
        : AuraColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: AuraTypography.bodyLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị reactions dưới message bubble
class MessageReactionsBar extends StatelessWidget {
  const MessageReactionsBar({
    super.key,
    required this.reactions,
    required this.isMine,
  });

  final Map<String, int> reactions;
  final bool isMine;

  static const _emotionEmoji = {
    'joy': '😊',
    'trust': '🤝',
    'anticipation': '🤩',
    'surprise': '😮',
    'sadness': '😢',
    'fear': '😰',
    'anger': '😡',
    'disgust': '🤢',
  };

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        left: isMine ? 0 : 8,
        right: isMine ? 8 : 0,
      ),
      child: Wrap(
        alignment: isMine ? WrapAlignment.end : WrapAlignment.start,
        spacing: 4,
        children: reactions.entries.map((entry) {
          final emoji = _emotionEmoji[entry.key] ?? '❓';
          final count = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AuraColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AuraColors.surfaceBorder,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                if (count > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '$count',
                    style: AuraTypography.labelSmall.copyWith(
                      color: AuraColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
