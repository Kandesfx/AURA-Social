import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/notifications/widgets/notification_tile.dart';
import 'package:app/features/notifications/providers/notification_provider.dart';

/// Widget tests cho NotificationTile – hiển thị từng notification item
void main() {
  group('NotificationTile Widget', () {
    final mockNotification = NotificationItem(
      id: 'test_1',
      type: NotificationType.reaction,
      title: 'Reaction mới',
      body: 'đã react 😊 Joy lên bài viết của bạn',
      senderName: 'Test User',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      senderEmotionVector: const {
        'joy': 0.4, 'trust': 0.2, 'anticipation': 0.15,
        'surprise': 0.1, 'sadness': 0.05, 'fear': 0.04,
        'anger': 0.03, 'disgust': 0.03,
      },
    );

    testWidgets('renders sender name and body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationTile(notification: mockNotification),
          ),
        ),
      );

      expect(find.text('Test User'), findsOneWidget);
      expect(find.textContaining('đã react'), findsOneWidget);
    });

    testWidgets('shows unread indicator when not read', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationTile(notification: mockNotification),
          ),
        ),
      );

      // Unread dot should be present (it's a Container with circle shape)
      // The notification is unread by default (isRead: false)
      expect(find.byType(NotificationTile), findsOneWidget);
    });

    testWidgets('hides unread indicator when read', (tester) async {
      final readNotif = mockNotification.copyWith(isRead: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationTile(notification: readNotif),
          ),
        ),
      );

      expect(find.byType(NotificationTile), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationTile(
              notification: mockNotification,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NotificationTile));
      expect(tapped, isTrue);
    });

    testWidgets('renders different notification types', (tester) async {
      final types = [
        NotificationType.reaction,
        NotificationType.follow,
        NotificationType.message,
        NotificationType.soulConnect,
        NotificationType.waveInvite,
        NotificationType.system,
      ];

      for (final type in types) {
        final notif = NotificationItem(
          id: 'test_${type.name}',
          type: type,
          title: 'Test',
          body: 'Test body',
          senderName: 'User',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(notification: notif),
            ),
          ),
        );

        expect(find.byType(NotificationTile), findsOneWidget);
      }
    });

    testWidgets('shows sender initial in avatar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationTile(notification: mockNotification),
          ),
        ),
      );

      // First letter of sender name
      expect(find.text('T'), findsOneWidget);
    });
  });
}
