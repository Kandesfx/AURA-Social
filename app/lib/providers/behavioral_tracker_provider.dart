import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/behavioral_tracker.dart';

/// AURA Social – Behavioral Tracker Provider
///
/// Person 4, Task #2
/// Riverpod provider wrapping BehavioralTracker singleton.
/// Auto-starts tracking khi được read lần đầu.
///
/// Usage:
/// ```dart
/// // Trong widget:
/// final tracker = ref.read(behavioralTrackerProvider);
/// tracker.trackViewPost(postId);
/// ```
final behavioralTrackerProvider = Provider<BehavioralTracker>((ref) {
  final tracker = BehavioralTracker.instance;

  // Auto-start khi provider được tạo
  if (!tracker.isRunning) {
    tracker.start();
  }

  // Auto-stop khi provider bị dispose (user logout, app close)
  ref.onDispose(() {
    tracker.stop();
  });

  return tracker;
});
