import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/notifications/providers/notification_provider.dart';

/// Unit tests cho NotificationProvider
void main() {
  group('NotificationItem', () {
    test('creates with required fields', () {
      final item = NotificationItem(
        id: 'n1',
        type: NotificationType.reaction,
        title: 'Test',
        body: 'Test body',
        senderName: 'User',
        createdAt: DateTime.now(),
      );

      expect(item.id, equals('n1'));
      expect(item.type, equals(NotificationType.reaction));
      expect(item.isRead, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final item = NotificationItem(
        id: 'n1',
        type: NotificationType.follow,
        title: 'Follow',
        body: 'followed you',
        senderName: 'User',
        createdAt: DateTime(2026, 4, 29),
      );

      final read = item.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, equals('n1'));
      expect(read.type, equals(NotificationType.follow));
      expect(read.senderName, equals('User'));
    });
  });

  group('NotificationState', () {
    test('default state has no notifications', () {
      const state = NotificationState();
      expect(state.notifications, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.unreadCount, equals(0));
    });

    test('counts unread correctly', () {
      final now = DateTime.now();
      final state = NotificationState(
        notifications: [
          NotificationItem(
            id: '1', type: NotificationType.reaction,
            title: 'T', body: 'B', senderName: 'U',
            createdAt: now, isRead: false,
          ),
          NotificationItem(
            id: '2', type: NotificationType.follow,
            title: 'T', body: 'B', senderName: 'U',
            createdAt: now, isRead: true,
          ),
          NotificationItem(
            id: '3', type: NotificationType.message,
            title: 'T', body: 'B', senderName: 'U',
            createdAt: now, isRead: false,
          ),
        ],
      );

      expect(state.unreadCount, equals(2));
    });

    test('copyWith updates fields correctly', () {
      const state = NotificationState(isLoading: true);
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
    });
  });

  group('NotificationNotifier', () {
    test('initializes with loading state', () {
      final notifier = NotificationNotifier();
      // Initially loading
      expect(notifier.state.isLoading, isTrue);
    });

    test('loads mock notifications after delay', () async {
      final notifier = NotificationNotifier();
      // Wait for mock data to load
      await Future.delayed(const Duration(milliseconds: 600));
      expect(notifier.state.notifications, isNotEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    test('marks notification as read', () async {
      final notifier = NotificationNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      final firstId = notifier.state.notifications.first.id;

      notifier.markAsRead(firstId);

      final updated = notifier.state.notifications
          .firstWhere((n) => n.id == firstId);
      expect(updated.isRead, isTrue);
    });

    test('marks all as read', () async {
      final notifier = NotificationNotifier();
      await Future.delayed(const Duration(milliseconds: 600));

      notifier.markAllAsRead();

      expect(notifier.state.unreadCount, equals(0));
      for (final n in notifier.state.notifications) {
        expect(n.isRead, isTrue);
      }
    });
  });
}
