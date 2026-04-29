import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/compass/widgets/ai_insight_card.dart';

/// Widget tests cho AIInsightCard
void main() {
  group('AIInsightCard Widget', () {
    testWidgets('renders insight text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AIInsightCard(
                insight: 'Test insight message',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test insight message'), findsOneWidget);
      expect(find.text('AI Insight'), findsOneWidget);
    });

    testWidgets('renders suggestion when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AIInsightCard(
                insight: 'Main insight',
                suggestion: 'Try this suggestion',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Try this suggestion'), findsOneWidget);
    });

    testWidgets('hides suggestion when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AIInsightCard(
                insight: 'Only insight, no suggestion',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Only insight, no suggestion'), findsOneWidget);
      // No ✨ emoji container for suggestion
    });

    testWidgets('renders wellbeing score when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AIInsightCard(
                insight: 'Insight text',
                wellbeingScore: 85,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Wellbeing Score'), findsOneWidget);
      expect(find.text('85/100'), findsOneWidget);
    });

    testWidgets('hides wellbeing score when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AIInsightCard(
                insight: 'No score here',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Wellbeing Score'), findsNothing);
    });
  });
}
