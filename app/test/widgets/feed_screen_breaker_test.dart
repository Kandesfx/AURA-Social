import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/feed/screens/feed_screen.dart';
import 'package:app/features/wellbeing/widgets/break_card.dart';
import 'package:app/providers/emotion_profile_provider.dart';
import 'package:app/shared/models/emotion_profile_model.dart';
import 'package:app/services/feed_service.dart';

class MockBreakerFeedService implements FeedService {
  @override
  Future<FeedResult> getForYouFeed({int page = 0, int limit = 20}) async {
    return FeedResult(
      posts: [
        {
          'id': 'breaker_1',
          'userId': 'system_wellbeing',
          'userName': 'Wellbeing Guard',
          'userHandle': '@wellbeing',
          'timeAgo': '1m',
          'content': '✨ **Góc tươi sáng**: Hãy cùng nhìn vào điều tích cực.',
          'hasImage': false,
          'is_breaker': true,
          'breaker_type': 'positive_inject',
          'emotionVector': {'joy': 0.8},
          'reactions': {},
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
  group('FeedScreen WellbeingBreakCard Integration Tests', () {
    late MockBreakerFeedService mockFeedService;

    setUp(() {
      mockFeedService = MockBreakerFeedService();
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

    testWidgets('renders WellbeingBreakCard in feed when is_breaker is true', (tester) async {
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

      // WellbeingBreakCard should be present
      expect(find.byType(WellbeingBreakCard), findsOneWidget);
      // It should display the clean subtitle (prefix removed)
      expect(find.text('Hãy cùng nhìn vào điều tích cực.'), findsOneWidget);
      expect(find.text('Góc tươi sáng'), findsOneWidget);
    });

    testWidgets('dismisses WellbeingBreakCard when "Tiếp tục" is tapped', (tester) async {
      final emotionStream = Stream.value(
        const EmotionProfileModel(
          valence: 0.2,
          totalInferences: 1,
          currentEmotionVector: {'joy': 0.8, 'trust': 0.2},
        ),
      );

      await tester.pumpWidget(createTestWidget(emotionStream: emotionStream));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WellbeingBreakCard), findsOneWidget);

      // Tap the dismiss button ("Tiếp tục")
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // WellbeingBreakCard should disappear
      expect(find.byType(WellbeingBreakCard), findsNothing);
    });
  });
}
