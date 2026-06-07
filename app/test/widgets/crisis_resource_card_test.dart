import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/wellbeing/widgets/crisis_resource_card.dart';

void main() {
  group('CrisisResourceCard Widget Tests', () {
    testWidgets('renders title and basic hotline information', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrisisResourceCard(
                customHotlineName: 'Đường dây nóng Ngày Mai',
                customHotlinePhone: '0963061414',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Chúng mình luôn ở đây vì bạn'), findsOneWidget);
      expect(find.text('Đường dây nóng Ngày Mai'), findsOneWidget);
      expect(find.text('Hotline: 0963061414 (Miễn phí)'), findsOneWidget);
      expect(find.text('Gọi Ngay'), findsOneWidget);
    });

    testWidgets('calls onDismiss when close button is tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrisisResourceCard(
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );

      // Find close icon or "Để sau" button
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });

    testWidgets('calls onDismiss when "Để sau" button is tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrisisResourceCard(
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Để sau'));
      expect(dismissed, isTrue);
    });

    testWidgets('shows Chat Ẩn Danh button and triggers callback when tapped', (tester) async {
      bool chatStarted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrisisResourceCard(
                onStartAnonymousChat: () => chatStarted = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Chat Ẩn Danh'), findsOneWidget);
      await tester.tap(find.text('Chat Ẩn Danh'));
      expect(chatStarted, isTrue);
    });

    testWidgets('triggers onCallHotline callback when "Gọi Ngay" is tapped', (tester) async {
      bool callTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrisisResourceCard(
                onCallHotline: () => callTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Gọi Ngay'));
      expect(callTapped, isTrue);
    });
  });
}
