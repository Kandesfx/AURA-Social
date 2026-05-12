import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';

/// AURA Social – Root App Widget
class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

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
