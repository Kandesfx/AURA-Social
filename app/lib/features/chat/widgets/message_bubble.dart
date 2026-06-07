import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/message_model.dart';
import 'message_actions_sheet.dart';

/// AURA Social – Message Bubble Widget
///
/// Hiển thị 1 tin nhắn trong chat.
/// - My message: gradient purple → cyan, right-aligned
/// - Other's message: dark surface, left-aligned
/// - Emotion tint: subtle background dựa trên AI sentiment
/// - Long-press: show action sheet (react, reply, copy, delete)
/// - Reactions bar: emoji reactions dưới bubble
/// - Reply preview: hiện trên content nếu tin nhắn trả lời tin khác
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTimestamp = true,
    this.showReadStatus = true,
    this.isLastInGroup = true,
    this.onLongPress,
    this.onReplyTap,
  });

  final MessageModel message;
  final bool isMine;
  final bool showTimestamp;
  final bool showReadStatus;
  final bool isLastInGroup;
  final VoidCallback? onLongPress;
  final void Function(String messageId)? onReplyTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 64 : 16,
        right: isMine ? 16 : 64,
        top: 2,
        bottom: isLastInGroup ? 8 : 2,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ── Message Bubble ──
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine ? _myBubbleGradient : null,
                color: isMine ? null : _otherBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : (isLastInGroup ? 4 : 18)),
                  bottomRight: Radius.circular(isMine ? (isLastInGroup ? 4 : 18) : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMine
                        ? AuraColors.primary.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reply preview (nếu có)
                  if (message.replyTo != null) _buildReplyPreview(),
                  // Main content
                  _buildContent(),
                ],
              ),
            ),
          ),

          // ── Reactions ──
          if (message.reactions.isNotEmpty)
            MessageReactionsBar(
              reactions: message.reactionCounts,
              isMine: isMine,
            ),

          // ── Timestamp + Read Status ──
          if (showTimestamp && isLastInGroup)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: AuraTypography.labelSmall.copyWith(
                      color: AuraColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  if (isMine && showReadStatus) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: _isRead
                          ? AuraColors.secondary
                          : AuraColors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Reply preview bar phía trên content
  Widget _buildReplyPreview() {
    final reply = message.replyTo!;
    return GestureDetector(
      onTap: () => onReplyTap?.call(reply.messageId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.15)
              : AuraColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: AuraColors.primary,
              width: 2.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply.senderName,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              reply.content.length > 60
                  ? '${reply.content.substring(0, 60)}...'
                  : reply.content,
              style: AuraTypography.bodySmall.copyWith(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.7)
                    : AuraColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: message.mediaUrl != null && message.mediaUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: message.mediaUrl!,
                      width: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 220,
                        height: 160,
                        color: AuraColors.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AuraColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 220,
                        height: 160,
                        color: AuraColors.surfaceVariant,
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 40,
                          color: AuraColors.textTertiary,
                        ),
                      ),
                    )
                  : Container(
                      width: 220,
                      height: 160,
                      color: AuraColors.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.image_rounded,
                          size: 48,
                          color: AuraColors.textTertiary,
                        ),
                      ),
                    ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message.content,
                style: AuraTypography.bodyMedium.copyWith(
                  color: isMine ? Colors.white : AuraColors.textPrimary,
                ),
              ),
            ],
          ],
        );

      case MessageType.system:
        return Text(
          message.content,
          style: AuraTypography.bodySmall.copyWith(
            color: AuraColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        );

      default:
        return Text(
          message.content,
          style: AuraTypography.bodyMedium.copyWith(
            color: isMine ? Colors.white : AuraColors.textPrimary,
            height: 1.4,
          ),
        );
    }
  }

  // ── Helpers ──

  LinearGradient get _myBubbleGradient {
    // Emotion tint: nếu có AI sentiment, blend nhẹ
    final emotionColor = message.aiSentiment != null
        ? AuraColors.getEmotionColor(message.aiSentiment!)
        : AuraColors.primary;

    return LinearGradient(
      colors: [
        Color.lerp(AuraColors.primary, emotionColor, 0.3)!,
        Color.lerp(AuraColors.primaryDark, emotionColor, 0.15)!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color get _otherBubbleColor {
    if (message.aiSentiment != null) {
      final emotionColor =
          AuraColors.getEmotionColor(message.aiSentiment!);
      return Color.lerp(
        AuraColors.surfaceVariant,
        emotionColor,
        0.08,
      )!;
    }
    return AuraColors.surfaceVariant;
  }

  bool get _isRead {
    // Coi là đã đọc nếu ít nhất 1 người khác đã đọc
    return message.readBy.entries
        .any((e) => e.key != message.senderId && e.value);
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// System message – hiển thị giữa (e.g. "Bạn vừa kết nối")
class SystemMessageBubble extends StatelessWidget {
  const SystemMessageBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 48),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AuraColors.surfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message,
            style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Date separator
class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: AuraColors.surfaceBorder,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              date,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: AuraColors.surfaceBorder,
            ),
          ),
        ],
      ),
    );
  }
}
