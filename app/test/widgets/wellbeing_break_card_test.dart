import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/wellbeing/widgets/break_card.dart';

/// Widget tests cho WellbeingBreakCard
void main() {
  group('WellbeingBreakCard Widget', () {
    testWidgets('renders session_break variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WellbeingBreakCard(
                title: 'Nghỉ ngơi nhé!',
                subtitle: 'Bạn đã sử dụng 30 phút',
                variant: 'session_break',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nghỉ ngơi nhé!'), findsOneWidget);
      expect(find.text('Bạn đã sử dụng 30 phút'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('renders positive_inject variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WellbeingBreakCard(
                title: 'Góc tươi sáng',
                subtitle: 'Hãy nhìn vào điều tích cực',
                variant: 'positive_inject',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Góc tươi sáng'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('shows "Xem Aura" button for session_break', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WellbeingBreakCard(
                title: 'Break time',
                subtitle: 'Rest',
                variant: 'session_break',
                onViewCompass: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Xem Aura'), findsOneWidget);
    });

    testWidgets('calls onDismiss when dismiss tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WellbeingBreakCard(
                title: 'Test',
                subtitle: 'Test body',
                variant: 'session_break',
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tiếp tục'));
      expect(dismissed, isTrue);
    });

    testWidgets('renders suggestion when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WellbeingBreakCard(
                title: 'Test',
                subtitle: 'Body',
                variant: 'session_break',
                suggestion: 'Uống nước đi!',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Uống nước đi!'), findsOneWidget);
    });
  });
}
