import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../models/conversation_model.dart';
import '../providers/chat_provider.dart';
import '../../../services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/shimmer_loading.dart';

/// AURA Social – Conversations List Screen
///
/// Danh sách cuộc hội thoại với:
/// - Search bar
/// - Online indicator + Aura Ring
/// - Unread badge
/// - Soul Connect badge
/// - Swipe-to-delete
/// - Pull-to-refresh
/// - Loading/Error/Empty states
class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isEditing = false;
  final Set<String> _selectedConversationIds = {};
  final Set<String> _mutedConversationIds = {};

  @override
  void initState() {
    super.initState();
    _loadMutedConversations();
  }

  Future<void> _loadMutedConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final tempSet = <String>{};
    for (final key in keys) {
      if (key.startsWith('muted_conversation_') && prefs.getBool(key) == true) {
        final convId = key.substring('muted_conversation_'.length);
        tempSet.add(convId);
      }
    }
    if (mounted) {
      setState(() {
        _mutedConversationIds.clear();
        _mutedConversationIds.addAll(tempSet);
      });
    }
  }

  Future<void> _toggleMuteConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final isMuted = prefs.getBool('muted_conversation_$conversationId') ?? false;
    final newMute = !isMuted;
    await prefs.setBool('muted_conversation_$conversationId', newMute);
    if (mounted) {
      setState(() {
        if (newMute) {
          _mutedConversationIds.add(conversationId);
        } else {
          _mutedConversationIds.remove(conversationId);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteConversation(ConversationModel conv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xóa cuộc trò chuyện?',
          style: AuraTypography.titleMedium.copyWith(
            color: AuraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa cuộc trò chuyện với ${conv.peerName ?? 'User'} không? Hành động này sẽ xóa vĩnh viễn toàn bộ tin nhắn.',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Hủy',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AuraColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: AuraTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref
            .read(conversationActionsProvider)
            .deleteConversation(conv.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Đã xóa cuộc trò chuyện với ${conv.peerName ?? 'User'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa cuộc trò chuyện: $e'),
            backgroundColor: AuraColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversationIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xóa ${_selectedConversationIds.length} cuộc trò chuyện?',
          style: AuraTypography.titleMedium.copyWith(
            color: AuraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa tất cả các cuộc trò chuyện đã chọn không? Hành động này sẽ xóa vĩnh viễn toàn bộ tin nhắn.',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Hủy',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AuraColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: AuraTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final messenger = ScaffoldMessenger.of(context);
      final count = _selectedConversationIds.length;
      try {
        final actions = ref.read(conversationActionsProvider);
        for (final id in _selectedConversationIds) {
          await actions.deleteConversation(id);
        }
        setState(() {
          _selectedConversationIds.clear();
          _isEditing = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Đã xóa $count cuộc trò chuyện'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa cuộc trò chuyện: $e'),
            backgroundColor: AuraColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<ConversationModel> _filteredConversations(
      List<ConversationModel> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    return conversations
        .where((c) =>
            (c.peerName ?? '').toLowerCase().contains(_searchQuery) ||
            (c.lastMessage?.content ?? '').toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _showConversationActions(BuildContext context, ConversationModel conv) {
    final isMuted = _mutedConversationIds.contains(conv.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  conv.peerName ?? 'Tùy chọn cuộc trò chuyện',
                  style: AuraTypography.titleMedium.copyWith(
                    color: AuraColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              // Mark as read
              ListTile(
                leading: Icon(Icons.mark_chat_read_rounded, color: AuraColors.primary),
                title: Text(
                  'Đánh dấu đã đọc',
                  style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final currentUserId = ref.read(currentUserIdProvider);
                  try {
                    await ref.read(chatServiceProvider).resetUnreadCount(conv.id, currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đánh dấu đã đọc'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: AuraColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              // Mute notifications
              ListTile(
                leading: Icon(
                  isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: isMuted ? Colors.green : Colors.orange,
                ),
                title: Text(
                  isMuted ? 'Bật thông báo' : 'Tắt thông báo',
                  style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleMuteConversation(conv.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isMuted ? 'Đã bật nhận thông báo' : 'Đã tắt nhận thông báo'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              // Delete conversation
              ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: AuraColors.error),
                title: Text(
                  'Xóa cuộc trò chuyện',
                  style: AuraTypography.bodyMedium.copyWith(color: AuraColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConversation(conv);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch async stream trực tiếp để có loading/error states
    final asyncConversations = ref.watch(conversationsStreamProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        title: _isEditing
            ? Text(
                _selectedConversationIds.isEmpty
                    ? 'Chọn đoạn chat'
                    : 'Đã chọn ${_selectedConversationIds.length}',
                style: AuraTypography.titleLarge.copyWith(
                  color: AuraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : ShaderMask(
                shaderCallback: (bounds) =>
                    AuraColors.primaryGradient.createShader(bounds),
                child: Text(
                  'Messages',
                  style: AuraTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        actions: [
          if (_isEditing && _selectedConversationIds.isNotEmpty)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AuraColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AuraColors.error,
                ),
              ),
              onPressed: _deleteSelectedConversations,
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isEditing
                    ? AuraColors.primary.withValues(alpha: 0.15)
                    : AuraColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                size: 18,
                color: AuraColors.primary,
              ),
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _selectedConversationIds.clear();
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: asyncConversations.when(
        // ── Loading State ──
        loading: () => const ShimmerChatList(),

        // ── Error State ──
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AuraColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Không thể tải tin nhắn',
                style: AuraTypography.titleMedium.copyWith(
                  color: AuraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đã xảy ra lỗi khi kết nối máy chủ. Vui lòng thử lại sau.',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(conversationsStreamProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Data State ──
        data: (conversations) {
          final filtered = _filteredConversations(conversations);

          return Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AuraColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AuraColors.surfaceBorder,
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    style: AuraTypography.bodyMedium.copyWith(
                      color: AuraColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tin nhắn...',
                      hintStyle: AuraTypography.bodyMedium.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AuraColors.textTertiary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AuraColors.textTertiary,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Online Friends Horizontal ──
              _OnlineFriendsBar(
                conversations: conversations
                    .where((c) => c.isPeerOnline)
                    .toList(),
                onReturn: _loadMutedConversations,
              ),

              // ── Conversations List ──
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AuraColors.primary,
                        backgroundColor: AuraColors.surface,
                        onRefresh: () async {
                          // Stream tự update, refresh chỉ để UX
                          // ignore: unused_result
                          ref.refresh(conversationsStreamProvider);
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        },
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.only(top: 4, bottom: 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final conv = filtered[index];
                            return Dismissible(
                              key: ValueKey(conv.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                color: AuraColors.error
                                    .withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: AuraColors.error,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      'Xóa cuộc trò chuyện?',
                                      style: AuraTypography.titleMedium.copyWith(
                                        color: AuraColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    content: Text(
                                      'Bạn có chắc chắn muốn xóa cuộc trò chuyện với ${conv.peerName ?? 'User'} không? Hành động này sẽ xóa vĩnh viễn toàn bộ tin nhắn.',
                                      style: AuraTypography.bodyMedium.copyWith(
                                        color: AuraColors.textSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(
                                          'Hủy',
                                          style: AuraTypography.labelLarge.copyWith(
                                            color: AuraColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AuraColors.error,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Xóa',
                                          style: AuraTypography.labelLarge.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return confirm ?? false;
                              },
                              onDismissed: (_) async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await ref
                                      .read(conversationActionsProvider)
                                      .deleteConversation(conv.id);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Đã xóa cuộc trò chuyện với ${conv.peerName ?? 'User'}'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi khi xóa cuộc trò chuyện: $e'),
                                      backgroundColor: AuraColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: _ConversationTile(
                                conversation: conv,
                                currentUserId: currentUserId,
                                isEditing: _isEditing,
                                isSelected: _selectedConversationIds.contains(conv.id),
                                isMuted: _mutedConversationIds.contains(conv.id),
                                onTap: () {
                                  if (_isEditing) {
                                    setState(() {
                                      if (_selectedConversationIds.contains(conv.id)) {
                                        _selectedConversationIds.remove(conv.id);
                                      } else {
                                        _selectedConversationIds.add(conv.id);
                                      }
                                    });
                                  } else {
                                    context.push('/chat/${conv.id}').then((_) {
                                      _loadMutedConversations();
                                    });
                                  }
                                },
                                onLongPress: () {
                                  if (!_isEditing) {
                                    _showConversationActions(context, conv);
                                  }
                                },
                              ).animate().fadeIn(
                                    duration: 300.ms,
                                    delay: (index * 60).ms,
                                  ).slideX(
                                    begin: 0.03,
                                    duration: 300.ms,
                                    delay: (index * 60).ms,
                                  ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AuraColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: AuraTypography.titleMedium.copyWith(
                color: AuraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

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
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: AuraColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn',
            style: AuraTypography.headlineSmall.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Tim nguoi dung'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 500.ms),
    );
  }
}

/// Online friends horizontal scroll bar
class _OnlineFriendsBar extends StatelessWidget {
  const _OnlineFriendsBar({required this.conversations, this.onReturn});

  final List<ConversationModel> conversations;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Đang hoạt động',
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => context.push('/chat/${conv.id}').then((_) {
                      onReturn?.call();
                    }),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            AuraRing(
                              size: 48,
                              emotionVector: conv.peerEmotionVector,
                              animate: true,
                              glowIntensity: 0.3,
                            ),
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
                        const SizedBox(height: 4),
                        Text(
                          (conv.peerName ?? 'User').split(' ').last,
                          style: AuraTypography.labelSmall.copyWith(
                            color: AuraColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                      duration: 300.ms,
                      delay: (index * 100).ms,
                    ).slideX(
                      begin: 0.1,
                      duration: 300.ms,
                      delay: (index * 100).ms,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 1 conversation tile
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
    this.isEditing = false,
    this.isSelected = false,
    this.isMuted = false,
  });

  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isEditing;
  final bool isSelected;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCountFor(currentUserId);
    final hasUnread = unread > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (isEditing) ...[
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AuraColors.primary : AuraColors.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 12),
            ],
            // ── Avatar with Aura Ring + Online Dot ──
            Stack(
              children: [
                AuraRing(
                  size: 56,
                  emotionVector: conversation.peerEmotionVector,
                  animate: false,
                  glowIntensity: hasUnread ? 0.3 : 0.15,
                ),
                if (conversation.isPeerOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AuraColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AuraColors.background,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Name + Last Message ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.peerName ?? 'User',
                          style: AuraTypography.titleSmall.copyWith(
                            color: AuraColors.textPrimary,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Soul Connect badge
                      if (conversation.type == ConversationType.soulConnect)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AuraColors.primary.withValues(alpha: 0.2),
                                AuraColors.tertiary.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '💜 Soul',
                            style: AuraTypography.labelSmall.copyWith(
                              color: AuraColors.primaryLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage?.content ?? '',
                    style: AuraTypography.bodySmall.copyWith(
                      color: hasUnread
                          ? AuraColors.textSecondary
                          : AuraColors.textTertiary,
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Time + Unread Badge ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMuted) ...[
                      Icon(
                        Icons.notifications_off_rounded,
                        color: AuraColors.textTertiary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatTime(conversation.lastMessage?.timestamp),
                      style: AuraTypography.labelSmall.copyWith(
                        color: hasUnread
                            ? AuraColors.primary
                            : AuraColors.textTertiary,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: AuraColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Bây giờ';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${time.day}/${time.month}';
  }
}
