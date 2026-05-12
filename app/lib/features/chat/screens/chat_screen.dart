import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../models/conversation_model.dart';
import '../providers/chat_provider.dart';
import '../providers/presence_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input.dart';

/// AURA Social – Chat Screen
///
/// Màn hình chat 1-1 real-time.
/// - AppBar: avatar + name + online status
/// - Messages: grouped by date, scroll to bottom
/// - Input bar: text + emoji + attach + send
/// - Typing indicator
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _showTyping = false;

  @override
  void initState() {
    super.initState();
    // Scroll to bottom sau khi build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
      // Mark as read
      ref
          .read(conversationsProvider.notifier)
          .markAsRead(widget.conversationId, ref.read(currentUserIdProvider));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _handleSend(String text) {
    final notifier =
        ref.read(chatMessagesProvider(widget.conversationId).notifier);
    notifier.sendMessage(text);

    // Update conversation last message
    ref.read(conversationsProvider.notifier).updateLastMessage(
          widget.conversationId,
          LastMessage(
            content: text,
            senderId: ref.read(currentUserIdProvider),
            timestamp: DateTime.now(),
          ),
        );

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Simulate typing response sau 1.5s
    _simulateTypingResponse();
  }

  void _simulateTypingResponse() {
    // Show typing sau 1s
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _showTyping = true);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    // Hide typing và "nhận" tin nhắn sau 3s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _showTyping = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final conversations = ref.watch(conversationsProvider);

    // Tìm conversation hiện tại
    final conversation = conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => conversations.first,
    );

    final peerId = conversation.participants.firstWhere(
      (p) => p != currentUserId,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: _buildAppBar(context, conversation, peerId),
      body: Column(
        children: [
          // ── Messages ──
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyChat(conversation.peerName ?? 'User')
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    itemCount: messages.length + (_showTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Typing indicator ở cuối
                      if (_showTyping && index == messages.length) {
                        return TypingIndicator(
                          userName: conversation.peerName,
                          showName: false,
                        ).animate().fadeIn(duration: 200.ms);
                      }

                      final message = messages[index];
                      final isMine = message.isMine(currentUserId);

                      // Check nếu message tiếp theo cùng sender
                      final isLastInGroup = index == messages.length - 1 ||
                          messages[index + 1].senderId != message.senderId;

                      // Date separator
                      Widget? dateSeparator;
                      if (index == 0 ||
                          !_isSameDay(messages[index - 1].timestamp,
                              message.timestamp)) {
                        dateSeparator = DateSeparator(
                          date: _formatDate(message.timestamp),
                        );
                      }

                      return Column(
                        children: [
                          ?dateSeparator,
                          MessageBubble(
                            message: message,
                            isMine: isMine,
                            isLastInGroup: isLastInGroup,
                          ).animate().fadeIn(
                                duration: 250.ms,
                                delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
                              ),
                        ],
                      );
                    },
                  ),
          ),

          // ── Input ──
          ChatInput(
            onSend: _handleSend,
            onAttach: () {
              // TODO: image picker
            },
            onEmoji: () {
              // TODO: emoji picker
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ConversationModel conversation,
    String peerId,
  ) {
    final presence = ref.watch(userPresenceProvider(peerId));

    return AppBar(
      backgroundColor: AuraColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          // TODO: navigate to user profile
        },
        child: Row(
          children: [
            // Avatar with Aura Ring
            Stack(
              children: [
                AuraRing(
                  size: 40,
                  emotionVector: conversation.peerEmotionVector,
                  animate: false,
                  glowIntensity: 0.2,
                ),
                if (presence.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AuraColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AuraColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Name + Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.peerName ?? 'User',
                    style: AuraTypography.titleSmall.copyWith(
                      color: AuraColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    presence.isOnline
                        ? 'Đang hoạt động'
                        : formatLastSeen(presence.lastSeen),
                    style: AuraTypography.labelSmall.copyWith(
                      color: presence.isOnline
                          ? AuraColors.success
                          : AuraColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, size: 22),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 22),
          onPressed: () => _showChatOptions(context),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: AuraColors.surfaceBorder,
        ),
      ),
    );
  }

  Widget _buildEmptyChat(String peerName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AuraColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              size: 36,
              color: AuraColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu trò chuyện',
            style: AuraTypography.headlineSmall.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gửi lời chào đến $peerName!',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textTertiary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 500.ms),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AuraColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _OptionTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Xem profile',
                  onTap: () => Navigator.pop(context),
                ),
                _OptionTile(
                  icon: Icons.search_rounded,
                  label: 'Tìm trong cuộc trò chuyện',
                  onTap: () => Navigator.pop(context),
                ),
                _OptionTile(
                  icon: Icons.notifications_off_outlined,
                  label: 'Tắt thông báo',
                  onTap: () => Navigator.pop(context),
                ),
                _OptionTile(
                  icon: Icons.block_rounded,
                  label: 'Chặn người dùng',
                  color: AuraColors.error,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hôm nay';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Hôm qua';

    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Option tile cho bottom sheet
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AuraColors.textSecondary, size: 22),
      title: Text(
        label,
        style: AuraTypography.bodyLarge.copyWith(
          color: color ?? AuraColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
