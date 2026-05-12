import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/post_card.dart';
import '../models/post_model.dart';

/// AURA Social – Feed Screen
///
/// Tab "For You": hiển thị posts từ Firestore (tương lai: FastAPI AI feed)
/// Tab "Following": posts từ người đã follow (Firestore query)
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
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
            floating: true, snap: true, elevation: 0, toolbarHeight: 60,
            title: Row(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/logo_icon.png', width: 32, height: 32, fit: BoxFit.cover)),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) => AuraColors.primaryGradient.createShader(b),
                  child: Text('AURA', style: AuraTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AuraColors.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AuraColors.primary.withValues(alpha: .2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AuraColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('🧠 AI Active', style: AuraTypography.labelSmall.copyWith(color: AuraColors.primary)),
                ]),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3000.ms, color: AuraColors.primary.withValues(alpha: .3)),
              const SizedBox(width: 8),
              IconButton(icon: const Badge(smallSize: 8, backgroundColor: AuraColors.error, child: Icon(Icons.notifications_outlined, size: 24)), onPressed: () {}),
            ]),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(44),
              child: TabBar(controller: _tabController, tabs: const [Tab(text: 'For You'), Tab(text: 'Following')], padding: const EdgeInsets.symmetric(horizontal: 16))),
          ),
        ],
        body: TabBarView(controller: _tabController, children: [
          _ForYouTab(),
          _FollowingTab(),
        ]),
      ),
    );
  }
}

/// Tab For You – Posts mới nhất từ Firestore (tương lai: FastAPI AI curated)
class _ForYouTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts')
          .where('status', isEqualTo: 'active')
          .orderBy('created_at', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmer();
        if (snapshot.hasError) return _buildError(snapshot.error.toString());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmpty();

        final posts = docs.map((d) => PostModel.fromFirestore(d)).toList();

        return RefreshIndicator(
          color: AuraColors.primary,
          onRefresh: () async { /* Pull-to-refresh: tương lai gọi FastAPI */ },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: posts.length,
            itemBuilder: (context, i) => PostCard(post: posts[i])
                .animate().fadeIn(duration: 400.ms, delay: (i * 80).ms)
                .slideY(begin: .05, duration: 400.ms, delay: (i * 80).ms),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() => ListView.builder(
    padding: const EdgeInsets.all(16), itemCount: 3,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: AuraColors.surfaceVariant, highlightColor: AuraColors.surfaceHigh,
      child: Container(height: 200, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AuraColors.surface, borderRadius: BorderRadius.circular(16))),
    ),
  );

  Widget _buildError(String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 48, color: AuraColors.error),
    const SizedBox(height: 12),
    Text('Đã xảy ra lỗi', style: AuraTypography.titleMedium.copyWith(color: AuraColors.textPrimary)),
    const SizedBox(height: 4),
    Text(msg, style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary), textAlign: TextAlign.center),
  ]));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.explore_outlined, size: 64, color: AuraColors.textTertiary.withValues(alpha: .5)),
    const SizedBox(height: 16),
    Text('Chưa có bài viết nào', style: AuraTypography.headlineSmall.copyWith(color: AuraColors.textSecondary)),
    const SizedBox(height: 8),
    Text('Hãy tạo bài viết đầu tiên!', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary)),
  ]));
}

/// Tab Following – Posts từ người đã follow
class _FollowingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Vui lòng đăng nhập'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('following').snapshots(),
      builder: (context, followSnap) {
        if (followSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AuraColors.primary));
        }

        final followingIds = followSnap.data?.docs.map((d) => d.id).toList() ?? [];
        if (followingIds.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_outline_rounded, size: 64, color: AuraColors.textTertiary.withValues(alpha: .5)),
            const SizedBox(height: 16),
            Text('Chưa follow ai', style: AuraTypography.headlineSmall.copyWith(color: AuraColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Follow người khác để xem bài viết ở đây', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary), textAlign: TextAlign.center),
          ]));
        }

        // Firestore whereIn giới hạn 30 items → batch nếu cần
        final batch = followingIds.take(30).toList();
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts')
              .where('user_id', whereIn: batch)
              .where('status', isEqualTo: 'active')
              .orderBy('created_at', descending: true)
              .limit(30)
              .snapshots(),
          builder: (context, postSnap) {
            if (postSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AuraColors.primary));
            }
            final posts = postSnap.data?.docs.map((d) => PostModel.fromFirestore(d)).toList() ?? [];
            if (posts.isEmpty) {
              return Center(child: Text('Chưa có bài viết từ người bạn follow', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary)));
            }
            return RefreshIndicator(
              color: AuraColors.primary,
              onRefresh: () async {},
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: posts.length,
                itemBuilder: (context, i) => PostCard(post: posts[i]),
              ),
            );
          },
        );
      },
    );
  }
}
