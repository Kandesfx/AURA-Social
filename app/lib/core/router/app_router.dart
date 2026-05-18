import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/soul_connect/screens/soul_connect_screen.dart';
import '../../features/post/screens/create_post_screen.dart';
import '../../features/post/screens/post_detail_screen.dart';
import '../../features/chat/screens/conversations_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/ai_settings_screen.dart';
import '../../features/settings/screens/privacy_settings_screen.dart';
import '../../features/compass/screens/emotional_compass_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/waves/screens/waves_list_screen.dart';
import '../../features/waves/screens/wave_chat_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

/// AURA Social – Router Configuration
///
/// GoRouter setup với:
/// - Auth guard: redirect khi chưa/đã login
/// - ShellRoute cho bottom navigation
/// - Fullscreen routes (create post, post detail)
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    // Auth redirect: kiểm tra trạng thái đăng nhập
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final currentPath = state.matchedLocation;

      // Paths không cần auth
      const publicPaths = ['/', '/login', '/register', '/onboarding'];
      final isPublic = publicPaths.contains(currentPath);

      // Chưa login → chuyển tới login (trừ public paths)
      if (user == null && !isPublic) return '/login';

      // Đã login mà vào auth pages → chuyển tới feed
      if (user != null && (currentPath == '/login' || currentPath == '/register')) {
        return '/feed';
      }

      return null; // Không redirect
    },
    routes: [
      // ── Splash Screen ──
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth Routes ──
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/ai',
        builder: (context, state) => const AISettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/compass',
        builder: (context, state) => const EmotionalCompassScreen(),
      ),
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),

      // ── Waves (Person 3) ──
      GoRoute(
        path: '/waves',
        builder: (context, state) => const WavesListScreen(),
      ),
      GoRoute(
        path: '/wave/:waveId',
        builder: (context, state) {
          final waveId = state.pathParameters['waveId']!;
          return WaveChatScreen(waveId: waveId);
        },
      ),

      // ── Search (Person 3) ──
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
});
