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
/// - Messages: grouped by date, scroll to bottom (RTDB stream)
/// - Input bar: text + emoji + attach + send
/// - Typing indicator (RTDB stream)
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Mark as read khi vào screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();

    // Clear typing khi rời screen
    _clearTyping();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _clearTyping();
    }
  }

  void _markAsRead() {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId.isEmpty) return;
    ref
        .read(conversationActionsProvider)
        .markAsRead(widget.conversationId, currentUserId);
  }

  void _clearTyping() {
    ref
        .read(typingActionProvider)
        .setTyping(widget.conversationId, false);
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
    final conversations = ref.read(conversationsProvider);
    ConversationModel? conversation;
    for (final item in conversations) {
      if (item.id == widget.conversationId) {
        conversation = item;
        break;
      }
    }

    if (conversation == null || conversation.participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dang tai cuoc tro chuyen, thu lai sau mot chut.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Gửi message qua ChatService
    ref.read(sendMessageProvider).send(
          conversationId: widget.conversationId,
          content: text,
          participants: conversation.participants,
        );

    // Clear typing status
    _clearTyping();

    // Scroll to bottom sau khi message được thêm
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleTypingChanged(bool isTyping) {
    ref
        .read(typingActionProvider)
        .setTyping(widget.conversationId, isTyping);
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final conversations = ref.watch(conversationsProvider);

    // Auto-scroll khi có message mới
    if (messages.length > _previousMessageCount && _previousMessageCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    _previousMessageCount = messages.length;

    // Tìm conversation hiện tại
    final conversation = conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => ConversationModel(
        id: widget.conversationId,
        participants: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final peerId = conversation.participants.isNotEmpty
        ? conversation.participants.firstWhere(
            (p) => p != currentUserId,
            orElse: () => '',
          )
        : '';

    // Watch typing status từ RTDB stream
    final typingStatus =
        ref.watch(typingStatusProvider(widget.conversationId));
    final showTyping = typingStatus.isTyping;

    // Watch loading state
    final isLoading = ref.watch(
      chatMessagesStreamProvider(widget.conversationId)
          .select((v) => v.isLoading),
    );

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: _buildAppBar(context, conversation, peerId),
      body: Column(
        children: [
          // ── Messages ──
          Expanded(
            child: isLoading && messages.isEmpty
                ? _buildLoadingState()
                : messages.isEmpty
                    ? _buildEmptyChat(conversation.peerName ?? 'User')
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        itemCount: messages.length + (showTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Typing indicator ở cuối
                          if (showTyping && index == messages.length) {
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
                                    delay: Duration(
                                        milliseconds:
                                            (index * 30).clamp(0, 300)),
                                  ),
                            ],
                          );
                        },
                      ),
          ),

          // ── Input ──
          ChatInput(
            onSend: _handleSend,
            onTypingChanged: _handleTypingChanged,
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
    final presence = peerId.isNotEmpty
        ? ref.watch(userPresenceProvider(peerId))
        : const UserPresence();

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

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AuraColors.primary,
        strokeWidth: 2,
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
