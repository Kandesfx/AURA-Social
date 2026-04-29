import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/post_card.dart';

/// AURA Social – Feed Screen
///
/// Màn hình chính với 2 tab: For You (AI-curated) và Following (chronological).
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 60,
            title: Row(
              children: [
                // Logo / Brand
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AuraColors.primaryGradient.createShader(bounds),
                      child: Text(
                        'AURA',
                        style: AuraTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // AI Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AuraColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AuraColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AuraColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '🧠 AI Active',
                        style: AuraTypography.labelSmall.copyWith(
                          color: AuraColors.primary,
                        ),
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .shimmer(duration: 3000.ms, color: AuraColors.primary.withValues(alpha: 0.3)),

                const SizedBox(width: 8),
                // Notifications
                IconButton(
                  icon: const Badge(
                    smallSize: 8,
                    backgroundColor: AuraColors.error,
                    child: Icon(Icons.notifications_outlined, size: 24),
                  ),
                  onPressed: () => context.push('/notifications'),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'For You'),
                  Tab(text: 'Following'),
                ],
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ForYouTab(),
            _FollowingTab(),
          ],
        ),
      ),
    );
  }
}

/// Tab For You – AI curated feed
class _ForYouTab extends StatelessWidget {
  // Mock data cho demo
  final List<Map<String, dynamic>> _mockPosts = [
    {
      'id': '1',
      'userName': 'Minh Anh',
      'userHandle': '@minhanh',
      'timeAgo': '2h',
      'content': 'Hôm nay tôi cảm thấy thật tuyệt vời khi được nhìn thấy hoàng hôn trên biển. Có ai cũng thích ngắm hoàng hôn không? 🌅',
      'hasImage': true,
      'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      'emotionVector': {'joy': 0.45, 'trust': 0.2, 'anticipation': 0.15, 'surprise': 0.1, 'sadness': 0.05, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02},
      'reactions': {'joy': 24, 'trust': 8, 'anticipation': 5, 'surprise': 3, 'sadness': 0, 'fear': 0, 'anger': 0, 'disgust': 0},
      'commentCount': 12,
    },
    {
      'id': '2',
      'userName': 'Hoàng Dũng',
      'userHandle': '@hoangdung',
      'timeAgo': '4h',
      'content': 'Just shipped a new feature at work! The feeling when your code compiles without errors on the first try 🚀\n\n#coding #developer #happyday',
      'hasImage': false,
      'emotionVector': {'joy': 0.35, 'anticipation': 0.3, 'trust': 0.15, 'surprise': 0.1, 'sadness': 0.03, 'fear': 0.02, 'anger': 0.03, 'disgust': 0.02},
      'reactions': {'joy': 42, 'anticipation': 15, 'trust': 7, 'surprise': 12, 'sadness': 0, 'fear': 0, 'anger': 0, 'disgust': 0},
      'commentCount': 23,
    },
    {
      'id': '3',
      'userName': 'Thu Hà',
      'userHandle': '@thuha_dreamer',
      'timeAgo': '6h',
      'content': 'Nghe playlist lofi chill cả buổi chiều, thời tiết mát mát là lý do hoàn hảo để pha một ly cà phê nóng và đọc sách 📖☕',
      'hasImage': true,
      'imageUrl': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600',
      'emotionVector': {'trust': 0.3, 'joy': 0.25, 'anticipation': 0.15, 'surprise': 0.05, 'sadness': 0.1, 'fear': 0.05, 'anger': 0.05, 'disgust': 0.05},
      'reactions': {'trust': 18, 'joy': 14, 'anticipation': 3, 'surprise': 1, 'sadness': 2, 'fear': 0, 'anger': 0, 'disgust': 0},
      'commentCount': 8,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _mockPosts.length,
      itemBuilder: (context, index) {
        return PostCard(post: _mockPosts[index])
            .animate()
            .fadeIn(duration: 400.ms, delay: (index * 100).ms)
            .slideY(begin: 0.05, duration: 400.ms, delay: (index * 100).ms);
      },
    );
  }
}

/// Tab Following – Chronological feed
class _FollowingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: AuraColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Following Feed',
            style: AuraTypography.headlineSmall.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posts từ những người bạn follow\nsẽ hiển thị ở đây',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
