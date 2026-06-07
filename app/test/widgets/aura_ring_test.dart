import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/widgets/aura_ring_widget.dart';

/// Widget tests cho AuraRing – component visual cốt lõi
void main() {
  group('AuraRing Widget', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuraRing(size: 60),
            ),
          ),
        ),
      );

      // Should render without error
      expect(find.byType(AuraRing), findsOneWidget);
    });

    testWidgets('renders with emotion vector', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuraRing(
                size: 80,
                emotionVector: {
                  'joy': 0.4,
                  'trust': 0.2,
                  'anticipation': 0.15,
                  'surprise': 0.1,
                  'sadness': 0.05,
                  'fear': 0.04,
                  'anger': 0.03,
                  'disgust': 0.03,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AuraRing), findsOneWidget);
      // Should contain a CustomPaint for the gradient ring
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('renders with child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuraRing(
                size: 60,
                child: Container(
                  color: Colors.blue,
                  child: const Icon(Icons.person),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AuraRing), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders default avatar when no image or child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuraRing(size: 60),
            ),
          ),
        ),
      );

      // Default avatar shows person icon
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('respects animate parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuraRing(size: 60, animate: false),
            ),
          ),
        ),
      );

      expect(find.byType(AuraRing), findsOneWidget);
      // No error when animation is disabled
    });
  });
}
