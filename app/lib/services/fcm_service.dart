import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// AURA Social – FCM Service
///
/// Person 4, Task #5
/// Firebase Cloud Messaging setup cho push notifications.
///
/// Handles:
/// - Token management (register/refresh)
/// - Foreground notification display
/// - Background notification handling
/// - Notification tap → deep link routing
class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// FCM token hiện tại
  String? get fcmToken => _fcmToken;

  /// Khởi tạo FCM service
  ///
  /// Gọi trong main.dart sau Firebase.initializeApp()
  Future<void> initialize() async {
    // Request permission (iOS + Web)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Permission denied by user');
      return;
    }

    debugPrint('[FCM] Permission granted: ${settings.authorizationStatus}');

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('[FCM] Token: $_fcmToken');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _onTokenRefresh(newToken);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message tap (khi user tap notification để mở app)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check nếu app được mở từ notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Subscribe to topic (e.g., 'waves_updates', 'general')
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed from topic: $topic');
  }

  // ── Handlers ──

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    // Notification sẽ được hiển thị qua NotificationProvider
    // (không cần flutter_local_notifications vì ta dùng in-app UI)
    _onNotificationReceived?.call(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');

    // Deep link routing dựa trên notification data
    final type = message.data['type'];
    final targetId = message.data['target_id'];

    _onNotificationTapped?.call(type ?? '', targetId ?? '');
  }

  void _onTokenRefresh(String newToken) {
    // TODO: Gửi token mới lên Firestore users/{uid}/fcm_tokens
    debugPrint('[FCM] Token refreshed: $newToken');
  }

  // ── Callbacks ──

  /// Callback khi nhận notification foreground
  void Function(RemoteMessage)? _onNotificationReceived;

  /// Callback khi user tap notification
  void Function(String type, String targetId)? _onNotificationTapped;

  /// Đăng ký callback cho foreground notifications
  void setOnNotificationReceived(void Function(RemoteMessage) callback) {
    _onNotificationReceived = callback;
  }

  /// Đăng ký callback cho notification tap
  void setOnNotificationTapped(void Function(String type, String targetId) callback) {
    _onNotificationTapped = callback;
  }
}
