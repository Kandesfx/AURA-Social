import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/user_tile.dart';

/// AURA Social – Search Screen
///
/// Person 3, Task #18
/// Tìm kiếm user, bài post, waves.
/// - Debounced search input
/// - Tab: Users / Posts / Waves
/// - Trending users / suggested

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MOCK DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final _mockUsers = [
  _MockUser('Minh Anh', 'Just vibing ✨', 'joy', true,
    {'joy': 0.4, 'trust': 0.25, 'anticipation': 0.15, 'surprise': 0.1, 'sadness': 0.05, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02}),
  _MockUser('Hoàng Dũng', 'Code & coffee ☕', 'anticipation', true,
    {'anticipation': 0.35, 'joy': 0.3, 'trust': 0.15, 'surprise': 0.1, 'sadness': 0.03, 'fear': 0.02, 'anger': 0.03, 'disgust': 0.02}),
  _MockUser('Thu Hà', 'Dreamer 📚', 'trust', false,
    {'trust': 0.3, 'joy': 0.25, 'sadness': 0.15, 'anticipation': 0.1, 'surprise': 0.08, 'fear': 0.05, 'anger': 0.04, 'disgust': 0.03}),
  _MockUser('Khánh Linh', 'Sunset chaser 🌅', 'surprise', true,
    {'surprise': 0.3, 'joy': 0.25, 'anticipation': 0.2, 'trust': 0.1, 'sadness': 0.05, 'fear': 0.04, 'anger': 0.03, 'disgust': 0.03}),
  _MockUser('Tuấn Kiệt', 'Runner 🏃', 'anticipation', false,
    {'anticipation': 0.3, 'joy': 0.28, 'trust': 0.18, 'surprise': 0.08, 'sadness': 0.06, 'fear': 0.04, 'anger': 0.03, 'disgust': 0.03}),
  _MockUser('Lan Phương', 'Music lover 🎵', 'joy', true,
    {'joy': 0.35, 'trust': 0.2, 'anticipation': 0.15, 'surprise': 0.1, 'sadness': 0.08, 'fear': 0.05, 'anger': 0.04, 'disgust': 0.03}),
  _MockUser('Đức Minh', 'Sci-fi nerd 🌌', 'surprise', false,
    {'surprise': 0.25, 'joy': 0.25, 'anticipation': 0.2, 'trust': 0.15, 'sadness': 0.05, 'fear': 0.04, 'anger': 0.03, 'disgust': 0.03}),
  _MockUser('Hương Giang', 'Yoga & mindfulness 🧘', 'trust', false,
    {'trust': 0.35, 'joy': 0.2, 'sadness': 0.15, 'anticipation': 0.1, 'surprise': 0.08, 'fear': 0.05, 'anger': 0.04, 'disgust': 0.03}),
];

class _MockUser {
  final String name;
  final String bio;
  final String dominantEmotion;
  final bool isOnline;
  final Map<String, double> emotionVector;
  _MockUser(this.name, this.bio, this.dominantEmotion, this.isOnline, this.emotionVector);
}

/// Search Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<_MockUser>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return [];
  return _mockUsers
      .where((u) =>
          u.name.toLowerCase().contains(query) ||
          u.bio.toLowerCase().contains(query) ||
          u.dominantEmotion.toLowerCase().contains(query))
      .toList();
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
    final results = ref.watch(searchResultsProvider);

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
              prefixIcon: const Icon(
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
      body: query.isEmpty
          ? _buildSuggestions()
          : results.isEmpty
              ? _buildNoResults(query)
              : _buildResults(results),
    );
  }

  Widget _buildSuggestions() {
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

        ..._mockUsers.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          return UserSearchTile(
            displayName: user.name,
            bio: user.bio,
            emotionVector: user.emotionVector,
            dominantEmotion: user.dominantEmotion,
            isOnline: user.isOnline,
            onTap: () {
              // TODO: Navigate to user profile
            },
          ).animate(delay: Duration(milliseconds: 200 + index * 60))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05, duration: 300.ms);
        }),
      ],
    );
  }

  Widget _buildResults(List<_MockUser> results) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return UserSearchTile(
          displayName: user.name,
          bio: user.bio,
          emotionVector: user.emotionVector,
          dominantEmotion: user.dominantEmotion,
          isOnline: user.isOnline,
          onTap: () {
            // TODO: Navigate to user profile
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
