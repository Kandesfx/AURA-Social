import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_state_provider.dart';
import 'providers/behavioral_tracker_provider.dart';
import 'providers/settings_provider.dart';
import 'services/behavioral_tracker.dart';
import 'services/fcm_service.dart';

/// AURA Social – Root App Widget
class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Watch auth state change globally to start/stop services (Person 4, Task #5 & #1)
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        // Khởi chạy Behavioral Tracker
        ref.read(behavioralTrackerProvider);
        // Khởi tạo FCM Push Notifications
        FCMService.instance.initialize();
      } else {
        // Dừng Behavioral Tracker
        BehavioralTracker.instance.stop();
      }
    });

    return MaterialApp.router(
      title: 'AURA Social',
      debugShowCheckedModeBanner: false,

      // Theme – now controlled by SettingsProvider
      theme: AuraTheme.light,
      darkTheme: AuraTheme.dark,
      themeMode: themeMode,

      // Router
      routerConfig: router,
    );
  }
}
