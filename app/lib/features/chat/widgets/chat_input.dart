import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/message_model.dart';

/// AURA Social – Chat Input Widget
///
/// Input bar cho tin nhắn: text field + attach + emoji + send button.
/// Send button chỉ hiện khi có text, với gradient animation.
/// Reply banner hiện khi đang trả lời tin nhắn.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.onAttach,
    this.onEmoji,
    this.enabled = true,
    this.onTypingChanged,
    this.replyingTo,
    this.onCancelReply,
    this.controller,
  });

  final void Function(String message) onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onEmoji;
  final bool enabled;
  final void Function(bool isTyping)? onTypingChanged;
  final TextEditingController? controller;

  /// Tin nhắn đang reply (null = không reply)
  final MessageModel? replyingTo;

  /// Callback khi cancel reply
  final VoidCallback? onCancelReply;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  bool _isLocalController = false;
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isLocalController = false;
    } else {
      _controller = TextEditingController();
      _isLocalController = true;
    }
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showEmoji = false;
      });
    }
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-focus khi bắt đầu reply
    if (widget.replyingTo != null && oldWidget.replyingTo == null) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_isLocalController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      widget.onTypingChanged?.call(hasText);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 12),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AuraColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AuraColors.surfaceBorder.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Reply Banner ──
              if (widget.replyingTo != null) _buildReplyBanner(),

              // ── Input Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attach Button
                    _ActionButton(
                      icon: Icons.add_rounded,
                      onTap: widget.onAttach,
                      tooltip: 'Đính kèm',
                    ),

                    const SizedBox(width: 4),

                    // Text Input
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Emoji button
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 4),
                              child: _ActionButton(
                                icon: _showEmoji
                                    ? Icons.keyboard_rounded
                                    : Icons.emoji_emotions_outlined,
                                onTap: () {
                                  if (_showEmoji) {
                                    _focusNode.requestFocus();
                                  } else {
                                    _focusNode.unfocus();
                                  }
                                  setState(() {
                                    _showEmoji = !_showEmoji;
                                  });
                                },
                                tooltip: 'Emoji',
                                size: 20,
                              ),
                            ),

                            // TextField
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                enabled: widget.enabled,
                                maxLines: 5,
                                minLines: 1,
                                textCapitalization: TextCapitalization.sentences,
                                style: AuraTypography.bodyMedium.copyWith(
                                  color: AuraColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: widget.replyingTo != null
                                      ? 'Trả lời...'
                                      : 'Nhắn tin...',
                                  hintStyle: AuraTypography.bodyMedium.copyWith(
                                    color: AuraColors.textTertiary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _handleSend(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Send Button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: _hasText
                          ? _SendButton(
                              key: const ValueKey('send'),
                              onTap: _handleSend,
                            )
                          : _ActionButton(
                              key: const ValueKey('mic'),
                              icon: Icons.mic_rounded,
                              onTap: () {},
                              tooltip: 'Voice',
                            ),
                    ),
                  ],
                ),
              ),
              if (_showEmoji)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  child: _buildEmojiPanel(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPanel() {
    final emojis = [
      '😊', '😭', '😍', '👍', '🔥', '😂', '😮', '👏',
      '🤝', '🎯', '❤️', '🤔', '🙄', '😱', '🥳', '😎',
      '😡', '💩', '🙏', '✨', '👀', '💯', '💔', '🌟'
    ];

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AuraColors.surface,
        border: Border(
          top: BorderSide(
            color: AuraColors.surfaceBorder.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          final emoji = emojis[index];
          return InkWell(
            onTap: () {
              final text = _controller.text;
              final selection = _controller.selection;
              
              final start = selection.start >= 0 ? selection.start : text.length;
              final end = selection.end >= 0 ? selection.end : text.length;

              final newText = text.replaceRange(start, end, emoji);
              _controller.text = newText;
              
              _controller.selection = TextSelection.collapsed(
                offset: start + emoji.length,
              );
              _onTextChanged();
            },
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Reply banner – hiện preview tin nhắn đang reply + nút X cancel
  Widget _buildReplyBanner() {
    final reply = widget.replyingTo!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      decoration: BoxDecoration(
        color: AuraColors.primary.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: AuraColors.primary.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: AuraColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          // Reply content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '↩ Đang trả lời',
                  style: AuraTypography.labelSmall.copyWith(
                    color: AuraColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  reply.content.length > 50
                      ? '${reply.content.substring(0, 50)}...'
                      : reply.content,
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Cancel button
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: AuraColors.textTertiary,
            ),
            onPressed: widget.onCancelReply,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    ).animate().slideY(begin: -1, duration: 200.ms, curve: Curves.easeOut);
  }
}

/// Nút send gradient
class _SendButton extends StatelessWidget {
  const _SendButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AuraColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AuraColors.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 18,
        ),
      ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 200.ms,
            curve: Curves.elasticOut,
          ),
    );
  }
}

/// Nút action nhỏ (attach, emoji, mic)
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 22,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: size,
            color: AuraColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
