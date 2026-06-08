import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/user_model.dart';
import '../widgets/user_tile.dart';
import '../../../shared/widgets/shimmer_loading.dart';

/// AURA Social – Search Screen
///
/// Person 3, Task #18
/// Tìm kiếm user, bài post, waves.
/// - Debounced search input
/// - Tab: Users / Posts / Waves
/// - Trending users / suggested

/// Search Provider
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchableUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final currentUid = FirebaseAuth.instance.currentUser?.uid;

  return FirebaseFirestore.instance
      .collection('users')
      .limit(50)
      .snapshots()
      .map((snapshot) {
    final users = snapshot.docs
        .where((doc) => doc.id != currentUid)
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    users.sort((a, b) => a.displayName.compareTo(b.displayName));
    return users;
  });
});

/// Search Screen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = '';
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final usersAsync = ref.watch(searchableUsersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AuraColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AuraColors.surfaceBorder,
              width: 0.5,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm người dùng, cảm xúc...',
              hintStyle: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: AuraColors.textTertiary,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
        ),
      ),
      body: usersAsync.when(
        loading: () => const ShimmerChatList(),
        error: (error, _) => _buildLoadError(error),
        data: (users) {
          final results = query.isEmpty
              ? <UserModel>[]
              : users.where((u) {
                  final q = query.toLowerCase();
                  return u.displayName.toLowerCase().contains(q) ||
                      u.username.toLowerCase().contains(q) ||
                      (u.bio ?? '').toLowerCase().contains(q) ||
                      u.auraDominantEmotion.toLowerCase().contains(q);
                }).toList();

          return query.isEmpty
              ? _buildSuggestions(users)
              : results.isEmpty
                  ? _buildNoResults(query)
                  : _buildResults(results);
        },
      ),
    );
  }

  Widget _buildLoadError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Không thể tải dữ liệu tìm kiếm',
              style: AuraTypography.titleMedium.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng kiểm tra lại kết nối mạng và thử lại.',
              textAlign: TextAlign.center,
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(List<UserModel> users) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // ── Suggested ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Gợi ý cho bạn',
            style: AuraTypography.titleSmall.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
        ),

        // Emotion filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EmotionChip('😊 Joy', 'joy'),
              _EmotionChip('🤝 Trust', 'trust'),
              _EmotionChip('🔥 Hype', 'anticipation'),
              _EmotionChip('✨ Wow', 'surprise'),
              _EmotionChip('💙 Calm', 'sadness'),
            ].map((chip) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = chip.emotion;
                  ref.read(searchQueryProvider.notifier).state = chip.emotion;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AuraColors.getEmotionColor(chip.emotion)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AuraColors.getEmotionColor(chip.emotion)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    chip.label,
                    style: AuraTypography.labelMedium.copyWith(
                      color: AuraColors.getEmotionColor(chip.emotion),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 16),

        // Trending users
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Đang nổi bật',
                style: AuraTypography.titleSmall.copyWith(
                  color: AuraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        if (users.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Chua co nguoi dung khac de hien thi',
              textAlign: TextAlign.center,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          )
        else
          ...users.take(8).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          return UserSearchTile(
            displayName: user.displayName,
            bio: user.bio,
            avatarUrl: user.avatarUrl,
            emotionVector: {user.auraDominantEmotion: 0.7},
            dominantEmotion: user.auraDominantEmotion,
            isOnline: user.isOnline,
            onTap: () {
              context.push('/user/${user.uid}');
            },
          ).animate(delay: Duration(milliseconds: 200 + index * 60))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05, duration: 300.ms);
        }),
      ],
    );
  }

  Widget _buildResults(List<UserModel> results) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return UserSearchTile(
          displayName: user.displayName,
          bio: user.bio,
          avatarUrl: user.avatarUrl,
          emotionVector: {user.auraDominantEmotion: 0.7},
          dominantEmotion: user.auraDominantEmotion,
          isOnline: user.isOnline,
          onTap: () {
            context.push('/user/${user.uid}');
          },
        ).animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 250.ms);
      },
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AuraColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: AuraTypography.headlineSmall.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Không tìm thấy "$query".\nThử tìm với từ khóa khác.',
            textAlign: TextAlign.center,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textTertiary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

class _EmotionChip {
  final String label;
  final String emotion;
  _EmotionChip(this.label, this.emotion);
}
