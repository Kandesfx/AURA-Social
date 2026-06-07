import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../services/chat_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/call_model.dart';
import '../../../services/call_service.dart';
import '../providers/chat_provider.dart';
import '../providers/presence_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_actions_sheet.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input.dart';
import '../../../providers/api_service_provider.dart';
import '../../../providers/emotion_profile_provider.dart';

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
  final _chatController = TextEditingController();
  List<String> _replySuggestions = [];
  bool _loadingSuggestions = false;
  int _previousMessageCount = 0;
  MessageModel? _replyingTo;

  bool _isSearching = false;
  String _chatSearchQuery = '';
  bool _isMuted = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Mark as read khi vào screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
      _loadMuteAndBlockStates();
    });
  }

  @override
  void deactivate() {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _chatController.dispose();

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

  String _getPeerId() {
    try {
      final conversations = ref.read(conversationsProvider);
      final currentUserId = ref.read(currentUserIdProvider);
      final conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
      return conversation.participants.firstWhere((p) => p != currentUserId, orElse: () => '');
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadMuteAndBlockStates() async {
    final prefs = await SharedPreferences.getInstance();
    final peerId = _getPeerId();
    if (mounted) {
      setState(() {
        _isMuted = prefs.getBool('muted_conversation_${widget.conversationId}') ?? false;
        _isBlocked = peerId.isNotEmpty ? (prefs.getBool('blocked_user_$peerId') ?? false) : false;
      });
    }
  }

  Future<void> _toggleMute() async {
    final prefs = await SharedPreferences.getInstance();
    final newMute = !_isMuted;
    await prefs.setBool('muted_conversation_${widget.conversationId}', newMute);
    setState(() => _isMuted = newMute);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newMute ? 'Đã tắt thông báo cuộc trò chuyện này' : 'Đã bật thông báo cuộc trò chuyện này'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _toggleBlock() async {
    final peerId = _getPeerId();
    if (peerId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isBlocked ? 'Bỏ chặn người dùng?' : 'Chặn người dùng?',
          style: AuraTypography.titleMedium.copyWith(
            color: AuraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          _isBlocked
              ? 'Bạn sẽ có thể nhận tin nhắn và tương tác lại với người dùng này.'
              : 'Bạn sẽ không nhận được tin nhắn hay cuộc gọi từ người dùng này nữa.',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AuraColors.textTertiary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _isBlocked ? AuraColors.primary : AuraColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isBlocked ? 'Bỏ chặn' : 'Chặn',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final newBlock = !_isBlocked;
      await prefs.setBool('blocked_user_$peerId', newBlock);
      setState(() => _isBlocked = newBlock);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newBlock ? 'Đã chặn người dùng' : 'Đã bỏ chặn người dùng'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
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

  ConversationModel? _findConversation() {
    final conversations = ref.read(conversationsProvider);
    for (final item in conversations) {
      if (item.id == widget.conversationId) return item;
    }
    return null;
  }

  void _handleSend(String text) {
    final conversation = _findConversation();
    if (conversation == null || conversation.participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải cuộc trò chuyện, thử lại sau.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final chatService = ref.read(chatServiceProvider);

    if (_replyingTo != null) {
      // Gửi kèm reply info
      final currentUserId = ref.read(currentUserIdProvider);
      chatService.sendMessageWithReply(
        conversationId: widget.conversationId,
        content: text,
        replyTo: ReplyInfo(
          messageId: _replyingTo!.id,
          senderId: _replyingTo!.senderId,
          senderName: _replyingTo!.isMine(currentUserId) ? 'Bạn' : (conversation.peerName ?? 'User'),
          content: _replyingTo!.content,
        ),
        participants: conversation.participants,
      );
      setState(() => _replyingTo = null);
    } else {
      // Gửi bình thường
      ref.read(sendMessageProvider).send(
            conversationId: widget.conversationId,
            content: text,
            participants: conversation.participants,
          );
    }

    _clearTyping();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleTypingChanged(bool isTyping) {
    ref.read(typingActionProvider).setTyping(widget.conversationId, isTyping);
  }

  // ── Message Actions ──

  void _showMessageActions(MessageModel message) {
    final currentUserId = ref.read(currentUserIdProvider);
    final isMine = message.isMine(currentUserId);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MessageActionsSheet(
        message: message,
        isMine: isMine,
        currentUserId: currentUserId,
        onReaction: (emotion) => _handleReaction(message.id, emotion),
        onReply: () => _handleReply(message),
        onCopy: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã sao chép tin nhắn'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        },
        onDelete: isMine ? () => _handleDelete(message) : null,
      ),
    );
  }

  void _handleReply(MessageModel message) {
    setState(() => _replyingTo = message);
  }

  void _handleReaction(String messageId, String emotion) {
    ref.read(chatServiceProvider).toggleReaction(
      conversationId: widget.conversationId,
      messageId: messageId,
      emotion: emotion,
    );
  }

  void _handleDelete(MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xóa tin nhắn?',
          style: AuraTypography.titleMedium.copyWith(color: AuraColors.textPrimary),
        ),
        content: Text(
          'Tin nhắn này sẽ bị xóa vĩnh viễn.',
          style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: AuraColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatServiceProvider).deleteMessage(
                conversationId: widget.conversationId,
                messageId: message.id,
              );
            },
            child: Text('Xóa', style: TextStyle(color: AuraColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImagePick() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    final conversation = _findConversation();
    if (conversation == null) return;

    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Đang gửi ảnh...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(days: 1),
      ),
    );

    try {
      final bytes = await image.readAsBytes();
      final chatService = ref.read(chatServiceProvider);
      
      final downloadUrl = await chatService.uploadChatMedia(
        widget.conversationId,
        '${DateTime.now().millisecondsSinceEpoch}_${image.name}',
        bytes,
      );

      await chatService.sendImageMessage(
        conversationId: widget.conversationId,
        mediaUrl: downloadUrl,
        participants: conversation.participants,
        replyTo: _replyingTo != null
            ? ReplyInfo(
                messageId: _replyingTo!.id,
                senderId: _replyingTo!.senderId,
                senderName: _replyingTo!.isMine(ref.read(currentUserIdProvider))
                    ? 'Bạn'
                    : (conversation.peerName ?? 'User'),
                content: _replyingTo!.content,
              )
            : null,
      );

      if (mounted) {
        setState(() => _replyingTo = null);
      }
      scaffoldMessenger.clearSnackBars();
    } catch (e) {
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi ảnh: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AuraColors.error,
        ),
      );
    }
  }

  Future<void> _handleVoiceSend(Uint8List audioBytes) async {
    final conversation = _findConversation();
    if (conversation == null) return;

    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Đang gửi tin nhắn thoại...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(days: 1),
      ),
    );

    try {
      final chatService = ref.read(chatServiceProvider);
      
      final downloadUrl = await chatService.uploadChatMedia(
        widget.conversationId,
        '${DateTime.now().millisecondsSinceEpoch}_voice.webm',
        audioBytes,
      );

      await chatService.sendAudioMessage(
        conversationId: widget.conversationId,
        mediaUrl: downloadUrl,
        participants: conversation.participants,
        replyTo: _replyingTo != null
            ? ReplyInfo(
                messageId: _replyingTo!.id,
                senderId: _replyingTo!.senderId,
                senderName: _replyingTo!.isMine(ref.read(currentUserIdProvider))
                    ? 'Bạn'
                    : (conversation.peerName ?? 'User'),
                content: _replyingTo!.content,
              )
            : null,
      );

      if (mounted) {
        setState(() => _replyingTo = null);
      }
      scaffoldMessenger.clearSnackBars();
    } catch (e) {
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi tin nhắn thoại: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AuraColors.error,
        ),
      );
    }
  }

  Future<void> _startCall(CallType type) async {
    final conversation = _findConversation();
    if (conversation == null) return;
    
    final currentUserId = ref.read(currentUserIdProvider);
    final peerId = _getPeerId();
    if (peerId.isEmpty) return;

    final currentUserDisplayName = 'Tôi';
    
    try {
      final call = await ref.read(callServiceProvider).makeCall(
        callerId: currentUserId,
        callerName: currentUserDisplayName,
        receiverId: peerId,
        receiverName: conversation.peerName ?? 'User',
        receiverAvatar: conversation.peerAvatarUrl,
        type: type,
      );

      if (mounted) {
        context.push('/call/${call.id}?incoming=false');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thực hiện cuộc gọi: $e'),
            backgroundColor: AuraColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final conversations = ref.watch(conversationsProvider);

    final filteredMessages = _isSearching && _chatSearchQuery.isNotEmpty
        ? messages
            .where((m) => m.content
                .toLowerCase()
                .contains(_chatSearchQuery.toLowerCase()))
            .toList()
        : messages;

    // Auto-scroll khi có message mới + Đánh dấu đã đọc nếu đang xem cuộc trò chuyện + Fetch AI gợi ý phản hồi
    if (messages.length > _previousMessageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        if (messages.isNotEmpty && !messages.last.isMine(currentUserId)) {
          _markAsRead();
          _fetchReplySuggestions(messages.last.content);
        } else if (messages.isNotEmpty && messages.last.isMine(currentUserId)) {
          setState(() {
            _replySuggestions = [];
          });
        }
      });
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
                : filteredMessages.isEmpty
                    ? _isSearching
                        ? Center(
                            child: Text(
                              'Không tìm thấy tin nhắn phù hợp',
                              style: AuraTypography.bodyMedium.copyWith(
                                color: AuraColors.textTertiary,
                              ),
                            ),
                          )
                        : _buildEmptyChat(conversation.peerName ?? 'User')
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        itemCount: filteredMessages.length + (showTyping && !_isSearching ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Typing indicator ở cuối
                          if (showTyping && !_isSearching && index == filteredMessages.length) {
                            return TypingIndicator(
                              userName: conversation.peerName,
                              showName: false,
                            ).animate().fadeIn(duration: 200.ms);
                          }

                          final message = filteredMessages[index];
                          final isMine = message.isMine(currentUserId);

                          // Check nếu message tiếp theo cùng sender
                          final isLastInGroup = index == filteredMessages.length - 1 ||
                              filteredMessages[index + 1].senderId != message.senderId;

                          // Date separator
                          Widget? dateSeparator;
                          if (index == 0 ||
                              !_isSameDay(filteredMessages[index - 1].timestamp,
                                  message.timestamp)) {
                            dateSeparator = DateSeparator(
                              date: _formatDate(message.timestamp),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (dateSeparator != null) dateSeparator,
                              MessageBubble(
                                message: message,
                                isMine: isMine,
                                	isLastInGroup: isLastInGroup,
                                onLongPress: () => _showMessageActions(message),
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
          if (_isBlocked)
            Container(
              width: double.infinity,
              color: AuraColors.surfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bạn đã chặn người dùng này',
                      style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: _toggleBlock,
                      child: Text(
                        'Bỏ chặn',
                        style: AuraTypography.labelLarge.copyWith(color: AuraColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildSuggestionsRow(),
            ChatInput(
              onSend: _handleSend,
              onSendVoice: _handleVoiceSend,
              onTypingChanged: _handleTypingChanged,
              replyingTo: _replyingTo,
              onCancelReply: () => setState(() => _replyingTo = null),
              onAttach: _handleImagePick,
              onEmoji: () {},
              controller: _chatController,
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ConversationModel conversation,
    String peerId,
  ) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: AuraColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: TextField(
          autofocus: true,
          style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tìm nội dung tin nhắn...',
            hintStyle: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _chatSearchQuery = value;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => setState(() {
              if (_chatSearchQuery.isNotEmpty) {
                _chatSearchQuery = '';
              } else {
                _isSearching = false;
              }
            }),
          ),
          const SizedBox(width: 8),
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
          if (peerId.isNotEmpty) {
            context.push('/user/$peerId');
          }
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
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: AuraColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AuraColors.surfaceBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bắt đầu cuộc gọi',
                        style: AuraTypography.titleMedium.copyWith(
                          color: AuraColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AuraColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.call_rounded, color: AuraColors.primary),
                        ),
                        title: Text(
                          'Cuộc gọi thoại',
                          style: AuraTypography.titleSmall.copyWith(color: AuraColors.textPrimary),
                        ),
                        subtitle: Text(
                          'Gọi thoại chất lượng cao',
                          style: AuraTypography.labelSmall.copyWith(color: AuraColors.textTertiary),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _startCall(CallType.audio);
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AuraColors.tertiary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.videocam_rounded, color: AuraColors.tertiary),
                        ),
                        title: Text(
                          'Cuộc gọi video',
                          style: AuraTypography.titleSmall.copyWith(color: AuraColors.textPrimary),
                        ),
                        subtitle: Text(
                          'Gọi video với camera trước',
                          style: AuraTypography.labelSmall.copyWith(color: AuraColors.textTertiary),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _startCall(CallType.video);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 22),
          onPressed: () => _showChatOptions(context, peerId),
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

  void _showChatOptions(BuildContext context, String peerId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (innerContext) {
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
                  onTap: () {
                    Navigator.pop(innerContext);
                    if (peerId.isNotEmpty) {
                      context.push('/user/$peerId');
                    }
                  },
                ),
                _OptionTile(
                  icon: Icons.search_rounded,
                  label: 'Tìm trong cuộc trò chuyện',
                  onTap: () {
                    Navigator.pop(innerContext);
                    setState(() {
                      _isSearching = true;
                      _chatSearchQuery = '';
                    });
                  },
                ),
                _OptionTile(
                  icon: _isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  label: _isMuted ? 'Bật thông báo' : 'Tắt thông báo',
                  onTap: () {
                    Navigator.pop(innerContext);
                    _toggleMute();
                  },
                ),
                _OptionTile(
                  icon: Icons.block_rounded,
                  label: _isBlocked ? 'Bỏ chặn người dùng' : 'Chặn người dùng',
                  color: AuraColors.error,
                  onTap: () {
                    Navigator.pop(innerContext);
                    _toggleBlock();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchReplySuggestions(String lastMessageContent) async {
    if (lastMessageContent.isEmpty || _loadingSuggestions) return;
    
    setState(() {
      _loadingSuggestions = true;
    });

    try {
      final conversations = ref.read(conversationsProvider);
      final conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
      
      // Get partner mood from peer's emotion vector
      String partnerMood = 'explore';
      if (conversation.peerEmotionVector != null && conversation.peerEmotionVector!.isNotEmpty) {
        partnerMood = conversation.peerEmotionVector!.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
      
      // Get current user's mood from profile provider
      final userMood = ref.read(currentEmotionProfileProvider).value?.dominantEmotion ?? 'explore';

      final response = await ref.read(apiServiceProvider).post('/api/v1/prompts/suggest-replies', data: {
        'last_message': lastMessageContent,
        'partner_mood': partnerMood,
        'user_mood': userMood,
      });
      
      final list = List<String>.from(response.data['suggestions'] ?? []);
      if (mounted) {
        setState(() {
          _replySuggestions = list;
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting reply suggestions: $e');
      if (mounted) {
        setState(() {
          _replySuggestions = [];
          _loadingSuggestions = false;
        });
      }
    }
  }

  Widget _buildSuggestionsRow() {
    if (_replySuggestions.isEmpty && !_loadingSuggestions) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _loadingSuggestions
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _replySuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _replySuggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      suggestion,
                      style: AuraTypography.labelMedium.copyWith(
                        color: AuraColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: AuraColors.surface,
                    side: BorderSide(
                      color: AuraColors.primary.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () {
                      _chatController.text = suggestion;
                      _chatController.selection = TextSelection.fromPosition(
                        TextSelection.collapsed(offset: suggestion.length).base,
                      );
                    },
                  ),
                );
              },
            ),
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
