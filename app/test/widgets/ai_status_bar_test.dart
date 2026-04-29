import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/widgets/ai_status_bar.dart';

/// Widget tests cho AIStatusBar
void main() {
  group('AIStatusBar Widget', () {
    testWidgets('renders with default props', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIStatusBar(),
          ),
        ),
      );

      expect(find.byType(AIStatusBar), findsOneWidget);
      expect(find.textContaining('Đang hiểu bạn'), findsOneWidget);
    });

    testWidgets('shows processing text when isProcessing true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIStatusBar(isProcessing: true),
          ),
        ),
      );

      expect(find.textContaining('Đang hiểu bạn'), findsOneWidget);
    });

    testWidgets('shows ready text when isProcessing false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIStatusBar(isProcessing: false),
          ),
        ),
      );

      expect(find.textContaining('AI sẵn sàng'), findsOneWidget);
    });

    testWidgets('displays correct emotional mode label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIStatusBar(emotionalMode: 'explore'),
          ),
        ),
      );

      expect(find.text('Khám phá'), findsOneWidget);
    });

    testWidgets('displays gentle_uplift mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIStatusBar(emotionalMode: 'gentle_uplift'),
          ),
        ),
      );

      expect(find.text('Nâng đỡ'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIStatusBar(onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(AIStatusBar));
      expect(tapped, isTrue);
    });
  });
}
