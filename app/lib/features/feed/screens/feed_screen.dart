import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/feed_service.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

/// AURA Social – Feed Screen
///
/// Màn hình chính với 2 tab: For You (AI-curated) và Following (chronological).
/// Enhanced by Person 4, Task #19: pull-to-refresh, infinite scroll, shimmer loading.
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
                        decoration: BoxDecoration(
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
                  icon: Badge(
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
          children: const [
            _ForYouTab(),
            _FollowingTab(),
          ],
        ),
      ),
    );
  }
}

/// Tab For You – AI curated feed
/// Enhanced: shimmer loading → pull-to-refresh → infinite scroll
class _ForYouTab extends ConsumerStatefulWidget {
  const _ForYouTab();

  @override
  ConsumerState<_ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends ConsumerState<_ForYouTab> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Infinite scroll: load more khi gần cuối list
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// Load lần đầu
  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _posts.clear();
    });

    final feedService = ref.read(feedServiceProvider);
    final result = await feedService.getForYouFeed(page: 0);

    if (mounted) {
      setState(() {
        _posts.addAll(result.posts);
        _hasMore = result.hasMore;
        _isLoading = false;
        _currentPage = 1;
      });
    }
  }

  /// Load thêm (infinite scroll)
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final feedService = ref.read(feedServiceProvider);
    final result = await feedService.getForYouFeed(page: _currentPage);

    if (mounted) {
      setState(() {
        _posts.addAll(result.posts);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
        _currentPage++;
      });
    }
  }

  /// Pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    // ── Shimmer loading state ──
    if (_isLoading) {
      return const ShimmerFeedLoading(itemCount: 3);
    }

    // ── Empty state ──
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.explore_outlined, size: 48,
                  color: AuraColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text('Chưa có bài viết',
                style: AuraTypography.headlineSmall
                    .copyWith(color: AuraColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Hãy follow ai đó để xem feed!',
                style: AuraTypography.bodyMedium
                    .copyWith(color: AuraColors.textTertiary)),
          ],
        ),
      );
    }

    // ── Feed list with pull-to-refresh + infinite scroll ──
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AuraColors.primary,
      backgroundColor: AuraColors.surface,
      displacement: 40,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // ── Loading more indicator at bottom ──
          if (index == _posts.length) {
            return _buildLoadMoreIndicator();
          }

          final delay = Duration(milliseconds: (index * 100).clamp(0, 500));
          return PostCard(
            post: PostModel.fromMockMap(_posts[index]),
            persistReactionChanges: false,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: delay)
              .slideY(begin: 0.05, duration: 400.ms, delay: delay);
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                        AuraColors.primary.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Đang tải thêm...',
                  style: AuraTypography.labelMedium
                      .copyWith(color: AuraColors.textTertiary),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Tab Following – Chronological feed
/// Enhanced: pull-to-refresh + shimmer loading
class _FollowingTab extends ConsumerStatefulWidget {
  const _FollowingTab();

  @override
  ConsumerState<_FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends ConsumerState<_FollowingTab> {
  final List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    final feedService = ref.read(feedServiceProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final result = await feedService.getFollowingFeed(myUid: myUid, page: 0);

    if (mounted) {
      setState(() {
        _posts.clear();
        _posts.addAll(result.posts);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ShimmerFeedLoading(itemCount: 2);
    }

    if (_posts.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: AuraColors.primary,
      backgroundColor: AuraColors.surface,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostCard(
            post: PostModel.fromMockMap(_posts[index]),
            persistReactionChanges: false,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (index * 100).ms)
              .slideY(begin: 0.05, duration: 400.ms, delay: (index * 100).ms);
        },
      ),
    );
  }
}
