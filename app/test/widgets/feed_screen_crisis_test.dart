import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/feed/screens/feed_screen.dart';
import 'package:app/features/wellbeing/widgets/crisis_resource_card.dart';
import 'package:app/providers/emotion_profile_provider.dart';
import 'package:app/shared/models/emotion_profile_model.dart';
import 'package:app/services/feed_service.dart';

class MockFeedService implements FeedService {
  @override
  Future<FeedResult> getForYouFeed({int page = 0, int limit = 20}) async {
    return FeedResult(
      posts: [
        {
          'id': '1',
          'userName': 'Mock User',
          'userHandle': '@mockuser',
          'timeAgo': '1m',
          'content': 'Hello, AURA!',
          'hasImage': false,
          'emotionVector': {'joy': 1.0},
          'reactions': {'joy': 1},
          'commentCount': 0,
        }
      ],
      hasMore: false,
      feedMeta: FeedMeta(
        emotionalMode: 'explore',
        diversityScore: 1.0,
        generatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<FeedResult> getFollowingFeed({required String myUid, int page = 0, int limit = 20}) async {
    return FeedResult(
      posts: [],
      hasMore: false,
      feedMeta: FeedMeta(
        emotionalMode: 'following',
        diversityScore: 0.0,
        generatedAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  group('FeedScreen CrisisResourceCard Integration Tests', () {
    late MockFeedService mockFeedService;

    setUp(() {
      mockFeedService = MockFeedService();
    });

    Widget createTestWidget({required Stream<EmotionProfileModel> emotionStream}) {
      return ProviderScope(
        overrides: [
          feedServiceProvider.overrideWithValue(mockFeedService),
          currentEmotionProfileProvider.overrideWith((ref) => emotionStream),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FeedScreen(),
          ),
        ),
      );
    }

    testWidgets('does not show CrisisResourceCard when valence is normal', (tester) async {
      final emotionStream = Stream.value(
        const EmotionProfileModel(
          valence: 0.2,
          totalInferences: 1,
          currentEmotionVector: {'joy': 0.8, 'trust': 0.2},
        ),
      );

      await tester.pumpWidget(createTestWidget(emotionStream: emotionStream));
      await tester.pump(); // Start fetching
      await tester.pump(const Duration(milliseconds: 100)); // complete async build

      // CrisisResourceCard should not be present
      expect(find.byType(CrisisResourceCard), findsNothing);
      expect(find.text('Hello, AURA!'), findsOneWidget);
    });

    testWidgets('shows CrisisResourceCard at top of feed when valence is low (<= -0.5)', (tester) async {
      final emotionStream = Stream.value(
        const EmotionProfileModel(
          valence: -0.6,
          totalInferences: 1,
          currentEmotionVector: {'sadness': 0.8, 'fear': 0.2},
        ),
      );

      await tester.pumpWidget(createTestWidget(emotionStream: emotionStream));
      await tester.pump(); // Start fetching
      await tester.pump(const Duration(milliseconds: 100)); // complete async build

      // CrisisResourceCard should be present at the top
      expect(find.byType(CrisisResourceCard), findsOneWidget);
      expect(find.text('Chúng mình luôn ở đây vì bạn'), findsOneWidget);
      expect(find.text('Hello, AURA!'), findsOneWidget);
    });

    testWidgets('dismisses CrisisResourceCard when "Để sau" is tapped', (tester) async {
      final emotionStream = Stream.value(
        const EmotionProfileModel(
          valence: -0.6,
          totalInferences: 1,
          currentEmotionVector: {'sadness': 0.8, 'fear': 0.2},
        ),
      );

      await tester.pumpWidget(createTestWidget(emotionStream: emotionStream));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CrisisResourceCard), findsOneWidget);

      // Tap the dismiss button
      await tester.tap(find.text('Để sau'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // CrisisResourceCard should disappear
      expect(find.byType(CrisisResourceCard), findsNothing);
      expect(find.text('Hello, AURA!'), findsOneWidget);
    });
  });
}
