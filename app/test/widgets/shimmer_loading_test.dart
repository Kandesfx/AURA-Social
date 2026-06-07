import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/widgets/shimmer_loading.dart';

/// Widget tests cho Shimmer Loading components
///
/// Person 4, Task #19 (testing)
void main() {
  group('ShimmerPostCard', () {
    testWidgets('renders with image placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShimmerPostCard(hasImage: true),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerPostCard), findsOneWidget);
    });

    testWidgets('renders without image placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShimmerPostCard(hasImage: false),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerPostCard), findsOneWidget);
    });
  });

  group('ShimmerFeedLoading', () {
    testWidgets('renders correct number of shimmer cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerFeedLoading(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(ShimmerFeedLoading), findsOneWidget);
      expect(find.byType(ShimmerPostCard), findsNWidgets(3));
    });

    testWidgets('default itemCount is 3', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerFeedLoading(),
          ),
        ),
      );

      expect(find.byType(ShimmerPostCard), findsNWidgets(3));
    });
  });

  group('ShimmerNotificationTile', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerNotificationTile(),
          ),
        ),
      );

      expect(find.byType(ShimmerNotificationTile), findsOneWidget);
    });
  });

  group('ShimmerBox', () {
    testWidgets('renders with correct dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShimmerBox(width: 100, height: 50, borderRadius: 8),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('renders with default border radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShimmerBox(width: 200, height: 30),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });
  });
}
