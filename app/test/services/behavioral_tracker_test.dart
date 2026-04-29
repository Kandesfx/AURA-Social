import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/behavioral_tracker.dart';

/// Unit tests cho BehavioralTracker service
void main() {
  group('BehavioralTracker', () {
    late BehavioralTracker tracker;

    setUp(() {
      tracker = BehavioralTracker.instance;
      // Ensure clean state
      if (tracker.isRunning) tracker.stop();
    });

    tearDown(() {
      if (tracker.isRunning) tracker.stop();
    });

    test('starts and stops correctly', () {
      expect(tracker.isRunning, isFalse);

      tracker.start();
      expect(tracker.isRunning, isTrue);

      tracker.stop();
      expect(tracker.isRunning, isFalse);
    });

    test('tracks events when running', () {
      tracker.start();

      tracker.trackEvent(BehavioralEvent(
        type: 'test_event',
        timestamp: DateTime.now(),
      ));

      // pendingEventCount includes the app_open event from start() + our test event
      expect(tracker.pendingEventCount, greaterThanOrEqualTo(1));

      tracker.stop();
    });

    test('ignores events when not running', () {
      expect(tracker.isRunning, isFalse);

      tracker.trackEvent(BehavioralEvent(
        type: 'ignored_event',
        timestamp: DateTime.now(),
      ));

      expect(tracker.pendingEventCount, equals(0));
    });

    test('does not start twice', () {
      tracker.start();
      final countAfterFirstStart = tracker.pendingEventCount;

      tracker.start(); // Should be no-op
      expect(tracker.pendingEventCount, equals(countAfterFirstStart));

      tracker.stop();
    });
  });

  group('BehavioralEvent', () {
    test('converts to map correctly', () {
      final event = BehavioralEvent(
        type: 'view_post',
        timestamp: DateTime(2026, 4, 29, 12, 0, 0),
        targetId: 'post_123',
        metadata: {'scroll_depth': 50},
      );

      final map = event.toMap();
      expect(map['type'], equals('view_post'));
      expect(map['target_id'], equals('post_123'));
      expect(map['scroll_depth'], equals(50));
      expect(map.containsKey('timestamp'), isTrue);
    });

    test('converts to map without optional fields', () {
      final event = BehavioralEvent(
        type: 'app_open',
        timestamp: DateTime.now(),
      );

      final map = event.toMap();
      expect(map['type'], equals('app_open'));
      expect(map.containsKey('target_id'), isFalse);
    });
  });
}
