import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../models/conversation_model.dart';
import '../providers/chat_provider.dart';

/// AURA Social – Conversations List Screen
///
/// Danh sách cuộc hội thoại với:
/// - Search bar
/// - Online indicator + Aura Ring
/// - Unread badge
/// - Soul Connect badge
/// - Swipe-to-delete
/// - Pull-to-refresh
/// - Empty state
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final filtered = _filteredConversations(conversations);

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        title: ShaderMask(
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, size: 18),
            ),
            onPressed: () {
              // TODO: new conversation
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
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
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AuraColors.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
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
          ),

          // ── Conversations List ──
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AuraColors.primary,
                    backgroundColor: AuraColors.surface,
                    onRefresh: () async {
                      // TODO: fetch from backend
                      await Future.delayed(
                          const Duration(milliseconds: 800));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        return Dismissible(
                          key: ValueKey(conv.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            color: AuraColors.error.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AuraColors.error,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            // TODO: confirm dialog
                            return false;
                          },
                          child: _ConversationTile(
                            conversation: conv,
                            currentUserId: currentUserId,
                            onTap: () {
                              context.push('/chat/${conv.id}');
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
          // const SizedBox(height: 8),
          // Text(
          //   'Kết nối với mọi người qua Soul Connect\nđể bắt đầu trò chuyện!',
          //   style: AuraTypography.bodyMedium.copyWith(
          //     color: AuraColors.textTertiary,
          //   ),
          //   textAlign: TextAlign.center,
          // ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/soul'),
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text('Soul Connect'),
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
  const _OnlineFriendsBar({required this.conversations});

  final List<ConversationModel> conversations;

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
                    onTap: () => context.push('/chat/${conv.id}'),
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
  });

  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCountFor(currentUserId);
    final hasUnread = unread > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
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
