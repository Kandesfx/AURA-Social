import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/soul_connect/screens/soul_connect_screen.dart';
import '../../features/post/screens/create_post_screen.dart';
import '../../features/chat/screens/conversations_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

/// AURA Social – Router Configuration
///
/// GoRouter setup với ShellRoute cho bottom navigation.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Splash Screen ──
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Main Shell (Bottom Navigation) ──
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeedScreen(),
            ),
          ),
          GoRoute(
            path: '/soul',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SoulConnectScreen(),
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConversationsListScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Fullscreen Routes (no bottom nav) ──
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
    ],
  );
});
