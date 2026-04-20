import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';

/// AURA Social – Conversations List Screen
class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({super.key});

  final List<Map<String, dynamic>> _mockConversations = const [
    {
      'name': 'Minh Anh',
      'lastMessage': 'Chào bạn! Mình thấy mình match cao ghê 😄',
      'time': '10:30',
      'unread': 2,
      'online': true,
    },
    {
      'name': 'Hoàng Dũng',
      'lastMessage': 'Bài post hôm nay hay quá!',
      'time': '09:15',
      'unread': 0,
      'online': true,
    },
    {
      'name': 'Thu Hà',
      'lastMessage': 'Cảm ơn bạn đã chia sẻ 💕',
      'time': 'Hôm qua',
      'unread': 0,
      'online': false,
    },
    {
      'name': 'Đức Anh',
      'lastMessage': 'Tối nay đi cafe không?',
      'time': 'Hôm qua',
      'unread': 1,
      'online': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _mockConversations.length,
        itemBuilder: (context, index) {
          final conv = _mockConversations[index];
          return _ConversationTile(
            name: conv['name'],
            lastMessage: conv['lastMessage'],
            time: conv['time'],
            unreadCount: conv['unread'],
            isOnline: conv['online'],
          ).animate()
            .fadeIn(duration: 300.ms, delay: (index * 80).ms)
            .slideX(begin: 0.03, duration: 300.ms, delay: (index * 80).ms);
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
  });

  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                AuraRing(
                  size: 52,
                  animate: false,
                  glowIntensity: 0.2,
                ),
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
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
            const SizedBox(width: 12),

            // Name + Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AuraTypography.titleSmall.copyWith(
                      color: AuraColors.textPrimary,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage,
                    style: AuraTypography.bodySmall.copyWith(
                      color: unreadCount > 0
                          ? AuraColors.textSecondary
                          : AuraColors.textTertiary,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time + Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: AuraTypography.labelSmall.copyWith(
                    color: unreadCount > 0
                        ? AuraColors.primary
                        : AuraColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AuraColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
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
}
